#if defined _aps_mixed_included
  #endinput
#endif
#define _aps_mixed_included

forward APS_PlayerKick(const admin, const player, const reason[]);
forward APS_PlayerKicked(const admin, const player, const reason[]);

forward APS_PlayerSlap(const admin, const player, const damage);
forward APS_PlayerSlaped(const admin, const player, const damage);

forward APS_PlayerSlay(const admin, const player);
forward APS_PlayerSlayed(const admin, const player);

native APS_PlayerKick(const admin, const player, const reason[]);
native APS_PlayerSlap(const admin, const player, const damage);
native APS_PlayerSlay(const admin, const player);
