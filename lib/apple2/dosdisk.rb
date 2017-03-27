require 'apple2/disk.rb'
require 'apple2/dos/catalog.rb'
require 'apple2/dos/file_entry.rb'
require 'apple2/dos/vtoc.rb'

module Apple2

  ##
  # Apple 2 DOS 3.3 Disk

  class DOSDisk

    class FileInfo
      attr_reader :num_tsl_sectors, :num_data_sectors, :num_sectors

      def initialize(data)
        @num_tsl_sectors = (data.length / BYTES_PER_TSL_SECTOR) + ((data.length % BYTES_PER_TSL_SECTOR > 0) ? 1 : 0)
        @num_data_sectors = data.length / Disk::BYTES_PER_SECTOR   # FIXME: assume no remainder
        @num_sectors = @num_data_sectors + @num_tsl_sectors
      end
    end

    TRACK_SECTOR_LIST_OFFSET  = 0xc
    LINKS_PER_TSL_SECTOR      = 122
    BYTES_PER_TSL_SECTOR      = LINKS_PER_TSL_SECTOR * Disk::BYTES_PER_SECTOR
    TSL_LINK_OFFSET           = 0xc
    TSL_SECTOR_NUM_OFFSET     = 5

    attr_reader :catalog

    ##
    # Open specified disk image for reading and writing files

    def self.open(file)
      disk = DOSDisk.new(file)

      if block_given?
        begin
          yield disk
        ensure
          disk.close
        end
      else
        disk
      end
    end

    ##
    # Display disk catalog

    def self.catalog(file)
      puts "#{file}:"
      Apple2::DOSDisk.new(file).catalog.file_entries.each { |f| puts f.to_s }
      puts
    end

    def valid?
      @disk.valid? && @vtoc.valid?
    end

    ##
    # Write changes and close the disk image.

    def close
      @disk.save(@filename) if @changed
    end

    ##
    # Read specified file

    def read(filename)
      file = nil

      file_entry = @catalog.file_entries.find { |f| filename == f.name.strip }
      if file_entry
        data = ""
        get_ts_list(file_entry).each do |t, s|
          data << @disk.read_bytes(t, s)
        end
        file = DOSFile.new(file_entry, data)
      end

      file
    end

    ##
    # Write specified file

    def write(file, filename = nil)
      #TODO: fix ugliness
      filename, type, data = (filename ? filename : file.name), file.flags, file.data
      file_info = FileInfo.new(data)

      vtoc_free_sectors = @vtoc.free_sectors
      if file_info.num_sectors > vtoc_free_sectors.length
        raise sprintf("Insufficient space. Free sectors: %d, file sectors: %d\n",
                      vtoc_free_sectors.length, file_info.num_sectors)
      end

      free_sectors = vtoc_free_sectors.each

      tsl_sectors = []
      last_track_written = 0
      file_info.num_data_sectors.times do |d|
        # Allocate TSL sector if necessary
        if d % LINKS_PER_TSL_SECTOR == 0
          tsl_sectors << @vtoc.alloc(free_sectors.next)
          #printf("%p tsl\n", tsl_sectors.last)
        end

        # Allocate and write data sector
        data_sector = @vtoc.alloc(free_sectors.next)
        write_file_data_sector(data_sector, d, data)
        last_track_written = data_sector[0]

        # Write link to TSL sector
        write_file_link(tsl_sectors.last, tsl_sectors.index(tsl_sectors.last), data_sector, d % LINKS_PER_TSL_SECTOR)
      end

      # Update links between tsl sectors
      for tsl_sector_index in (0...tsl_sectors.length-1)
        t, s = tsl_sectors[tsl_sector_index]
        @disk.write_bytes(t, s, 1, tsl_sectors[tsl_sector_index + 1].pack("CC"))
      end

      @vtoc.set_last_allocated_track(last_track_written)

      @catalog.add_file_entry(filename, type, file_info.num_sectors, tsl_sectors[0][0],
                              tsl_sectors[0][1])

      @changed = true
    end

    private

    def initialize(filename)
      @filename = filename
      @disk = Disk.load(@filename)
      @vtoc = DOS::VTOC.new(@disk)
      @catalog = DOS::Catalog.new(@disk, @vtoc.catalog_track, @vtoc.catalog_sector)
      @changed = false
    end

    def get_ts_list(file_entry)
      ts_list = []
      t = file_entry.ts_list_track
      s = file_entry.ts_list_sector
      while (t > 0 && t < Disk::TRACKS_PER_DISK)
        TRACK_SECTOR_LIST_OFFSET.step(Disk::BYTES_PER_SECTOR-1, 2) do |i|
          ts = @disk.read_bytes(t, s, i, 2).unpack("CC")
          break if ts[0] == 0
          ts_list << ts
        end
        t, s = @disk.read_bytes(t, s, 1, 2).unpack("CC")
      end
      ts_list
    end

    def write_file_data_sector(data_ts, index, data)
      #printf("%p data index %d, ", data_ts, index)
      @disk.write_bytes(data_ts[0], data_ts[1], 0,
                        data[index * Disk::BYTES_PER_SECTOR, Disk::BYTES_PER_SECTOR])
    end

    def write_file_link(tsl_ts, tsl_sector_index, link_ts, link_index)
      #printf("tsl %p, link %d = %p\n", tsl_ts, link_index, link_ts)
      @disk.write_bytes(tsl_ts[0], tsl_ts[1], TSL_SECTOR_NUM_OFFSET,
                  [tsl_sector_index * LINKS_PER_TSL_SECTOR].pack("v"))
      @disk.write_bytes(tsl_ts[0], tsl_ts[1], 2 * link_index + TSL_LINK_OFFSET, link_ts.pack("CC"))
    end
  end
end

