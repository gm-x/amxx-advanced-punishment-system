#include <amxmodx>
#include <reapi>
#include <aps_chat>

public plugin_init() {
	register_plugin("[APS] Chat Voice ReAPI", "0.1.0", "GM-X Team");
	RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "CSGameRules_CanPlayerHearPlayer_Pre", false);
}

public CSGameRules_CanPlayerHearPlayer_Pre(const listener, const sender) {
	if (APS_ChatGetBlockedVoice(sender)) {
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}
