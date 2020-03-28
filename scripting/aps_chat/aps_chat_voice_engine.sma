#include <amxmodx>
#include <engine>
#include <aps>

new APS_Type:TypeId;

public plugin_init() {
	register_plugin("[APS] Chat VTC Engine", APS_VERSION_STR, "GM-X Team");
}

public APS_Inited() {
	TypeId = APS_GetTypeIndex("voice_chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS] Type voice_chat not registered");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId) {
		set_speak(id, SPEAK_MUTED);
	}
}

public APS_PlayerAmnestying(const id, const APS_Type:type) {
	if (type == TypeId) {
		set_speak(id, SPEAK_NORMAL);
	}
}
