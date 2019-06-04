#include <amxmodx>

#define APS_MAX_REASON_LENGTH 32

public plugin_init() {
	register_plugin("[APS] Mixed", "0.1.0", "GM-X Team");

	// register_dictionary("admincmd.txt");
	// register_dictionary("common.txt");
	// register_dictionary("adminhelp.txt");

	register_concmd("amx_kick", "CmdKick", ADMIN_KICK);
	register_concmd("amx_slap", "CmdSlap", ADMIN_SLAY);
	register_concmd("amx_slay", "CmdSlay", ADMIN_SLAY);
}

public CmdKick(const id, const level) {
	enum { arg_player = 1, arg_reason };

	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	if (read_argc() < 1) {
		console_print(id, "USAGE: amx_kick <steamID or nickname or #authid or IP>  <reason>");
		return PLUGIN_HANDLED;
	}
	
	new target[32];
	read_argv(arg_player, target, charsmax(target));
	remove_quotes(target);
	new player = APS_FindPlayerByTarget(target);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}

	new reason[APS_MAX_REASON_LENGTH];
	read_argv(arg_reason, reason, charsmax(reason));
	remove_quotes(reason);
	
	playerKick(id, player, reason);
	
	return PLUGIN_HANDLED;
}

public CmdSlap(const id, const level) {
	enum { arg_player = 1, arg_damage };

	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	if (read_argc() < 2) {
		console_print(id, "USAGE: amx_slap <steamID or nickname or #authid or IP> <damage>");
		return PLUGIN_HANDLED;
	}
	
	new target[32];
	read_argv(arg_player, target, charsmax(target));
	remove_quotes(target);
	new player = APS_FindPlayerByTarget(target);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}
	
	new damage = read_argv_int(arg_damage);

	playerSlap(id, player, damage);
	
	return PLUGIN_HANDLED;
}

public CmdSlay(const id, const level) {
	enum { arg_player = 1  };

	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	if (read_argc() < 2) {
		console_print(id, "USAGE: amx_slay <steamID or nickname or #authid or IP>");
		return PLUGIN_HANDLED;
	}
	
	new target[32];
	read_argv(arg_player, target, charsmax(target));
	remove_quotes(target);
	new player = APS_FindPlayerByTarget(target);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}
	
	playerSlay(id, player);
	
	return PLUGIN_HANDLED;
}

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
	
public plugin_natives() {
	register_native("APS_PlayerKick", "NativeKick", 0);
	register_native("APS_PlayerSlap", "NativeSlap", 0);
	register_native("APS_PlayerSlay", "NativeSlay", 0);
}

public NativeKick(plugin, argc) {
	enum { arg_admin = 1, arg_player, arg_reason };

	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	
	new admin = get_param(arg_admin);
	if (admin != 0) {
		CHECK_NATIVE_PLAYER(admin, 0)
	}

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)
	
	new reason[APS_MAX_REASON_LENGTH];
	get_string(arg_reason, reason, charsmax(reason));
	
	playerKick(admin, player, reason);
	return 1;
}

public NativeSlap(plugin, argc) {
	enum { arg_admin = 1, arg_player, arg_damage };

	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	
	new admin = get_param(arg_admin);
	if (admin != 0) {
		CHECK_NATIVE_PLAYER(admin, 0)
	}

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)
	
	new damage = get_param(arg_damage);
	playerSlap(admin, player, damage);
	return 1;
}

public NativeSlay(plugin, argc) {
	enum { arg_admin = 1, arg_player };

	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	
	new admin = get_param(arg_admin);
	if (admin != 0) {
		CHECK_NATIVE_PLAYER(admin, 0)
	}

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	playerSlay(admin, player);
	return 1;
}

playerKick(const admin, const player, const reason[]) {
	#pragma unused admin
	new userid = get_user_userid(player);
	if (!is_user_bot(player) && reason[0] != EOS) {
		server_cmd("kick #%d ^"%s^"", userid, reason);
	} else {
		server_cmd("kick #%d", userid);
	}
	
	// log_amx("Kick: ^"%s<%d><%s><>^" kick ^"%s<%d><%s><>^" (reason ^"%s^")", name, get_user_userid(id), authid, name2, userid2, authid2, reason)

	// show_activity_key("ADMIN_KICK_1", "ADMIN_KICK_2", name, name2);
}

playerSlap(const admin, const player, const damage) {
	#pragma unused admin
	user_slap(player, damage);
}

playerSlay(const admin, const player) {
	#pragma unused admin
	user_kill(player);
}

stock APS_FindPlayerByTarget(const buffer[]) {
	if (buffer[0] == '#' && buffer[1]) {
		return find_player_ex(FindPlayer_MatchUserId, str_to_num(buffer[1]));
	}

	new result = find_player_ex(FindPlayer_MatchAuthId, buffer);
	if (!result) {
		result = find_player_ex(FindPlayer_MatchIP, buffer);
	}

	if (!result) {
		result = find_player_ex(FindPlayer_MatchNameSubstring | FindPlayer_CaseInsensitive|  FindPlayer_LastMatched, buffer);
	}

	return result;
}