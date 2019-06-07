#include <amxmodx>
#include <aps_chat>

enum _:MessageReturn {
	MESSAGE_IGNORED,
	MESSAGE_CHANGED,
	MESSAGE_BLOCKED
};

forward cm_player_send_message(const id, const message[], const team_chat);

public plugin_init() {
	register_plugin("[APS] Chat Manager Addon", "0.1.0", "GM-X Team");
}

public cm_player_send_message(const id) {
	return APS_ChatGetBlocketType(id) & APS_Chat_Text ? MESSAGE_BLOCKED : MESSAGE_IGNORED;
}