#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <grip>
#include <gmx>
#include <gmx_player>
#include <aps>
//#include <uac>

#define CHECK_NATIVE_ARGS_NUM(%1,%2) \
	if (%1 < %2) { \
		log_error(AMX_ERR_NATIVE, "Invalid num of arguments %d. Expected %d", %1, %2); \
		return 0; \
	}
 
#define CHECK_NATIVE_PLAYER(%1) \
	if (!is_user_connected(%1)) { \
		log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
		return 0; \
	}

/*enum _:Type {
	TypeName[MAX_TYPE_NAME_LEN],
	TypePunishHandler,
	TypeUnPunishHandler,
}

enum PunishmentStatus {
	PunishmentStatusActive,
	PunishmentStatusExpired,
	PunishmentStatusUnpunished,
}

enum _:Punishment {
	PunishmentType,
	PunishmentExpired,
	PunishmentReason[],
	PunishmentComment[],
	PunishmentPunisherType,
	PunishmentPunisher,
}*/

/*const MAX_COMMENT_LENGTH = 64;
const MAX_REASON_LENGTH = 64;
const MAX_INFO_LENGTH = 64;
const MAX_TIME_STRING_LENGTH = 12;*/

enum CORE_FORWARDS {
	FW_PUNISH_PLAYER_PRE,
	FW_PUNISH_PLAYER_POST,
	FW_CHECK_PLAYER_PRE,
	FW_CHECK_PLAYER_POST,
	FW_UNPUNISH_PLAYER_PRE,
	FW_UNPUNISH_PLAYER_POST
};

new g_Forwards[CORE_FORWARDS];

enum _:PunishmentStruc {
	PunishmentID,
	PunishmentType[32],
	PunishmentExpired,
	PunishmentReason[32],
	PunishmentDetails[32],
	APS_PunisherType:PunishmentPunisherType,
	PunishmentPunisherID,
	APS_PunishmentStatus:PunishmentStatus
};
 
new Punishment[PunishmentStruc];
 
new Array:PlayersPunishment[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Core", "0.0.1b", "GM-X Team");

	for (new i = 1; i <= MAX_PLAYERS; i++) {
		PlayersPunishment[i] = ArrayCreate(PunishmentStruc, 0);
	}

	RegisterCoreForwards();
}

public plugin_end() {
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		ArrayDestroy(PlayersPunishment[i]);
	}
}

public GMX_PlayerLoading(const id) {
	ArrayClear(PlayersPunishment[id]);
}
 
public GMX_PlayerLoaded(const id, GripJSONValue:data) {
	// TODO: Find punishments for player

	set_task_ex(1.0, "TaskCheckPlayer", id + 100, .flags = SetTask_Repeat);
}

public TaskCheckPlayer(id) {
	id -= 100;

	if (!is_user_connected(id)) {
		return;
	}

	new now = get_systime();
	for (new i = 0, n = ArraySize(PlayersPunishment[id]); i < n; i++) {
		ArrayGetArray(PlayersPunishment[id], i, Punishment, sizeof Punishment);
		if (Punishment[PunishmentStatus] == APS_PunishmentStatusActive && Punishment[PunishmentExpired] <= now) {
			// TODO: unpunish player
		}
	}
}

RegisterCoreForwards() {
	g_Forwards[FW_PUNISH_PLAYER_PRE] = CreateMultiForward("APS_PlayerPunishing", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_PUNISH_PLAYER_POST] = CreateMultiForward("APS_PlayerPunished", ET_IGNORE, FP_CELL, FP_CELL);
	// g_Forwards[FW_CHECK_PLAYER_PRE] = CreateMultiForward("APS_CheckPlayerPre", ET_CONTINUE, FP_CELL);
	// g_Forwards[FW_CHECK_PLAYER_POST] = CreateMultiForward("APS_CheckPlayerPost", ET_IGNORE, FP_CELL, FP_CELL);
	// g_Forwards[FW_UNPUNISH_PLAYER_PRE] = CreateMultiForward("APS_UnPunishPlayerPre", ET_CONTINUE, FP_CELL, FP_CELL);
	// g_Forwards[FW_UNPUNISH_PLAYER_POST] = CreateMultiForward("APS_UnPunishPlayerPost", ET_IGNORE);

	//forward PS_PunishPlayerPre(const id, const type);
	//forward PS_PunishPlayerPost(const id, const type);
	//forward PS_CheckPlayerPre(const id);
	//forward PS_CheckPlayerPost(const id, const bool:is_punished);
	//forward PS_UnPunishPlayerPre(const id, const type);
	//forward PS_UnPunishPlayerPost();    
}

public plugin_natives() {
	register_native("APS_PunishPlayer", "NativePunishPlayer", 0);
	//register_native("APS_UnPunishPlayer", "NativeUnPunishPlayer", 0);
	//register_native("APS_CheckPlayer", "NativeCheckPlayer", 0);
	//register_native("APS_GetPunishmentExpired", "NativeGetPunishmentExpired", 0);
	//register_native("APS_SetPunishmentExpired", "NativeSetPunishmentExpired", 0);
	//register_native("APS_GetPunishmentReason", "NativeGetPunishmentReason", 0);
	//register_native("APS_SetPunishmentReason", "NativeSetPunishmentReason", 0);
	//register_native("APS_GetPunishmentDetails", "NativeGetPunishmentDetails", 0);
	//register_native("APS_SetPunishmentComment", "NativeSetPunishmentComment", 0);  
}


public NativePunishPlayer(plugin, argc) {
	enum { arg_player = 1, arg_type, arg_expired, arg_reason, arg_details, arg_punisher_id, arg_extra };

	CHECK_NATIVE_ARGS_NUM(argc, 4)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player)

	new type[32];
	get_string(arg_type, type, charsmax(type));
	new expired = get_param(arg_expired);
	new reason[32], details[32]; // TODO: max length must be in include as stock const
	get_string(arg_reason, reason, charsmax(reason));
	get_string(arg_details, details, charsmax(details));
	new punisher_id = get_param(arg_punisher_id);
	new extra = get_param(arg_extra);

	new GripJSONValue:request = grip_json_init_object();
	grip_json_object_set_string(request, "type", type);
	grip_json_object_set_number(request, "expired", expired);
	grip_json_object_set_string(request, "reason", reason);
	grip_json_object_set_string(request, "details", details);
	grip_json_object_set_number(request, "extra", extra);

	if (is_user_connected(punisher_id) && GMX_PlayerIsLoaded(punisher_id)) {
		grip_json_object_set_number(request, "punisher_type", _:APS_PunisherTypePlayer);
		grip_json_object_set_number(request, "id", GMX_PlayerGetPlayerId(punisher_id));
	} else {
		grip_json_object_set_number(request, "punisher_type", _:APS_PunisherTypeServer);
		grip_json_object_set_number(request, "punisher_id", 0);
	}

	if (GMX_PlayerIsLoaded(player)) {
		grip_json_object_set_number(request, "player_id", GMX_PlayerGetPlayerId(player));
		GMX_MakeRequest("punish", request, "OnPunished", get_user_userid(player));
	} else {
		new steamid[24], nick[32], ip[32];
		get_user_authid(player, steamid, charsmax(steamid));
		get_user_name(player, nick, charsmax(nick));
		get_user_ip(player, ip, charsmax(ip), 1);

		new emulator = has_reunion() ? REU_GetProtocol(player) : 0;

		grip_json_object_set_number(request, "emulator", emulator);
		grip_json_object_set_string(request, "steamid", steamid);
		grip_json_object_set_string(request, "nick", nick);
		grip_json_object_set_string(request, "ip", ip);
		GMX_MakeRequest("punish/immediately", request, "OnPunished", get_user_userid(player));
	}

	return 1;
}

public OnPunished(const GmxResponseStatus:status, GripJSONValue:data, const userid) {
	if (status != GmxResponseStatusOk) {
		return;
	}
 
	new id = GMX_GetPlayerByUserID(userid);
	if (id == 0) {
		return;
	}

	if (grip_json_get_type(data) != GripJSONObject) {
		return;
	} 
}
 

/*
public NativeUnPunishPlayer(plugin, params) {
	enum {
		arg_index = 1,
		arg_type
	};

	new index = get_param(arg_index);
	new punish_type = get_param(arg_type);

	ExecuteForward(g_Forwards[FW_UNPUNISH_PLAYER_PRE]);


	ExecuteForward(g_Forwards[FW_UNPUNISH_PLAYER_POST]);
}

public NativeCheckPlayer(plugin, params) {
	enum { arg_index = 1 };

	new index = get_param(arg_index);

	ExecuteForward(g_Forwards[FW_CHECK_PLAYER_PRE]);


	ExecuteForward(g_Forwards[FW_CHECK_PLAYER_POST]);
}

public NativeGetPunishmentExpired(plugin, params) {

}

public NativeSetPunishmentExpired(plugin, params) {
   enum { arg_expired = 1 };

	new expired = get_param(arg_expired);
}

public NativeGetPunishmentReason(plugin, params) {
	enum {
		arg_reason = 1,
		arg_len 
	};

	new reason[MAX_REASON_LENGTH];

	set_string(arg_reason, reason, get_param(arg_len));

	return reason;
}

public NativeSetPunishmentReason(plugin, params) {
	// const comment[]
}

public NativeGetPunishmentDetails(plugin, params) {
	enum { arg_comment = 1 };
	
	new comment[MAX_COMMENT_LENGTH];

	set_string(arg_comment, comment, charsmax(comment));

	return comment;
}

public NativeSetPunishmentComment(plugin, params) {
	// const comment[]
}
*/
