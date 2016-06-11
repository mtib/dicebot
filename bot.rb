$LOAD_PATH << "."
require 'discordrb'
require 'dnd'

$bot = Discordrb::Bot.new token: ENV["DICEBOT"], application_id: (ENV["DICEBOTID"].to_i)
$games = {}

$bot.message(start_with: "/begin") do |event|
    if !$games.include? event.channel
        $games[event.channel] = DND::Game.new channel: event.channel, master: event.user
        event.channel.send_message "Started new Game! #{event.user.username} is the dungeon master!"
    else
        $games[event.channel].restart event.user
        event.channel.send_message "Restarted game, #{event.user.username} is the dungeon master!"
    end
end

def new_command(cmd, &block)
    $bot.message(start_with: "/#{cmd}") do |event|
        if $games.include? event.channel
            block.call event, $games[event.channel]
        else
            event.channel.send_message "No current game running: /begin"
        end
    end
end

new_command("roll") do |event, game|
    game.broadcast DND.roll_string(event.content).to_s
end

new_command("sroll") do |event, game|
    if event.user == game.master
        game.secret DND.roll_string(event.content).to_s
    else
        event.user.pm "Only the dungeon master should use this, but here you go: #{DND.roll_string(event.content)}"
    end

end

$bot.mention() do |event|
    event.send_message "I will now kill myself!"
    $bot.stop
end

$bot.run
