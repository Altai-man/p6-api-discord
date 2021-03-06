unit module API::Discord::Types;

subset Snowflake is export of Str where /^ <[ 0 1 ]> ** 64 $/;

enum OPCODE is export (
    <despatch heartbeat identify status-update
    voice-state-update voice-ping
    resume reconnect
    request-members
    invalid-session hello heartbeat-ack>
);

enum CLOSE-EVENT is export (
);

