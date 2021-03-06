use API::Discord::Types;
use API::Discord::Connection;

use API::Discord::Channel;
use API::Discord::Guild;
use API::Discord::Message;
use API::Discord::User;

use Cro::WebSocket::Client;
use Cro::WebSocket::Client::Connection;

unit class API::Discord is export;

has Connection $!conn;
# Although a number it goes in a URL so it's a string
has Str $.version = '6';
has Str $.host = 'gateway.discord.gg';
has Str $.token is required;

# Docs say, increment number each time, per process
has Int $!snowflake = 0;

has Supplier $.messages = Supplier.new;

has %.channels;

method !start-message-tap {
    $!conn.messages.tap( -> $message {
        self!handle-message($message);
        $!messages.emit($message);
    })
}

method !handle-message($message) {
    if $message<d><channels> {
        for $message<d><channels>.values -> $c {
            %.channels{$c<id>} = self.create-channel($c);
        }
    }
    else { $message.say }
}

submethod DESTROY {
    $!conn.close;
}

method connect($session-id?, $sequence?) returns Promise {
    $!conn = Connection.new(
        url => "wss://{$.host}/?v={$.version}&encoding=json",
        token => $.token,
      |(:$session-id if $session-id),
      |(:$sequence if $sequence),
    );

    return $!conn.opener.then({ self!start-message-tap; $!conn.closer });
}

method messages returns Supply {
    $!messages.Supply;
}

multi method send-message($m) {
    # FIXME: decide how to translate "send" to "post" but only for message
    #$!conn.send($m);
}

multi method send-message(Str :$message, Str :$to) {
    # my $c = %.channels{$to} or die;
    # my $m = API::Discord::Message.new(... content => $message, channel => $c)
    # self.send-message($m)
    my $json = {
        tts => False,
        type => 0,
        channel_id => $to,
        content => $message,
        nonce => self.generate-snowflake,
        embed => {},
    };

    # FIXME: conn doesn't have a send any more
    #$!conn.send($json);
}

method generate-snowflake {
    my $time = DateTime.now - DateTime.new(year => 2015);
    my $worker = 0;
    my $proc = 0;
    my $s = $!snowflake++;

    return ($time.Int +< 22) + ($worker +< 17) + ($proc +< 12) + $s;
}

####### Object factories
# get-* will fetch
# create-* will construct

method get-messages (Int @message-ids) returns Array[Message] {
}

method create-message ($json) returns Message {
}

method get-channels (Int @channel-ids) returns Array[Channel] {
}

method create-channel ($json) returns API::Discord::Channel {
    API::Discord::Channel.from-json($json);
}
