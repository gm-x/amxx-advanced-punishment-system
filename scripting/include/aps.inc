#if defined _aps_included
	#endinput
#endif

#define _aps_included

#include <aps_consts>
#include <aps_stocks>
#include <aps_version>

enum APS_Type {
	APS_InvalidType = -1,
};

forward APS_Initing();
forward APS_Inited();
forward APS_PlayerPunishing(const id, const APS_Type:type);
forward APS_PlayerPunished(const id, const APS_Type:type);
forward APS_PlayerAmnestying(const id, const APS_Type:type);
forward APS_PlayerAmnestied(const id, const APS_Type:type);
forward APS_PlayerChecking(const id);
forward APS_PlayerChecked(const id);

native APS_Type:APS_RegisterType(const name[]);
native bool:APS_IsValidType(const APS_Type:type);
native APS_GetTypesNum();
native APS_Type:APS_GetTypeIndex(const name[]);
native APS_GetTypeName(const APS_Type:index, value[], len);
native bool:APS_PunishPlayer(const player, const APS_Type:type, const time, const reason[], const details[] = "", const punisherId = 0, const extra = 0);
native bool:APS_AmnestyPlayer(const player, const APS_Type:type);
native bool:APS_GetPlayerPunishment(const player, const APS_Type:type);
native APS_GetId();
native APS_GetExtra();
native APS_SetExtra(const value);
native APS_GetTime();
native APS_SetTime(const value);
native APS_GetCreated();
native APS_SetCreated(const value);
native APS_GetExpired();
native APS_SetExpired(const value);
native APS_GetReason(value[], const len);
native APS_SetReason(const value[]);
native APS_GetDetails(value[], const len);
native APS_SetDetails(const value[]);
native APS_PunisherType:APS_GetPunisherType();
native APS_SetPunisherType(const APS_PunisherType:value);
native APS_GetPunisherId();
native APS_SetPunisherId(const value);
/*
* This is callback from APS Core that gives major/minor versions for verifying compatibility for APS versions.
* Do not modify this!
*/
public __aps_version_check(const majorVersion, const minorVersion) {
	if(majorVersion != APS_MAJOR_VERSION) {
		set_fail_state("Api major version mismatch; expected %d, real %d", APS_MAJOR_VERSION, majorVersion);
		return;
	}

	if(minorVersion < APS_MINOR_VERSION){
		set_fail_state("Api minor version mismatch; expected at least %d, real %d", APS_MINOR_VERSION, minorVersion);
		return;
	}
}
