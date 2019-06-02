#include <amxmodx>
#include <amxmisc>
#include <reapi>
#include <grip>
#include <gmx>
#include <gmx_player>
#include <aps>

#define CHECK_NATIVE_ARGS_NUM(%1,%2,%3) \
	if (%1 < %2) { \
		log_error(AMX_ERR_NATIVE, "Invalid num of arguments %d. Expected %d", %1, %2); \
		return %3; \
	}
 
#define CHECK_NATIVE_PLAYER(%1,%2) \
	if (!is_user_connected(%1)) { \
		log_error(AMX_ERR_NATIVE, "Invalid player %d", %1); \
		return %2; \
	}

#define CHECK_NATIVE_TYPE(%1,%2) \
	if (0 > %1 || %1 >= TypesNum) { \
		log_error(AMX_ERR_NATIVE, "Invalid type %d", %1); \
		return %2; \
	}

enum FWD {
	FWD_PlayerPunishing,
	FWD_PlayerPunished,
	FWD_PlayerChecking,
	FWD_PlayerChecked,
}

new Forwards[FWD];
new Return;

new Array:Types, TypesNum;

enum _:PunishmentStruc {
	PunishmentID,
	PunishmentType,
	PunishmentExpired,
	PunishmentReason[APS_MAX_TYPE_LENGTH],
	PunishmentDetails[APS_MAX_DETAILS_LENGTH],
	APS_PunisherType:PunishmentPunisherType,
	PunishmentPunisherID,
	APS_PunishmentStatus:PunishmentStatus
};
 
new Punishment[PunishmentStruc];
 
new Array:PlayersPunishment[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Core", "0.0.1b", "GM-X Team");

	Types = ArrayCreate(APS_MAX_TYPE_LENGTH, 0);
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		PlayersPunishment[i] = ArrayCreate(PunishmentStruc, 0);
	}

	Forwards[FWD_PlayerPunishing] = CreateMultiForward("APS_PlayerPunishing", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerPunished] = CreateMultiForward("APS_PlayerPunished", ET_IGNORE, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerChecking] = CreateMultiForward("APS_PlayerChecking", ET_STOP, FP_CELL);
	Forwards[FWD_PlayerChecked] = CreateMultiForward("APS_PlayerChecked", ET_IGNORE, FP_CELL);
}

public plugin_cfg() {
	new fwdIniting = CreateMultiForward("APS_Initing", ET_STOP);
	new fwdInited = CreateMultiForward("APP_Inited", ET_IGNORE);

	ExecuteForward(fwdIniting, Return);
	TypesNum = ArraySize(Types);
	ExecuteForward(fwdInited, Return);

	DestroyForward(fwdIniting);
	DestroyForward(fwdInited);
}

public plugin_end() {
	ArrayDestroy(Types);
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		ArrayDestroy(PlayersPunishment[i]);
	}
	DestroyForward(Forwards[FWD_PlayerPunishing]);
	DestroyForward(Forwards[FWD_PlayerPunished]);
	DestroyForward(Forwards[FWD_PlayerChecking]);
	DestroyForward(Forwards[FWD_PlayerChecked]);
}

public GMX_PlayerLoading(const id) {
	ArrayClear(PlayersPunishment[id]);
}
 
public GMX_PlayerLoaded(const id, GripJSONValue:data) {
	ExecuteForward(Forwards[FWD_PlayerChecking], Return, id);
	if (Return == PLUGIN_HANDLED) {
		return;
	}
	// TODO: Find punishments for player
	server_print("^t PARSE PUNISHMENT");
	new GripJSONValue:punishments = grip_json_object_get_value(data, "punishments");
	if (punishments != Invalid_GripJSONValue) {
		return;
	}
	for (new i = 0, n = grip_json_array_get_count(punishments), GripJSONValue:tmp; i < n; i++) {
		tmp = grip_json_array_get_value(data, i);
		if (grip_json_get_type(tmp) == GripJSONObject) {
			
			parsePunishment(tmp);
		}
		grip_destroy_json_value(tmp);
	}
	grip_destroy_json_value(punishments);

	ExecuteForward(Forwards[FWD_PlayerChecked], Return, id);
	// set_task_ex(1.0, "TaskCheckPlayer", id + 100, .flags = SetTask_Repeat);
}

parsePunishment(const GripJSONValue:punishment) {
	arrayset(Punishment, 0, sizeof Punishment);
	new GripJSONValue:tmp;

	Punishment[PunishmentID] = grip_json_object_get_number(punishment, "id");

	new type[32];
	grip_json_object_get_string(punishment, "type", type, charsmax(type));
	Punishment[PunishmentReason] = ArrayFindString(Types, type);

	tmp = grip_json_object_get_value(punishment, "expired_at");
	Punishment[PunishmentExpired] = grip_json_get_type(tmp) != GripJSONNull ? grip_json_get_number(tmp) : 0;
	grip_destroy_json_value(tmp);

	tmp = grip_json_object_get_value(punishment, "reason");
	if (grip_json_get_type(tmp) != GripJSONObject) {
		grip_json_get_string(tmp, Punishment[PunishmentReason], charsmax(Punishment[PunishmentReason]));
	}
	grip_destroy_json_value(tmp);

	tmp = grip_json_object_get_value(punishment, "details");
	if (grip_json_get_type(tmp) != GripJSONNull) {
		grip_json_get_string(tmp, Punishment[PunishmentDetails], charsmax(Punishment[PunishmentDetails]));
	}
	grip_destroy_json_value(tmp);


	server_print("^t PARSED PUNISHMENT %d", Punishment[PunishmentID]);
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

public plugin_natives() {
	register_native("APS_RegisterType", "NativeRegisterType", 0);
	register_native("APS_GetTypeIndex", "NativeGetTypeIndex", 0);
	register_native("APS_GetTypeName", "NativeGetTypeName", 0);
	register_native("APS_PunishPlayer", "NativePunishPlayer", 0);
	register_native("APS_GetExpired", "NativeGetExpired", 0);
	register_native("APS_SetExpired", "NativeSetExpired", 0);
	register_native("APS_GetReason", "NativeGetReason", 0);
	register_native("APS_SetReason", "NativeSetReason", 0);
	register_native("APS_GetDetails", "NativeGetDetails", 0);
	register_native("APS_SetDetails", "NativeSetDetails", 0);
	//register_native("APS_UnPunishPlayer", "NativeUnPunishPlayer", 0);
	//register_native("APS_CheckPlayer", "NativeCheckPlayer", 0);
}

public NativeRegisterType(plugin, argc) {
	enum { arg_type = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, -1)

	new type[APS_MAX_TYPE_LENGTH];
	get_string(arg_type, type, charsmax(type));
	return ArrayPushString(Types, type);
}

public NativeGetTypeIndex(plugin, argc) {
	enum { arg_type = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, -1)

	new type[APS_MAX_TYPE_LENGTH];
	get_string(arg_type, type, charsmax(type));
	return ArrayFindString(Types, type);
}

public NativeGetTypeName(plugin, argc) {
	enum { arg_type = 1, arg_value, arg_len };

	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)

	new typeIndex = get_param(arg_type);
	CHECK_NATIVE_TYPE(typeIndex, 0)
	new type[APS_MAX_TYPE_LENGTH];
	ArrayGetString(Types, typeIndex, type, charsmax(type));
	set_string(arg_value, type, get_param(arg_len));
	return 1;
}

public NativePunishPlayer(plugin, argc) {
	enum { arg_player = 1, arg_type, arg_expired, arg_reason, arg_details, arg_punisher_id };
	arrayset(Punishment, 0, sizeof Punishment);

	CHECK_NATIVE_ARGS_NUM(argc, 4, 0)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	Punishment[PunishmentType] = get_param(arg_type)
	CHECK_NATIVE_TYPE(Punishment[PunishmentType], 0)

	Punishment[PunishmentExpired] = get_param(arg_expired);
	get_string(arg_reason, Punishment[PunishmentReason], charsmax(Punishment[PunishmentReason]));
	get_string(arg_details, Punishment[PunishmentDetails], charsmax(Punishment[PunishmentDetails]));
	Punishment[PunishmentPunisherID] = get_param(arg_punisher_id);
	if (Punishment[PunishmentPunisherID] != 0 && is_user_connected(Punishment[PunishmentPunisherID]) && GMX_PlayerIsLoaded(Punishment[PunishmentPunisherID])) {
		Punishment[PunishmentPunisherType] = APS_PunisherTypePlayer;
	} else {
		Punishment[PunishmentPunisherID] = 0;
		Punishment[PunishmentPunisherType] = APS_PunisherTypeServer;
	}

	ExecuteForward(Forwards[FWD_PlayerPunishing], Return, player, Punishment[PunishmentType]);
	if (Return == PLUGIN_HANDLED) {
		return 0;
	}

	new GripJSONValue:request = grip_json_init_object();

	new type[APS_MAX_TYPE_LENGTH];
	ArrayGetString(Types, Punishment[PunishmentType], type, charsmax(type));
	grip_json_object_set_string(request, "type", type);
	grip_json_object_set_number(request, "expired", Punishment[PunishmentExpired]);
	grip_json_object_set_string(request, "reason", Punishment[PunishmentReason]);
	if (Punishment[PunishmentDetails][0] != EOS) {
		grip_json_object_set_string(request, "details", Punishment[PunishmentDetails]);
	} else {
		grip_json_object_set_null(request, "details");
	}
	grip_json_object_set_number(request, "punisher_id", Punishment[PunishmentPunisherID]);

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

	ExecuteForward(Forwards[FWD_PlayerPunished], Return, id, Punishment[PunishmentType]);
}

public NativeGetExpired(plugin, argc) {
	return Punishment[PunishmentExpired];
}

public NativeSetExpired(plugin, argc) {
	enum { arg_value = 1};
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	Punishment[PunishmentExpired] = get_param(arg_value);
	return 1;
}

public NativeGetReason(plugin, argc) {
	enum { arg_value = 1, arg_len  };
	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	return set_string(arg_value, Punishment[PunishmentReason], get_param(arg_len));
}

public NativeSetReason(plugin, argc) {
	enum { arg_value = 1  };
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	get_string(arg_value, Punishment[PunishmentReason], charsmax(Punishment[PunishmentReason]));
	return 1;
}

public NativeGetDetails(plugin, argc) {
	enum { arg_value = 1, arg_len  };
	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	return set_string(arg_value, Punishment[PunishmentDetails], get_param(arg_len));
}

public NativeSetDetails(plugin, argc) {
	enum { arg_value = 1  };
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	get_string(arg_value, Punishment[PunishmentDetails], charsmax(Punishment[PunishmentDetails]));
	return 1;
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
*/
