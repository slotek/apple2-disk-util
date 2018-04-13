require 'set'

require 'apple2/disk.rb'

module Apple2::DOS
  ##
  # Apple 2 DOS 3.3 disk Catalog
  #
  class Catalog
    FILE_ENTRY_OFFSETS  = [0xb, 0x2e, 0x51, 0x74, 0x97, 0xba, 0xdd].freeze
    FILE_ENTRY_LENGTH   = 0x23

    attr_reader :file_entries

    def self.valid_ts?(track, sector)
      track > 0 && track < Disk::TRACKS_PER_DISK && sector > 0 && sector < Disk::SECTORS_PER_TRACK
    end

    def initialize(disk, track, sector)
      @disk = disk
      @file_entries = []
      @catalog_track = track
      @catalog_sector = sector

      return unless disk.valid?

      # Parse files from catalog sectors
      visited = Set.new
      found_empty = false
      while Catalog.valid_ts?(track, sector) && !found_empty && !visited.include?([track, sector])
        FILE_ENTRY_OFFSETS.each do |i|
          entry = FileEntry.parse(@disk.read_bytes(track, sector, i, FILE_ENTRY_LENGTH))
          if entry.empty?
            found_empty = true
          elsif !entry.deleted?
            @file_entries << entry
          end
        end
        visited << [track, sector]
        track, sector = @disk.read_bytes(track, sector, 1, 2).unpack('CC')
      end
    end

    def add_file_entry(name, type, length, ts_list_track, ts_list_sector)
      done = false
      track = @catalog_track
      sector = @catalog_sector
      while Catalog.valid_ts?(track, sector) && !done
        FILE_ENTRY_OFFSETS.each do |i|
          entry = FileEntry.parse(@disk.read_bytes(track, sector, i, FILE_ENTRY_LENGTH))
          next unless entry.empty? || entry.deleted?
          new_entry = FileEntry.new(name, type, length, ts_list_track, ts_list_sector)
          @file_entries << new_entry
          @disk.write_bytes(track, sector, i, new_entry.to_buffer)
          done = true
          break
        end
        track, sector = @disk.read_bytes(track, sector, 1, 2).unpack('CC')
      end
    end
  end
end
