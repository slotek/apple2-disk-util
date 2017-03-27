module Apple2

  class DOSFile
    attr_reader :data

    def initialize(file_entry, data)
      @file_entry = file_entry
      @data = data
    end

    def name
      @file_entry.name
    end

    def type
      @file_entry.type
    end

    def flags
      @file_entry.flags
    end

    def to_s
      @file_entry.to_s
    end
  end

end
