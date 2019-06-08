#include <amxmodx>
#include <aps>
#include <aps_chat>

new APS_Type:TypeId;
new bool:Blocked[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Chat CM Addon", "0.1.0", "GM-X Team");
}

public client_connect(id) {
	Blocked[id] = false;
}

public client_disconnected(id) {
	Blocked[id] = false;
}

public APP_Inited() {
	TypeId = APS_GetTypeIndex("chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS CHAT VTC] chat module not found");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Text) {
		Blocked[id] = true;
	}
}

public APS_PlayerExonerated(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Text) {
		Blocked[id] = false;
	}
}
