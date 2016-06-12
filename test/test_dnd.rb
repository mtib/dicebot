require 'minitest/autorun'
require 'dicebot_mtib'

# DiceTest is testing environment for dicebot_mtib.rb
class DiceTest < Minitest::Test
  def test_dice_min
    assert DND.roll_int(10, 10)
  end
end
