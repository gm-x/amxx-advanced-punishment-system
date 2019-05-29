#if defined _aps_consts_included
  #endinput
#endif
#define _aps_consts_included

const MAX_PUNISH_NAME_LENGTH = 64;

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