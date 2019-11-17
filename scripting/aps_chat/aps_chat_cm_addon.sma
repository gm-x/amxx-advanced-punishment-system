#include <amxmodx>
#include <aps>
#include <aps_chat>

enum _:MessageReturn {
	MESSAGE_IGNORED,
	MESSAGE_CHANGED,
	MESSAGE_BLOCKED
};

forward cm_player_send_message(const id, const message[], const team_chat);

new APS_Type:TypeId;
new bool:Blocked[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Text Chat CM Addon", APS_VERSION_STR, "GM-X Team");
}

public client_disconnected(id) {
	Blocked[id] = false;
}

public APS_PlayerChecking(const id) {
	Blocked[id] = false;
}

public APS_Inited() {
	TypeId = APS_GetTypeIndex("text_chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS CHAT REAPI] Type text_chat not registered");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId) {
		Blocked[id] = true;
	}
}

public APS_PlayerAmnestying(const id, const APS_Type:type) {
	if (type == TypeId) {
		Blocked[id] = false;
	}
}

public cm_player_send_message(const id) {
	if (!Blocked[id]) {
		return MESSAGE_IGNORED;
	}
	return MESSAGE_BLOCKED;
}
