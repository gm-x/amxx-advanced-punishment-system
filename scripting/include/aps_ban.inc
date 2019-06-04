#if defined _aps_ban_included
	#endinput
#endif

#define _aps_ban_included

forward APS_PlayerKick(const id);

native APS_PlayerBan(const admin, const player, const time, const reason[], const details[] = "");