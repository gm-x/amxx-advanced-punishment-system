#include <amxmodx>
// #include <gmx>
#include <aps>

const ACCESS_FLAG = ADMIN_BAN;

#if !defined NOT_CLIENT
	const NOT_CLIENT = 0;
#endif

#if !defined MAX_REASON_LENGTH
	const MAX_REASON_LENGTH = 64;
#endif

#if !defined MAX_INFO_LENGTH
	const MAX_INFO_LENGTH = 64;
#endif

#if !defined MAX_TIME_STRING_LENGTH
	const MAX_TIME_STRING_LENGTH = 12;
#endif

new TypeId;

public plugin_init() {
	register_plugin("[APS] Ban", "0.1.0", "GM-X Team");
	
	register_concmd("aps_ban", "CmdBan", ADMIN_BAN);
}

public APS_Initing() {
	TypeId = APS_RegisterType("ban");
}

public APS_PlayerPunished(const id, const type) {
	if(type != TypeId) {
		return;
	}
	
	new reason[APS_MAX_REASON_LENGTH];
	APS_GetReason(reason, charsmax(reason));
	if (reason[0] != EOS) {
		server_cmd("kick #%d ^"%s^"", get_user_userid(id), reason);
	} else {
		server_cmd("kick #%d", get_user_userid(id));
	}
}

public CmdBan(const id, const level) {
	enum { arg_player = 1, arg_time, arg_reason, arg_details };

	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	if (read_argc() < 2) {
		console_print(id, "USAGE: aps_ban <steamID or nickname or #authid or IP> <time in mins> <reason> [details]");
		return PLUGIN_HANDLED;
	}

	new tmp[32];
	read_argv(arg_player, tmp, charsmax(tmp));
	new player = findClientIndexByTarget(tmp);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}

	new time = read_argv_int(arg_time);

	new reason[32], details[32];
	read_argv(arg_reason, reason, charsmax(reason));
	read_argv(arg_details, details, charsmax(details));

	APS_PunishPlayer(player, TypeId, time, reason, details, id);

	return PLUGIN_HANDLED;
}

findClientIndexByTarget(const buffer[]) {
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