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

stock bool:APS_CanUserPunish(const index, target = 0, access = 0, checks = 0) {
	new bitsum;
	if (access && (checks & APS_CheckAccess)) {
		if ((get_user_flags(index) & access) == access) {
			bitsum |= APS_CheckAccess;          
		}
	}

	if (target && (checks & APS_CheckImmunityLevel)) {
		if (GMX_PlayerGetImmunity(index) > GMX_PlayerGetImmunity(target)) {
			bitsum |= APS_CheckImmunityLevel;
		}
	}
	
	return bool:((bitsum & checks) == checks);
}
