#if defined _aps_consts_included
  #endinput
#endif
#define _aps_consts_included

#define APS_MAX_TYPE_LENGTH 32
#define APS_MAX_REASON_LENGTH 64
#define APS_MAX_DETAILS_LENGTH 64

const MAX_PUNISH_DESC_LENGTH = 64;

enum APS_PunisherType {
	APS_PunisherTypePlayer,
	APS_PunisherTypeUser,
	APS_PunisherTypeServer
};
 
enum APS_PunishmentStatus {
	APS_PunishmentStatusActive,
	APS_PunishmentStatusInactive
};