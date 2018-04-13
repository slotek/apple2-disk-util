module Apple2::DOS
  ##
  # Apple 2 DOS 3.3 disk Volume Table Of Contents class
  #
  class VTOC
    class Bitmap
      BITMAP_LENGTH = 2

      def initialize(disk, track)
        @disk = disk
        @track = track
        @offset = VTOC::TRACK_BITMAP_OFFSET + (track * BITMAP_LENGTH * 2)
      end

      def alloc(sector)
        write_bitmap(read_bitmap & ~(1 << sector))
      end

      def free(sector)
        write_bitmap(read_bitmap | (1 << sector))
      end

      def free?(sector)
        (read_bitmap & (1 << sector)) != 0
      end

      private

      def read_bitmap
        @disk.read_bytes(VTOC::VTOC_TRACK, VTOC::VTOC_SECTOR, @offset, BITMAP_LENGTH).unpack('n').first
      end

      def write_bitmap(bmp)
        @disk.write_bytes(VTOC::VTOC_TRACK, VTOC::VTOC_SECTOR, @offset, [bmp].pack('n'))
      end
    end

    VTOC_TRACK                = 0x11
    VTOC_SECTOR               = 0
    CATALOG_TRACK_OFFSET      = 1
    CATALOG_SECTOR_OFFSET     = 2
    SECTORS_PER_TRACK_OFFSET  = 0x35
    TRACK_BITMAP_OFFSET       = 0x38
    LAST_ALLOCATED_TRACK_OFFSET = 0x30
    ALLOCATION_DIRECTION_OFFSET = 0x31

    def initialize(disk)
      @disk = disk
    end

    def valid?
      @disk.read_byte(VTOC_TRACK, VTOC_SECTOR, SECTORS_PER_TRACK_OFFSET) == Disk.SECTORS_PER_TRACK
    end

    def catalog_track
      @disk.read_byte(VTOC_TRACK, VTOC_SECTOR, CATALOG_TRACK_OFFSET)
    end

    def catalog_sector
      @disk.read_byte(VTOC_TRACK, VTOC_SECTOR, CATALOG_SECTOR_OFFSET)
    end

    def alloc(track_sector)
      t, s = track_sector
      Bitmap.new(@disk, t).alloc(s) if Disk.valid_ts?(t, s)
      track_sector
    end

    def free(track, sector)
      Bitmap.new(@disk, track).free(sector) if Disk.valid_ts?(track, sector)
    end

    def free?(track, sector)
      Disk.valid_ts?(track, sector) ? Bitmap.new(@disk, track).free?(sector) : false
    end

    def last_allocated_track
      @disk.read_byte(VTOC_TRACK, VTOC_SECTOR, LAST_ALLOCATED_TRACK_OFFSET)
    end

    def set_last_allocated_track(track)
      @disk.write_bytes(VTOC_TRACK, VTOC_SECTOR, LAST_ALLOCATED_TRACK_OFFSET, [track].pack('C'))
      set_allocation_direction(track)
    end

    def allocation_direction
      @disk.read_byte(VTOC_TRACK, VTOC_SECTOR, ALLOCATION_DIRECTION_OFFSET) == 1 ? 1 : -1
    end

    # Return list of free [track, sector] pairs as ordered
    # by the DOS 3.3 file allocation strategy.
    def free_sectors
      free = []
      direction = allocation_direction
        
      t = last_allocated_track + direction
      s = 0xf

      loop do
        free << [t, s] if free?(t, s)

        break if t == 0 && s == 0

        # Adjust track & sector
        if s > 0
          s -= 1
        else
          s = 0xf
          t += direction
          if t > 0x22
            t = 0x10
            direction = -1
          elsif t < 0
            t = 0x11
            direction = 1
          end
        end
      end

      free
    end

    private

    def set_allocation_direction(track)
      d = track >= 0x11 ? 1 : 0xff
      @disk.write_bytes(VTOC_TRACK, VTOC_SECTOR, ALLOCATION_DIRECTION_OFFSET, [d].pack('C'))
    end
  end
end
