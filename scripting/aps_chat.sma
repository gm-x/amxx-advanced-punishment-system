#include <amxmodx>
#include <reapi>
#include <aps>
#include <aps_chat>

#define CHECK_NATIVE_ARGS_NUM(%1,%2,%3) \
	if (%1 < %2) { \
		log_error(AMX_ERR_NATIVE, "Invalid num of arguments %d. Expected %d", %1, %2); \
		return %3; \
	}
 
#define CHECK_NATIVE_PLAYER(%1,%2) \
	if (!is_user_connected(%1)) { \
		log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
		return %2; \
	}

new TypeId;
new Blocked[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Chat", "0.1.0", "GM-X Team");

	if (!has_vtc()) {
		RegisterHookChain(RG_CSGameRules_CanPlayerHearPlayer, "CSGameRules_CanPlayerHearPlayer_Pre", false);
	}
	
	register_concmd("aps_chat", "CmdChat", ADMIN_CHAT);
	register_concmd("aps_mute", "CmdMute", ADMIN_CHAT);
	register_concmd("aps_gag", "CmdGag", ADMIN_CHAT);
}

public APS_Initing() {
	TypeId = APS_RegisterType("chat");
}

public client_connect(id) {
	Blocked[id] = 0;
}

public client_disconnected(id) {
	Blocked[id] = 0;
}

public APS_PlayerPunished(const id, const type) {
	if(type != TypeId) {
		return;
	}

	Blocked[id] = APS_GetExtra();
	if (Blocked[id] & APS_Chat_Voice && has_vtc()) {
		VTC_MuteClient(id);
	}
}

public CSGameRules_CanPlayerHearPlayer_Pre(const listener, const sender) {
	if (Blocked[sender] & APS_Chat_Voice) {
		SetHookChainReturn(ATYPE_INTEGER, 0);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public CmdChat(const id, const level) {
	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	return processCommand(id, APS_Chat_Voice | APS_Chat_Text);
}

public CmdMute(const id, const level) {
	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	return processCommand(id, APS_Chat_Voice);
}

public CmdGag(const id, const level) {
	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	return processCommand(id, APS_Chat_Text);
}

processCommand(const id, const extra) {
	enum { arg_player = 1, arg_time, arg_reason, arg_details };
	
	if (read_argc() < 2) {
		console_print(id, "USAGE: aps_mute <steamID or nickname or #authid or IP> <time in mins> <reason> [details]");
		return PLUGIN_HANDLED;
	}

	new tmp[32];
	read_argv(arg_player, tmp, charsmax(tmp));
	new player = APS_FindPlayerByTarget(tmp);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}

	new time = read_argv_int(arg_time) * 60;

	new reason[32], details[32];
	read_argv(arg_reason, reason, charsmax(reason));
	read_argv(arg_details, details, charsmax(details));

	APS_PunishPlayer(player, TypeId, time, reason, details, id, extra);

	return PLUGIN_HANDLED;
}

public plugin_natives() {
	register_native("APS_ChatGetBlocketType", "NativeChatGetBlocketType", 0);
}

public NativeChatGetBlocketType(plugin, argc) {
	enum { arg_player = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	return Blocked[player];
}