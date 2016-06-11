module DND
    class Game
        def initialize(attributes = {})
            @channel = attributes[:channel]
            @master = attributes[:master]
        end
        def restart(master=@master)
            @master = master
        end
        def broadcast(msg)
            @channel.send_message msg
        end
        def secret(msg)
            @master.pm msg
        end

        attr_reader :master
    end

    Dice = /(\d+)D(\d+)/i

    # Rolls dice and returns result
    # @param dices [String] String containing all Dices in form xDy/i
    def DND.roll_string(dices)
        sum = 0
        dices.scan(Dice) do |match|
            m = match.to_a
            print(m)
            sum += roll_int(m[0].to_i, m[1].to_i)
        end
        sum
    end

    def DND.roll_int(num, val)
        sum = num
        num.times do
            sum += rand(val)
        end
        sum
    end
end
