unit class API::Discord::Connection;

use API::Discord::Types;
use API::Discord::HTTPResource;
# Probably make API::Discord::Connection::WS later for hb etc
use Cro::WebSocket::Client::Connection;
use Cro::HTTP::Client;

has Str $.url is required;
has Str $.token is required;
has Int $.sequence;
has Str $.session-id;

has Cro::WebSocket::Client::Connection $.websocket;
has Cro::HTTP::Client $.rest;
has Promise $.opener;
has Supplier $!messages;
has Supply $!heartbeat;
has Promise $!hb-ack;
has Promise $.closer;

submethod TWEAK {
    $!rest = Cro::HTTP::Client.new(
        content-type => 'application/json',
        http => '1.1',
        headers => [
            Authorization => 'Bot ' ~ $!token,
            User-agent => "DiscordBot (https://github.io/kawaiiforms/p6-api-discord, 0.0.1)",
            Accept => 'application/json, */*',
            Accept-encoding => 'gzip, deflate',
            Connection => 'keep-alive',

        ]
    )
    but RESTy["https://discordapp.com/api"];

    $!messages = Supplier::Preserving.new;

    self.connect();
}

method connect() {
    my $cli = Cro::WebSocket::Client.new: :json;
    $!opener = $cli.connect($!url)
        .then( -> $connection {
            self._on_ws_connect($connection.result);
        });

}

method _on_ws_connect($!websocket) {
    my $messages = $!websocket.messages;
    $messages.tap:
        { self.handle-message($^a) }
    ;

    $!closer = $!websocket.closer.then(-> $closer {
        my $why = $closer.result;
        $!messages.done;
        $why;
    });
}

method handle-message($m) {
    # FIXME - this creates a Promise that may be broken, and we do nothing
    # about that. It was suggested I use the supply pattern instead, but I'm
    # not sure how right now
    $m.body.then({ self.handle-opcode($^a.result) }) if $m.is-text;
    # else what?
}

# $json is JSON with an op in it
method handle-opcode($json) {
    if $json<s> {
        $!sequence = $json<s>;
    }

    CATCH {.say}

    my $payload = $json<d>;
    my $event = $json<t>; # mnemonic: rtfm

    given ($json<op>) {
        when OPCODE::despatch {
            if $event eq 'READY' {
                $!session-id = $payload<session_id>;
            }
            else {
                # These are probably useful to the bot
                # We will figure out any that might not be, and handle them
                # here in future
                $!messages.emit($json);
            }
        }
        when OPCODE::invalid-session {
            note "Session invalid. Refreshing.";
            $!session-id = Str;
            $!sequence = Int;
            # Docs say to wait a random amount of time between 1 and 5
            # seconds, then re-auth
            Promise.in(4.rand+1).then({ self.auth });
        }
        when OPCODE::hello {
            self.auth;
            return if $!heartbeat;
            self.setup-heartbeat($payload<heartbeat_interval>/1000);
        }
        when OPCODE::reconnect {
            self.auth;
        }
        when OPCODE::heartbeat-ack {
            self.ack-heartbeat-ack;
        }
        default {
            note "Unhandled opcode $_ ({OPCODE($_)})";
            $!messages.emit($json);
        }
    }
}

method setup-heartbeat($interval) {
    $!heartbeat = Supply.interval($interval);
    $!heartbeat.tap: {
        note "♥";
        $!websocket.send({
            d => $!sequence,
            op => OPCODE::heartbeat,
        });

        # Set up a timeout that will be kept if the ack promise isn't
        $!hb-ack = Promise.new;
        Promise.anyof(
            Promise.in($interval - 1), $!hb-ack
        ).then({
            return if $!hb-ack;
            note "Heartbeat wasn't acknowledged! ☹";
            note "Attempting to reconnect...";
            self.connect;
        });
    };
}

method ack-heartbeat-ack {
    note "Still with us ♥";
    $!hb-ack.keep;
}

method auth {
    if ($!session-id and $!sequence) {
        note "Resuming session $!session-id at sequence $!sequence";
        $!websocket.send({
            op => OPCODE::resume,
            d => {
                token => $!token,
                session_id => $!session-id,
                sequence => $!sequence,
            }
        });
        return;
    }

    $!websocket.send({
        op => OPCODE::identify,
        d => {
            token => $!token,
            properties => {
                '$os' => $*PERL,
                '$browser' => 'API::Discord',
                '$device' => 'API::Discord',
            }
        }
    });
}

method messages returns Supply {
    $!messages.Supply;
}

method close {
    say "Closing connection";
    CATCH { .say }
    $!messages.done;
    #$!heartbeat.done;
    await $!websocket.close(code => 4001);
}
