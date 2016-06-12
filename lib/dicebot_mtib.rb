# Dungeons and Dragons module
# contains (#Game) which is instantiated for every
# game channel in Discord
module DND
  # Game is object that contains all information to
  # play a game of Dungeons and Dragons.
  # It wraps around some Discordrb objects
  # @todo export session
  # @todo import session
  # @todo standart sound effects
  # @todo characters
  # @todo fighting
  class Game
    attr_reader @voice_channel, @voice_enabled, @voice_bot
    attr_reader @master, @voice_enabled
    def initialize(attributes = {})
      @channel = attributes[:channel]
      @master = attributes[:master]
      @channel.server.channels.each do |c|
        next unless c.voice? && c.users.include?(@master)
        @voice_enabled = true
        @youtube_queue = []
        @voice_channel = c
        @youtube_playing = false
        break
      end
    end

    def ascii(string, lang = '')
      @channel.send_message "```#{lang}\n#{string}\n```"
    end

    def restart(master = @master)
      @master = master
    end

    def broadcast(msg)
      @channel.send_message msg
    end

    def secret(msg)
      @master.pm msg
    end

    def voice_bot(textbot)
      @voice_bot = textbot.voice_connect(@voice_channel, false)
      @voice_bot.filter_volume = 0.15
    end

    def voice_connect(bot)
      if @voice_enabled
        if @voice_bot.nil?
          voice_bot bot
        else
          voice_disconnect
        end
      end
    end

    def volume=(v)
      if v.to_f >= 0 && v.to_f <= 1
        @voice_bot.volume = v.to_f
        @voice_bot.filter_volume = v.to_f
        ascii "Set volume to #{v.to_f} (applies to next song)"
      end
    end

    def voice_disconnect
      return if @voice_bot.nil?
      @voice_bot.destroy
      @voice_bot = nil
    end

    def stop_playing
      @voice_bot.stop_playing unless @voice_bot.nil?
    end

    def add_queue(file)
      @youtube_queue.push(file) if @voice_enabled && !file.nil?
    end

    def play_file(file)
      add_queue file
      if !@youtube_playing && !@youtube_queue.empty?
        @youtube_playing = true
        stop_playing
        cf = @youtube_queue.shift
        @voice_bot.play_file(cf)
        FileUtils.rm(cf)
        @youtube_playing = false
        play_file nil
      end
    end

    def debug
      answ = '***Debug Information***\n```\n'
      def answ.<<(string)
        super "#{string}\n"
      end
      answ << "Channel: #{@channel.name}"
      answ << "Master: #{@master.name}"
      answ << "Server: #{@channel.server.name}"
      answ << "Voice-able: #{@voice_enabled}"
      answ << "Voice-channel: #{@voice_channel.name}" unless @voice_channel.nil?
      answ + '```'
    end
  end

  DICE = /(\d+)D(\d+)/i

  # Rolls dice and returns result
  # @param dices [String] String containing all Dices in form xDy/i
  def self.roll_string(dices)
    sum = 0
    dices.scan(DICE) do |match|
      m = match.to_a
      sum += roll_int(m[0].to_i, m[1].to_i)
    end
    sum
  end

  def self.roll_int(num, val)
    sum = num
    num.times do
      sum += rand(val)
    end
    sum
  end
end
