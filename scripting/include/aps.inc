#if defined _aps_included
	#endinput
#endif

#define _aps_included

#include <aps_consts>

forward APS_Initing();
forward APP_Inited();
forward APS_PlayerPunishing(const id, const type);
forward APS_PlayerPunished(const id, const type);

native APS_RegisterType(const name[]);
native APS_GetTypeIndex(const name[]);
native APS_GetTypeName(const index, value[], len);
native APS_PunishPlayer(const id, const type, const expired, const reason[], const details[] = "", const punisherId = 0);
native APS_GetExpired();
native APS_SetExpired(const expired);
native APS_GetReason(value[], const len);
native APS_SetReason(const value[]);
native APS_GetDetails(value[], const len);
native APS_SetDetails(const value[]);
