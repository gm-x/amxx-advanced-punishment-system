#if defined _aps_ban_included
	#endinput
#endif

#define _aps_ban_included

forward APS_PlayerBanKick(const id);

native APS_Ban(const admin, const player, const time, const reason[], const details[] = "");
