#include <amxmodx>
#include <aps>

new APS_Type:TypeId;
new bool:Muted[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Chat Voice ReAPI", APS_VERSION_STR, "GM-X Team");
	RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "CSGameRules_CanPlayerHearPlayer_Pre", false);
}

public client_disconnected(id) {
	Muted[id] = false;
}

public APS_PlayerChecking(const id) {
	Muted[id] = false;
}

public APS_Inited() {
	TypeId = APS_GetTypeIndex("voice_chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS] Type voice_chat not registered");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId) {
		Muted[id] = true;
	}
}

public APS_PlayerAmnestying(const id, const APS_Type:type) {
	if (type == TypeId) {
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
