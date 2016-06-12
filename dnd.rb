module DND
    class Game
        def initialize(attributes = {})
            @channel = attributes[:channel]
            def @channel.ascii(string, lang="")
                self.send_message "```#{lang}\n#{string}\n```"
            end
            @voice_channel = nil
            @voice_enabled = false
            @voice_bot = nil
            @master = attributes[:master]
            @server = @channel.server
            @server.channels.each do |c|
                if c.voice?
                    if c.users.include? @master
                        @voice_channel = c
                        @voice_enabled = true
                        @youtube_queue = []
                        @youtube_playing = false
                        break # found voice channel
                    end
                end
            end
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
        def voice_connect(bot)
            if @voice_enabled
                if @voice_bot.nil?
                    @voice_bot = bot.voice_connect(@voice_channel, false)
                    @voice_bot.filter_volume=0.15
                    return true
                else
                    voice_disconnect
                    @channel.ascii "The voice part of myself has killed itself"
                    return false
                end
            else
                @channel.ascii "Voice not enabled"
                @voice_bot = nil
                return false
            end
        end
        def set_volume(v)
            if v.to_f >= 0 && v.to_f <= 1
                @voice_bot.filter_volume=v.to_f
                @channel.ascii "Set volume to #{v.to_f} (applies to next song)"
            end
        end
        def voice_disconnect
            if !@voice_bot.nil?
                @voice_bot.destroy
                @voice_bot = nil
            end
        end
        def stop_playing
            @voice_bot.stop_playing() if !@voice_bot.nil?
        end
        def play_file(file)
            if @voice_enabled && !file.nil?
                @youtube_queue.push(file)
            end
            if !@youtube_playing && (@youtube_queue.length > 0)
                @youtube_playing = true
                stop_playing
                cf = @youtube_queue.shift
                name = cf.match(/\/tmp\/(.*)\..*/i)[1]
                msg = "Playing #{name} on #{@server.name} / #{@voice_channel.name}"
                puts msg
                @channel.send msg
                @voice_bot.play_file(cf)
                FileUtils.rm(cf)
                @youtube_playing = false
                play_file nil
            end
        end
        def debug
            answ = "***Debug Information***"
            def answ.<<(string)
                super "#{string}\n"
            end
            answ << "```"
            answ << "Channel: #{@channel.name}"
            answ << "Master: #{@master.name}"
            answ << "Server: #{@server.name}"
            answ << "Voice-able: #{@voice_enabled}"
            answ << "Voice-channel: #{@voice_channel.name}" if !@voice_channel.nil?
            answ << "```"
            return answ
        end

        attr_reader :master, :voice_enabled
    end

    Dice = /(\d+)D(\d+)/i

    # Rolls dice and returns result
    # @param dices [String] String containing all Dices in form xDy/i
    def DND.roll_string(dices)
        sum = 0
        dices.scan(Dice) do |match|
            m = match.to_a
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
