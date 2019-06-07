#include <amxmodx>
#include <aps>

enum FWD {
	FWD_PlayerKick,
	FWD_PlayerKicked,
	FWD_PlayerSlap,
	FWD_PlayerSlaped,
	FWD_PlayerSlay,
	FWD_PlayerSlayed,
}

new Forwards[FWD], FwdReturn;

public plugin_init() {
	register_plugin("[APS] Mixed", "0.1.0", "GM-X Team");

	// register_dictionary("admincmd.txt");
	// register_dictionary("common.txt");
	// register_dictionary("adminhelp.txt");

	register_concmd("amx_kick", "CmdKick", ADMIN_KICK);
	register_concmd("amx_slap", "CmdSlap", ADMIN_SLAY);
	register_concmd("amx_slay", "CmdSlay", ADMIN_SLAY);

	Forwards[FWD_PlayerKick] = CreateMultiForward("APS_PlayerKick", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
	Forwards[FWD_PlayerKicked] = CreateMultiForward("APS_PlayerKicked", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING);
	Forwards[FWD_PlayerSlap] = CreateMultiForward("APS_PlayerSlap", ET_STOP, FP_CELL, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerSlaped] = CreateMultiForward("APS_PlayerSlaped", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerSlay] = CreateMultiForward("APS_PlayerSlay", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerSlayed] = CreateMultiForward("APS_PlayerSlayed", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_end() {
	DestroyForward(Forwards[FWD_PlayerKick]);
	DestroyForward(Forwards[FWD_PlayerKicked]);
	DestroyForward(Forwards[FWD_PlayerSlap]);
	DestroyForward(Forwards[FWD_PlayerSlaped]);
	DestroyForward(Forwards[FWD_PlayerSlay]);
	DestroyForward(Forwards[FWD_PlayerSlayed]);
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

	if (!playerKick(id, player, reason)) {
		console_print(id, "Kick was canceled");
	} else {
		console_print(id, "Player ^"%n^" kicked with reason ^"%s^"", player, reason);
	}
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

	if (!playerSlap(id, player, damage)) {
		console_print(id, "Slap was canceled");
	} else {
		console_print(id, "Player ^"%n^" slaped with %d damage", player, damage);
	}
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
	
	if (!playerSlay(id, player)) {
		console_print(id, "Slap was canceled");
	} else {
		console_print(id, "Player ^"%n^" slayed", player);
	}
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
	
	return playerKick(admin, player, reason) ? 1 : 0;
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
	return playerSlap(admin, player, damage) ? 1 : 0;
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

	return playerSlay(admin, player) ? 1 : 0;
}

bool:playerKick(const admin, const player, const reason[]) {
	ExecuteForward(Forwards[FWD_PlayerKick], FwdReturn, admin, player, reason);
	if (FwdReturn == PLUGIN_HANDLED) {
		return false;
	}
	new userid = get_user_userid(player);
	if (!is_user_bot(player) && reason[0] != EOS) {
		server_cmd("kick #%d ^"%s^"", userid, reason);
	} else {
		server_cmd("kick #%d", userid);
	}
	ExecuteForward(Forwards[FWD_PlayerKicked], FwdReturn, admin, player, reason);
	return true;
}

bool:playerSlap(const admin, const player, const damage) {
	ExecuteForward(Forwards[FWD_PlayerSlap], FwdReturn, admin, player, damage);
	if (FwdReturn == PLUGIN_HANDLED) {
		return false;
	}
	user_slap(player, damage);
	ExecuteForward(Forwards[FWD_PlayerSlaped], FwdReturn, admin, player, damage);
	return true;
}

bool:playerSlay(const admin, const player) {
	ExecuteForward(Forwards[FWD_PlayerSlay], FwdReturn, admin, player);
	if (FwdReturn == PLUGIN_HANDLED) {
		return false;
	}
	user_kill(player);
	ExecuteForward(Forwards[FWD_PlayerSlayed], FwdReturn, admin, player);
	return true;
}
