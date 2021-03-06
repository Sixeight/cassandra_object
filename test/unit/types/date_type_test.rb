require 'test_helper'

class CassandraObject::Types::DateTypeTest < CassandraObject::Types::TestCase
  test 'encode' do
    assert_equal '2004-04-25', coder.encode(Date.new(2004, 4, 25))
  end

  test 'decode' do
    assert_equal Date.new(2004, 4, 25), coder.decode('2004-04-25')
  end
end
