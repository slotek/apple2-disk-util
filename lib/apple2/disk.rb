module Apple2

  ##
  # Apple2 16-Sector disk

  class Disk

    TRACKS_PER_DISK     = 35
    SECTORS_PER_TRACK   = 16
    BYTES_PER_SECTOR    = 256
    BYTES_PER_TRACK     = SECTORS_PER_TRACK * BYTES_PER_SECTOR
    BYTES_PER_DISK      = TRACKS_PER_DISK * BYTES_PER_TRACK

    ##
    # Load disk from specified file.

    def self.load(filename)
      data = nil
      File.open(filename, "rb") { |f| data = f.read }
      Disk.new(data)
    end

    def self.valid_ts?(track, sector)
      track >= 0 && track < Disk::TRACKS_PER_DISK && sector >= 0 && sector < Disk::SECTORS_PER_TRACK
    end

    ##
    # Save disk to specified file.

    def save(filename)
      File.open(filename, "wb") { |f| f << @buf }
    end

    def valid?
      (BYTES_PER_DISK - @buf.length).abs < BYTES_PER_SECTOR
    end

    def read_byte(track, sector, byte = 0)
      @buf[to_offset(track, sector, byte)].unpack("C").first
    end

    def read_bytes(track, sector, byte = 0, length = BYTES_PER_SECTOR)
      if length > 0 && (byte + length <= BYTES_PER_SECTOR)
        return @buf[to_offset(track, sector, byte), length]
      else
        raise "Cannot read #{length} bytes from offset #{byte}"
      end
    end

    def write_bytes(track, sector, byte, src)
      if src.length > 0 && (byte + src.length <= BYTES_PER_SECTOR)
        i = to_offset(track, sector, byte)
        src.each_char do |c|
          @buf[i] = c
          i += 1
        end
      else
        raise "Cannot write #{src.length} bytes at offset #{byte}"
      end
    end

    private

    def initialize(data)
      @buf = data
    end

    def to_offset(track, sector, byte = 0)
      if track >= 0 && track < TRACKS_PER_DISK && sector >= 0 && sector < SECTORS_PER_TRACK && byte >= 0 && byte < BYTES_PER_SECTOR
        return track * BYTES_PER_TRACK + sector * BYTES_PER_SECTOR + byte
      else
        raise sprintf("Invalid offset: track %02x, sector %02x, byte %02x", track, sector, byte)
      end
    end

  end
end
