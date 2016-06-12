require 'net/http'

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
    attr_reader :voice_channel, :voice_enabled, :voice_bot
    attr_reader :master, :voice_enabled
    def initialize(attributes = {})
      @channel = attributes[:channel]
      @master = attributes[:master]
      update_voice
    end

    def update_voice
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
      update_voice
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

    def volume=(volume)
      puts volume
      v = volume.to_f
      puts v
      if v >= 0 && v <= 1
        # @voice_bot.volume = v
        @voice_bot.filter_volume = v
        ascii "Set volume to #{v} (applies to next song)"
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

    def add_websound_obj(obj)
      @youtube_queue.push(obj) if @voice_enabled && !obj.nil?
    end

    def queue(url, user)
      ws = WebSound.new link: url, user: user
      add_websound_obj ws
      play_file unless @youtube_playing
    end

    def play_file
      @youtube_playing = true
      until @youtube_queue.empty?
        stop_playing
        ws = @youtube_queue.shift
        ws.download
        broadcast "Playing: **#{ws.title}**\n#{ws.link}\nadded by *#{ws.user.name}*"
        @voice_bot.play_file(ws.file)
        ws.remove
        play_file
      end
      @youtube_playing = false
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

  class WebSound
    @@af = 'mp3'
    def initialize(attributes = {})
      @link = WebSound.expand(attributes[:link][1..-1])
      @user = attributes[:user]
      uri = URI(@link)
      begin
        @title = Net::HTTP.get(uri).scan(/<title>(.*)?<\/title>/i)[0][0]
      rescue
        @title = "~~could not get the title~~"
      end
    end

    def download
      @file = "/tmp/#{Time.now.to_f}.#{@@af}"
      cmd = "youtube-dl -x --no-playlist -o #{@file} --audio-quality 9 --audio-format #{@@af} #{@link} > /dev/null"
      system(cmd)
    end

    def remove
      FileUtils.rm(@file)
    end

    def self.expand(link)
      case link
      when /youtu\.be/
        "https://www.youtube.com/watch?v=#{link[/\/\w*?$/][1..-1]}"
      else
        link
      end
    end

    def title
      @title
    end

    def link
      @link
    end

    def file
      @file
    end

    def user
      @user
    end
  end
end
