require 'test/unit'

require 'apple2'

include Apple2

class TestOffset < Test::Unit::TestCase
  def test_default_init
    o = Disk::Offset.new(0x22, 0xf)
    assert_equal(o.track, 0x22)
    assert_equal(o.sector, 0xf)
    assert_equal(o.byte, 0)
  end

  def test_init
    assert_equal Disk::Offset.new(0, 1, 2).byte, 2
  end

  def test_valid_track
    assert_raises { Disk::Offset.new(-1, 0) }
    assert_raises { Disk::Offset.new(0x23, 0) }
  end

  def test_valid_sector
    assert_raises { Disk::Offset.new(0, -2) }
    assert_raises { Disk::Offset.new(0, 0x10) }
  end

  def test_valid_byte
    assert_raises { Disk::Offset.new(0, 0, -3) }
    assert_raises { Disk::Offset.new(0, 0, 0x103) }
  end
end
