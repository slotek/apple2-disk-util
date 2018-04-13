require 'test/unit'

require 'apple2'

include Apple2

##
# Test the a2 string class
#
class TestString < Test::Unit::TestCase

  def test_init
    assert_equal Apple2String.new('foo'), 'foo'
  end

  def test_normal
    assert_equal('[Apple]',
                 Apple2String.parse("\xdb\xc1\xf0\xf0\xec\xe5\xdd"))
  end

  def test_inverse
    assert_equal('-=> ABC <=-',
                 Apple2String.parse("\x2d\x3d\x3e\x20\x01\x02\x03\x20\x3c\x3d\x2d"))
  end

  def test_flashing
    assert_equal('-=> ABC <=-',
                 Apple2String.parse("\x6d\x7d\x7e\x60\x41\x42\x43\x60\x7c\x7d\x6d"))
  end

  def test_buffer
    assert_equal(String.new("\xdb\xc1\xf0\xf0\xec\xe5\xdd", encoding: 'ASCII-8BIT'),
                 Apple2String.new('[Apple]').to_buffer)
  end
end
