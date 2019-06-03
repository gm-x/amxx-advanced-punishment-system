#if defined _aps_included
	#endinput
#endif

#define _aps_included

#include <aps_consts>
#include <aps_stocks>

forward APS_Initing();
forward APP_Inited();
forward APS_PlayerPunishing(const id, const type);
forward APS_PlayerPunished(const id, const type);

native APS_RegisterType(const name[]);
native APS_GetTypeIndex(const name[]);
native APS_GetTypeName(const index, value[], len);
native APS_PunishPlayer(const id, const type, const time, const reason[], const details[] = "", const punisherId = 0, const extra = 0);
native APS_GetId();
native APS_GetExtra();
native APS_SetExtra(const value);
native APS_GetTime();
native APS_SetTime(const value);
native APS_GetExpired();
native APS_SetExpired(const value);
native APS_GetReason(value[], const len);
native APS_SetReason(const value[]);
native APS_GetDetails(value[], const len);
native APS_SetDetails(const value[]);
