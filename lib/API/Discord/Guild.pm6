use API::Discord::Object;

unit class API::Discord::Guild does API::Discord::Object;

has %.ENDPOINTS is readonly =
    create => '/guilds',
    read => '/guilds/{guild-id}',
    update => '/guilds/{guild-id}',
    delete => '/guilds/{guild-id}',

    get-channels => '/guilds/{guild-id}/channels',
    create-channel => '/guilds/{guild-id}/channels',

    get-member => '/guilds/{guild-id}/members/{user-id}',
    list-members => '/guilds/{guild-id}/members',
    add-member => '/guilds/{guild-id}/members/{user-id}',
    modify-member => '/guilds/{guild-id}/members/{user-id}',
    remove-member => '/guilds/{guild-id}/members/{user-id}',

    get-bans => '/guilds/{guild-id}/bans',
    create-ban => '/guilds/{guild-id}/bans/{user-id}',
    revoke-ban => '/guilds/{guild-id}/bans/{user-id}',

    get-prune-count => '/guilds/{guild-id}/prune',
    begin-prune => '/guilds/{guild-id}/prune',

    get-integrations => '/guilds/{guild-id}/integrations',
    create-integration => '/guilds/{guild-id}/integrations',
    modify-integration => '/guilds/{guild-id}/integrations/{integration-id}',
    delete-integration => '/guilds/{guild-id}/integrations/{integration-id}',
    sync-integration => '/guilds/{guild-id}/integrations/{integration-id}/sync',

    get-embed => '/guilds/{guild-id}/embed',
    modify-embed => '/guilds/{guild-id}/embed',

    modify-nick => '/guilds/{guild-id}/members/@me/nick',
    get-invites => '/guilds/{guild-id}/invites',
    get-voice-regions => '/guilds/{guild-id}/regions',
    audit-log => '/guilds/{guild-id}/audit-logs',
    vanity-url => '/guilds/{guild-id}/vanity-url',
;

has $.id;
has $.name;
has $.icon;
has $.splash;
has $.is-owner;
has $.owner-id;
has $.permissions;
has $.region;
has $.afk-channel-id;
has $.afk-channel-timeout;
has $.is-embeddable;
has $.embed-channel-id;
has $.verification-level;
has $.default-notification-level;
has $.content-filter-level;
has $.mfa-level-required;
has $.application-id;
has $.is-widget-enabled;
has $.widget-channel-id;
has $.system-channel-id;
has DateTime $.joined-at;
has $.is-large;
has $.is-unavailable;
has $.member-count;

has @.roles;
has @.emojis;
has @.features;
has @.voice-states;
has @.members;
has @.channels;
has @.presences;

enum MessageNotificationLevel (
    <notification-all-messages notification-only-mentions>
);

enum ContentFilterLevel (
    <filter-disabled filter-members-without-roles filter-all-members>
);

enum MFALevel (
    <mfa-none mfa-elevated>
);

enum VerificationLevel (
    <verification-none verification-low verification-medium verification-high verification-very-high>
);

method to-json {}
method from-json ($json) {}
