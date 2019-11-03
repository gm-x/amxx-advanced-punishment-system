#include <amxmodx>
#include <reapi>
#include <aps>
#include <aps_chat>

new APS_Type:TypeId;
new bool:Muted[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Chat Voice ReAPI", "0.1.2", "GM-X Team");
	RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "CSGameRules_CanPlayerHearPlayer_Pre", false);
}

public client_connect(id) {
	Muted[id] = false;
}

public client_disconnected(id) {
	Muted[id] = false;
}

public APS_Inited() {
	TypeId = APS_GetTypeIndex("chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS CHAT REAPI] chat type not found");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Voice) {
		Muted[id] = true;
	}
}

public APS_PlayerExonerated(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Voice) {
		Muted[id] = false;
	}
}

public CSGameRules_CanPlayerHearPlayer_Pre(const listener, const sender) {
	if (Muted[sender]) {
		SetHookChainReturn(ATYPE_BOOL, false);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}
