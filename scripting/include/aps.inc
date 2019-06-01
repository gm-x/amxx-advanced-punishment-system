#if defined _aps_included
	#endinput
#endif

#define _aps_included

#include <aps_consts>

forward APS_Initing();
forward APP_Inited();
//forward APS_PunishedPlayerPost(const id, const typeId, const expired);

native APS_RegisterType(const name[]);
native APS_GetTypeIndex(const name[]);
native APS_GetTypeName(const index, value[], len);
native APS_PunishPlayer(const id, const type, const expired, const reason[], const details[] = "", const punisherId = 0, const extra = 0);
