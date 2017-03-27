require 'delegate'

module Apple2
  ##
  # Apple 2 String class
  #

  class Apple2String < SimpleDelegator
    ##
    # Convert Apple 2 character to standard ASCII

    def self.to_ascii(c)
      if (c >= 0 && c <= 0x1f)
        c += 0x40
      elsif (c >= 0x60 && c <= 0x7f)
        c -= 0x40
      elsif (c >= 0x80)
        c -= 0x80
      end
      return c
    end

    ##
    # Convert specified Apple 2 character buffer into a standard ASCII string.
    #
    # Apple 2 to ASCII character range map:
    #
    #   00-1f => 40-5f Inverse uppercase alpha
    #   20-3f => 20-3f Inverse symbols
    #   40-5f => 40-5f Flashing uppercase alpha
    #   60-7f => 20-3f Flashing symbols
    #   80-ff => 00-7f Normal text

    def self.parse(buffer)
      str = Apple2String.new
      buffer.each_byte { |c| str << self.to_ascii(c) }
      str
    end

    def initialize(str = "")
      super(str)
    end

    ##
    # Return string as an Apple 2 character buffer

    def to_buffer
      buffer = String.new
      each_byte { |c| buffer << (c | 0x80) }
      buffer
    end
  end
end
