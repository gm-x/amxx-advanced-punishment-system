#include <amxmodx>
#include <reapi>
#include <aps>
#include <aps_chat>

#define MAX_CMD_LENGTH 32

enum _:CmdData {
	CmdFlags,
	CmdAccess,
	CmdName[MAX_CMD_LENGTH]
};

new const Commands[][CmdData] = {
	{ APS_Chat_Voice, ADMIN_CHAT, "amx_mute" },
	{ APS_Chat_Text, ADMIN_CHAT, "amx_gag" },
	{ APS_Chat_Voice | APS_Chat_Text, ADMIN_CHAT, "amx_blockchat" }
};

new Blocked[MAX_PLAYERS + 1];
new APS_Type:TypeId;

public plugin_init() {
	register_plugin("[APS] Chat", "0.1.1", "GM-X Team");

	for(new i; i < sizeof Commands; i++) {
		register_concmd(Commands[i][CmdName], "CmdHandle", Commands[i][CmdAccess]);
	}
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

public APS_PlayerPunished(const id, const APS_Type:type) {
	if(type != TypeId) {
		return;
	}

	Blocked[id] = APS_GetExtra();
}

public APS_PlayerExonerated(const id, const APS_Type:type) {
	if(type != TypeId) {
		return;
	}

	Blocked[id] &= ~APS_GetExtra();
}

public CmdHandle(const id, const access) {
	if(~get_user_flags(id) & access) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	enum { arg_cmd, arg_player, arg_time, arg_reason, arg_details };

	new tmp[32];
	read_argv(arg_cmd, tmp, charsmax(tmp));
	new command = getCommandByName(tmp);

	if(command == INVALID_HANDLE) {
		console_print(id, "Command not found!");
		return PLUGIN_HANDLED;
	}

	read_argv(arg_player, tmp, charsmax(tmp));

	new player = APS_FindPlayerByTarget(tmp);

	if(!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}
 
	if(read_argc() < 3) {
		console_print(id, "USAGE: %s <steamID or nickname or #authid or IP> <time in mins> <reason> [details]", Commands[command][CmdName]);
		return PLUGIN_HANDLED;
	}

	new time = read_argv_int(arg_time) * 60;
	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];

	read_argv(arg_reason, reason, charsmax(reason));
	read_argv(arg_details, details, charsmax(details));

	APS_PunishPlayer(player, TypeId, time, reason, details, id, Commands[command][CmdFlags]);

	return PLUGIN_HANDLED;
}

getCommandByName(const name[]) {
	for(new i, n = sizeof Commands; i < n; i++) {
		if(!strcmp(Commands[i][CmdName], name)) {
			return i;
		}
	}

	return INVALID_HANDLE;
}

public plugin_natives() {
	register_native("APS_ChatGetBlockedType", "NativeChatGetBlockedType", 0);
	register_native("APS_ChatGetBlockedText", "NativeChatGetBlockedText", 0);
	register_native("APS_ChatGetBlockedVoice", "NativeChatGetBlockedVoice", 0);
}

public NativeChatGetBlockedType(plugin, argc) {
	enum { arg_player = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	return Blocked[player];
}

public NativeChatGetBlockedText(plugin, argc) {
	enum { arg_player = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	return Blocked[player] & APS_Chat_Text ? 1 : 0;
}

public NativeChatGetBlockedVoice(plugin, argc) {
	enum { arg_player = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	return Blocked[player] & APS_Chat_Voice ? 1 : 0;
}
