module Apple2::DOS

  ##
  # Apple 2 DOS 3.3 disk catalog File Entry

  class FileEntry
    FILE_NAME_LENGTH = 30
    FILE_TYPES = {
      0 => "T",
      1 => "I",
      2 => "A",
      4 => "B",
      8 => "S",
      0x10 => "R",
      0x20 => "a",
      0x40 => "b"
    }

    attr_reader :name, :length, :ts_list_track, :ts_list_sector, :flags

    def self.parse(buf)
      ts_list_track, ts_list_sector = buf[0, 2].unpack("CC")
      flags = buf[2].unpack("C").first
      name = Apple2String.parse(buf[3, FILE_NAME_LENGTH])
      length = buf[0x21, 2].unpack("v").first
      FileEntry.new(name, flags, length, ts_list_track, ts_list_sector)
    end

    def initialize(name, flags, length, ts_list_track, ts_list_sector)
      @name = Apple2String.new(name[0, FILE_NAME_LENGTH])
      if name.length < FILE_NAME_LENGTH
        @name << ' ' * (FILE_NAME_LENGTH - name.length)
      end
      @flags = flags
      @length = length
      @ts_list_track = ts_list_track
      @ts_list_sector = ts_list_sector
    end

    def to_buffer
      buf = [@ts_list_track, @ts_list_sector, @flags].pack("C*")
      buf << @name.to_buffer
      buf << [@length].pack("v")
    end

    def empty?
      @ts_list_track == 0 && @ts_list_sector == 0
    end

    def deleted?
      @ts_list_track == 0xff
    end

    def locked?
      @flags & 0x80
    end

    def type
      FILE_TYPES.fetch(@flags & 0x7f, "?")
    end

    def to_s
      str = locked? ? "*" : " "
      str << type << " "
      str << sprintf("%03d", length) << " "
      str << name
      str
    end
  end
end
