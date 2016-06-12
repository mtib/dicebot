require "minitest/autorun"
require "dicebot_mtib"

class DiceTest < Minitest::Test
    def test_dice_min
        assert DND::roll_int(10,10)
    end
end
