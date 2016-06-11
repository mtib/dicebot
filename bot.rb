$LOAD_PATH << "."
require 'discordrb'
require 'dnd'

$bot = Discordrb::Bot.new token: ENV["DICEBOT"], application_id: (ENV["DICEBOTID"].to_i)
$games = {}

$bot.message(start_with: "/begin") do |event|
    if !$games.include? event.channel
        $games[event.channel] = DND::Game.new channel: event.channel, master: event.user
        event.send_message "Started new Game! #{event.user.username} is the dungeon master!"
    else
        $games[event.channel].restart event.user
        event.send_message "Restarted game, #{event.user.username} is the dungeon master!"
    end
end

$bot.message(start_with: "/help") do |event|
    event.send_message  <<-EOF
**Hello, I am dicebot**
\n```/begin``` to begin a round of DND
```/roll xDy``` to roll x y-sided dice
```/sroll xDy``` to roll x y-sided dice in secret
EOF
end

$bot.message(start_with: "/debug") do |event|
    if $games.include? event.channel
        event.send_message $games[event.channel].debug
    end
end

$bot.message(start_with: "/skip") do |event|
    if $games.include? event.channel
        $games[event.channel].stop_playing
    end
end

def new_command(cmd, &block)
    $bot.message(start_with: "/#{cmd}") do |event|
        if $games.include? event.channel
            block.call event, $games[event.channel]
        else
            event.send_message "No current game running: /begin"
        end
    end
end

new_command("roll") do |event, game|
    game.broadcast DND.roll_string(event.content).to_s
end

new_command("voice") do |event, game|
    if game.voice_enabled
        permission = game.voice_connect($bot)
        game.broadcast "Connection established" if permission
    end
end

new_command("applause") do |event, game|
    game.play_file("#{ENV["PWD"]}/applause2.mp3")
end

# this depends on the python application youtube-dl
new_command("youtube") do |event, game|
    @channel.ascii "Adding your video to the queue"
    af = "mp3"
    file = "/tmp/dicebot_#{Time.new.to_f.to_s}.#{af}"
    url = event.text[/ \S+youtu.?be\S+/]
    cmd = "(youtube-dl -x --no-playlist -o #{file} --audio-quality 9 --audio-format #{af}#{url}) > /dev/null"
    system(cmd)
    game.play_file(file)
end

new_command("sroll") do |event, game|
    if event.user == game.master
        game.secret DND.roll_string(event.content).to_s
    else
        event.user.pm "Only the dungeon master should use this, but here you go: #{DND.roll_string(event.content)}"
    end

end

$bot.mention(from: "mtib") do |event|
    event.send_message "I will now kill myself!"
    $bot.stop
end

puts $bot.invite_url
$bot.run
