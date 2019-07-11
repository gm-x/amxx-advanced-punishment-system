#if defined _aps_stocks_included
	#endinput
#endif

#define _aps_stocks_included

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
