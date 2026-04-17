#!/bin/sh
set -o errexit || exit $?

LAUNCHER=$(readlink -f "${0}")
HERE=$(dirname "${LAUNCHER}")

# TAKEN FROM: https://github.com/OpenRA/TiberianDawnHD/blob/master/launch-dedicated.sh
NAME="${Name:-"Dedicated AIO Server"}"
LAUNCH_MOD="${Mod}"
MAP="${Map:-""}"
LISTEN_PORT="${ListenPort:-"1234"}"
ADVERTISE_ONLINE="${AdvertiseOnline:-"True"}"
PASSWORD="${Password:-""}"
RECORD_REPLAYS="${RecordReplays:-"False"}"

REQUIRE_AUTHENTICATION="${RequireAuthentication:-"False"}"
PROFILE_ID_BLACKLIST="${ProfileIDBlacklist:-""}"
PROFILE_ID_WHITELIST="${ProfileIDWhitelist:-""}"

ENABLE_SINGLE_PLAYER="${EnableSingleplayer:-"False"}"
ENABLE_SYNC_REPORTS="${EnableSyncReports:-"False"}"
ENABLE_GEOIP="${EnableGeoIP:-"True"}"
ENABLE_LINT_CHECKS="${EnableLintChecks:-"True"}"
SHARE_ANONYMISED_IPS="${ShareAnonymizedIPs:-"True"}"

FLOOD_LIMIT_JOIN_COOLDOWN="${FloodLimitJoinCooldown:-"5000"}"

SUPPORT_DIR="/${DATA_DIR}/${GAME}"

# Create the support directory if it does not exist
mkdir -p "$SUPPORT_DIR"

# If MOTD env var is set, write it to motd.txt in the support directory for the game
if [ -n "$MOTD" ]; then
  echo "$MOTD" > "${SUPPORT_DIR}/motd.txt"
fi

dirSegment="openra" 
if [ "$LAUNCH_MOD" = "hv" ]; then
        dirSegment="openhv"
fi

# Run the game or server
if [ -n "$1" ] && [ "$1" = "--utility" ]; then
        # Drop the --utility argument
        shift
        "${HERE}/usr/bin/${dirSegment}-ra-utility" "$@"
else
        "${HERE}/usr/lib/${dirSegment}/OpenRA.Server" Game.Mod="${LAUNCH_MOD}" \
        Server.Name="$NAME" \
        Server.Map="$MAP" \
        Server.ListenPort="$LISTEN_PORT" \
        Server.AdvertiseOnline="$ADVERTISE_ONLINE" \
        Server.AdvertiseOnLocalNetwork="$ADVERTISE_ONLINE" \
        Server.EnableSingleplayer="$ENABLE_SINGLE_PLAYER" \
        Server.Password="$PASSWORD" \
        Server.RecordReplays="$RECORD_REPLAYS" \
        Server.RequireAuthentication="$REQUIRE_AUTHENTICATION" \
        Server.ProfileIDBlacklist="$PROFILE_ID_BLACKLIST" \
        Server.ProfileIDWhitelist="$PROFILE_ID_WHITELIST" \
        Server.EnableSyncReports="$ENABLE_SYNC_REPORTS" \
        Server.EnableGeoIP="$ENABLE_GEOIP" \
        Server.EnableLintChecks="$ENABLE_LINT_CHECKS" \
        Server.ShareAnonymizedIPs="$SHARE_ANONYMISED_IPS" \
        Server.FloodLimitJoinCooldown="$FLOOD_LIMIT_JOIN_COOLDOWN" \
        Engine.SupportDir="$SUPPORT_DIR" || : "$@"
fi