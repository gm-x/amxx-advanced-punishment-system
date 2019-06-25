#include <amxmodx>
#include <reapi>
// #include <VtcApi>
#include <aps>
#include <aps_chat>

new APS_Type:TypeId;

public plugin_init() {
	register_plugin("[APS] Chat VTC ReAPI", "0.1.1", "GM-X Team");

	if (!has_vtc()) {
		set_fail_state("[APS CHAT VTC REAPI] VoiceTranscoder not found");
	}
}

public APP_Inited() {
	TypeId = APS_GetTypeIndex("chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS CHAT VTC REAPI] chat type not found");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Voice) {
		VTC_MuteClient(id);
	}
}

public APS_PlayerExonerated(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Voice) {
		VTC_UnmuteClient(id);
	}
}