#include <amxmodx>
#include <amxmisc>
#include <grip>
#include <aps>
#include <gmx_stocks>

#define CHECK_NATIVE_TYPE(%1,%2) \
	if (0 > %1 || %1 >= TypesNum) { \
		return %2; \
	}

#define CHECK_NATIVE_TYPE_ERROR(%1,%2) \
	if (0 > %1 || %1 >= TypesNum) { \
		log_error(AMX_ERR_NATIVE, "Invalid type %d", %1); \
		return %2; \
	}

enum {
	FWD_PlayerPunishing,
	FWD_PlayerPunished,
	FWD_PlayerAmnestying,
	FWD_PlayerAmnestied,
	FWD_PlayerChecking,
	FWD_PlayerChecked,

	FWD_LAST
}

new Forwards[FWD_LAST], FwdReturn;

new Array:Types, TypesNum;

enum _:PunishmentStruc {
	PunishmentID,
	PunishmentType,
	PunishmentExtra,
	PunishmentCreated,
	PunishmentTime,
	PunishmentExpired,
	PunishmentReason[APS_MAX_REASON_LENGTH],
	PunishmentDetails[APS_MAX_DETAILS_LENGTH],
	APS_PunisherType:PunishmentPunisherType,
	PunishmentPunisherID,
	APS_PunishmentStatus:PunishmentStatus
};

new Punishment[PunishmentStruc];

new Array:PlayersPunishment[MAX_PLAYERS + 1];
new PluginId;

public plugin_init() {
	PluginId = register_plugin("[APS] Core", APS_VERSION_STR, "GM-X Team");
	Types = ArrayCreate(APS_MAX_TYPE_LENGTH, 0);
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		PlayersPunishment[i] = ArrayCreate(PunishmentStruc, 0);
	}

	Forwards[FWD_PlayerPunishing] = CreateMultiForward("APS_PlayerPunishing", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerPunished] = CreateMultiForward("APS_PlayerPunished", ET_IGNORE, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerAmnestying] = CreateMultiForward("APS_PlayerAmnestying", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerAmnestied] = CreateMultiForward("APS_PlayerAmnestied", ET_IGNORE, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerChecking] = CreateMultiForward("APS_PlayerChecking", ET_STOP, FP_CELL);
	Forwards[FWD_PlayerChecked] = CreateMultiForward("APS_PlayerChecked", ET_IGNORE, FP_CELL);
}

public plugin_cfg() {
	checkAPIVersion();

	new fwdIniting = CreateMultiForward("APS_Initing", ET_IGNORE);
	new fwdInited = CreateMultiForward("APS_Inited", ET_IGNORE);

	ExecuteForward(fwdIniting, FwdReturn);
	TypesNum = ArraySize(Types);
	ExecuteForward(fwdInited, FwdReturn);

	DestroyForward(fwdIniting);
	DestroyForward(fwdInited);
}

public plugin_end() {
	ArrayDestroy(Types);
	for (new i = 1; i <= MAX_PLAYERS; i++) {
		ArrayDestroy(PlayersPunishment[i]);
	}

	for (new i = 0; i < sizeof Forwards; i++) {
		DestroyForward(Forwards[i]);
	}
}

public client_connect(id) {
	ArrayClear(PlayersPunishment[id]);
}

public client_disconnected(id) {
	remove_task(id);
}

public GMX_PlayerLoaded(const id, GripJSONValue:data) {
	ArrayClear(PlayersPunishment[id]);
	ExecuteForward(Forwards[FWD_PlayerChecking], FwdReturn, id);
	if (FwdReturn == PLUGIN_HANDLED) {
		return;
	}

	new GripJSONValue:punishments = grip_json_object_get_value(data, "punishments");
	if (punishments == Invalid_GripJSONValue) {
		return;
	}

	new bool:hasPunishments = false;
	for (new i = 0, n = grip_json_array_get_count(punishments), GripJSONValue:tmp; i < n; i++) {
		tmp = grip_json_array_get_value(punishments, i);
		if (grip_json_get_type(tmp) == GripJSONObject) {
			parsePunishment(tmp);
			ArrayPushArray(PlayersPunishment[id], Punishment, sizeof Punishment);
			ExecuteForward(Forwards[FWD_PlayerPunished], FwdReturn, id, Punishment[PunishmentType]);
			hasPunishments = true;
		}
		grip_destroy_json_value(tmp);
	}
	grip_destroy_json_value(punishments);

	ExecuteForward(Forwards[FWD_PlayerChecked], FwdReturn, id);
	if (hasPunishments) {
		set_task_ex(1.0, "TaskCheckPlayer", id + 100, .flags = SetTask_Repeat);
	} 
}

public OnPunished(const GmxResponseStatus:status, GripJSONValue:data, const userid) {
	if (status != GmxResponseStatusOk) {
		return;
	}

	new id = GMX_GetPlayerByUserID(userid);
	if (!id) {
		return;
	}

	if (grip_json_get_type(data) != GripJSONObject) {
		return;
	}

	new GripJSONValue:tmp = grip_json_object_get_value(data, "punishment");
	parsePunishment(tmp);
	grip_destroy_json_value(tmp);
	ArrayPushArray(PlayersPunishment[id], Punishment, sizeof Punishment);
	ExecuteForward(Forwards[FWD_PlayerPunished], FwdReturn, id, Punishment[PunishmentType]);

	if (!task_exists(id + 100)) {
		set_task_ex(1.0, "TaskCheckPlayer", id + 100, .flags = SetTask_Repeat);
	}
}

public OnAmnestied(const GmxResponseStatus:status, GripJSONValue:data, const userid) {
	if (status != GmxResponseStatusOk) {
		return;
	}

	new id = GMX_GetPlayerByUserID(userid);
	if (!id) {
		return;
	}

	if (grip_json_get_type(data) != GripJSONObject) {
		return;
	}

	new GripJSONValue:tmp = grip_json_object_get_value(data, "punishment");
	new punishmentID = grip_json_object_get_number(tmp, "id");
	grip_destroy_json_value(tmp);

	for (new i = 0, n = ArraySize(PlayersPunishment[id]); i < n; i++) {
		ArrayGetArray(PlayersPunishment[id], i, Punishment, sizeof Punishment);
		if (Punishment[PunishmentStatus] != APS_PunishmentStatusActive) {
			continue;
		}

		if (Punishment[PunishmentID] != punishmentID) {
			continue;
		}

		ExecuteForward(Forwards[FWD_PlayerAmnestying], FwdReturn, id, Punishment[PunishmentType]);
		if (FwdReturn != PLUGIN_HANDLED) {
			Punishment[PunishmentStatus] = APS_PunishmentStatusAmnestied;
			ArraySetArray(PlayersPunishment[id], i, Punishment, sizeof Punishment);
			ExecuteForward(Forwards[FWD_PlayerAmnestied], FwdReturn, id, Punishment[PunishmentType]);
		}
	}
}

public TaskCheckPlayer(id) {
	id -= 100;

	if (!is_user_connected(id)) {
		return;
	}

	new now = get_systime() + GMX_GetServerTimeDiff(), active = 0;
	for (new i = 0, n = ArraySize(PlayersPunishment[id]); i < n; i++) {
		ArrayGetArray(PlayersPunishment[id], i, Punishment, sizeof Punishment);
		if (Punishment[PunishmentStatus] != APS_PunishmentStatusActive) {
			continue;
		}
		if (Punishment[PunishmentExpired] > now) {
			active++;
			continue;
		}
		
		ExecuteForward(Forwards[FWD_PlayerAmnestying], FwdReturn, id, Punishment[PunishmentType]);
		if (FwdReturn != PLUGIN_HANDLED) {
			Punishment[PunishmentStatus] = APS_PunishmentStatusExpired
			ArraySetArray(PlayersPunishment[id], i, Punishment, sizeof Punishment);
			ExecuteForward(Forwards[FWD_PlayerAmnestied], FwdReturn, id, Punishment[PunishmentType]);
		} else {
			active++;
		}
	}

	if (active == 0) {
		remove_task(id + 100);
	}
}

bool:punishPlayer(const player) {
	ExecuteForward(Forwards[FWD_PlayerPunishing], FwdReturn, player, Punishment[PunishmentType]);
	if (FwdReturn == PLUGIN_HANDLED) {
		return false;
	}

	new GripJSONValue:request = grip_json_init_object();

	new type[APS_MAX_TYPE_LENGTH];
	ArrayGetString(Types, Punishment[PunishmentType], type, charsmax(type));
	grip_json_object_set_string(request, "type", type);
	if (Punishment[PunishmentExtra] == 0) {
		grip_json_object_set_null(request, "extra");
	} else {
		grip_json_object_set_number(request, "extra", Punishment[PunishmentExtra]);
	}
	grip_json_object_set_number(request, "time", Punishment[PunishmentTime]);
	grip_json_object_set_string(request, "reason", Punishment[PunishmentReason]);
	if (Punishment[PunishmentDetails][0] != EOS) {
		grip_json_object_set_string(request, "details", Punishment[PunishmentDetails]);
	} else {
		grip_json_object_set_null(request, "details");
	}

	if (Punishment[PunishmentPunisherID] > 0) {
		grip_json_object_set_number(request, "punisher_id", Punishment[PunishmentPunisherID]);
	}

	if (GMX_PlayerIsLoaded(player)) {
		grip_json_object_set_number(request, "player_id", GMX_PlayerGetPlayerId(player));
		GMX_MakeRequest("punish", request, "OnPunished", get_user_userid(player));
		grip_destroy_json_value(request);
	} else {
		new steamid[24], nick[32], ip[32];
		get_user_authid(player, steamid, charsmax(steamid));
		get_user_name(player, nick, charsmax(nick));
		get_user_ip(player, ip, charsmax(ip), 1);

		new emulator = 0;
		if (has_reunion()) {
			emulator = _:REU_GetAuthtype(player);
		}

		grip_json_object_set_number(request, "emulator", emulator);
		grip_json_object_set_string(request, "steamid", steamid);
		grip_json_object_set_string(request, "nick", nick);
		grip_json_object_set_string(request, "ip", ip);
		GMX_MakeRequest("punish/immediately", request, "OnPunished", get_user_userid(player));
		grip_destroy_json_value(request);
	}

	return true;
}

bool:amnestyPlayer(const player) {
	new GripJSONValue:request = grip_json_init_object();
	grip_json_object_set_number(request, "punishment_id", Punishment[PunishmentID]);
	GMX_MakeRequest("punish/amnesty", request, "OnAmnestied", get_user_userid(player));
	grip_destroy_json_value(request);
	return true;
}

parsePunishment(const GripJSONValue:punishment) {
	arrayset(Punishment, 0, sizeof Punishment);
	new GripJSONValue:tmp;

	Punishment[PunishmentID] = grip_json_object_get_number(punishment, "id");
	Punishment[PunishmentTime] = grip_json_object_get_number(punishment, "time");

	new type[32];
	grip_json_object_get_string(punishment, "type", type, charsmax(type));
	Punishment[PunishmentType] = ArrayFindString(Types, type);

	tmp = grip_json_object_get_value(punishment, "extra");
	Punishment[PunishmentExtra] = grip_json_get_type(tmp) != GripJSONNull ? grip_json_get_number(tmp) : 0;
	grip_destroy_json_value(tmp);

	Punishment[PunishmentCreated] = grip_json_object_get_number(punishment, "created_at");

	tmp = grip_json_object_get_value(punishment, "expired_at");
	Punishment[PunishmentExpired] = grip_json_get_type(tmp) != GripJSONNull ? grip_json_get_number(tmp) : 0;
	grip_destroy_json_value(tmp);

	tmp = grip_json_object_get_value(punishment, "punisher_id");
	if (grip_json_get_type(tmp) == GripJSONNumber) {
		Punishment[PunishmentPunisherType] = APS_PunisherTypePlayer;
		Punishment[PunishmentPunisherID] = grip_json_get_number(tmp);
		grip_destroy_json_value(tmp);
	} else {
		grip_destroy_json_value(tmp);
		tmp = grip_json_object_get_value(punishment, "punisher_user_id");
		if (grip_json_get_type(tmp) == GripJSONNumber) {
			Punishment[PunishmentPunisherType] = APS_PunisherTypeUser;
			Punishment[PunishmentPunisherID] = grip_json_get_number(tmp);
		} else {
			Punishment[PunishmentPunisherType] = APS_PunisherTypeServer;
			Punishment[PunishmentPunisherID] = 0;
		}
		grip_destroy_json_value(tmp);
	}

	tmp = grip_json_object_get_value(punishment, "reason");
	if (grip_json_get_type(tmp) == GripJSONObject) {
		grip_json_object_get_string(tmp, "title", Punishment[PunishmentReason], charsmax(Punishment[PunishmentReason]));
	}
	grip_destroy_json_value(tmp);

	tmp = grip_json_object_get_value(punishment, "details");
	if (grip_json_get_type(tmp) == GripJSONString) {
		grip_json_get_string(tmp, Punishment[PunishmentDetails], charsmax(Punishment[PunishmentDetails]));
	}
	grip_destroy_json_value(tmp);
}

public plugin_natives() {
	register_native("APS_RegisterType", "NativeRegisterType", 0);
	register_native("APS_IsValidType", "NativeIsValidType", 0);
	register_native("APS_GetTypesNum", "NativeGetTypesNum", 0);
	register_native("APS_GetTypeIndex", "NativeGetTypeIndex", 0);
	register_native("APS_GetTypeName", "NativeGetTypeName", 0);
	register_native("APS_PunishPlayer", "NativePunishPlayer", 0);
	register_native("APS_AmnestyPlayer", "NativeAmnestyPlayer", 0);
	register_native("APS_GetPlayerPunishment", "NativeGetPlayerPunishment", 0);
	register_native("APS_GetId", "NativeGetId", 0);
	register_native("APS_GetExtra", "NativeGetExtra", 0);
	register_native("APS_SetExtra", "NativeSetExtra", 0);
	register_native("APS_GetTime", "NativeGetTime", 0);
	register_native("APS_SetTime", "NativeSetTime", 0);
	register_native("APS_GetCreated", "NativeGetCreated", 0);
	register_native("APS_SetCreated", "NativeSetCreated", 0);
	register_native("APS_GetExpired", "NativeGetExpired", 0);
	register_native("APS_SetExpired", "NativeSetExpired", 0);
	register_native("APS_GetReason", "NativeGetReason", 0);
	register_native("APS_SetReason", "NativeSetReason", 0);
	register_native("APS_GetDetails", "NativeGetDetails", 0);
	register_native("APS_SetDetails", "NativeSetDetails", 0);
	register_native("APS_GetPunisherType", "NativeGetPunisherType", 0);
	register_native("APS_SetPunisherType", "NativeSetPunisherType", 0);
	register_native("APS_GetPunisherId", "NativeGetPunisherId", 0);
	register_native("APS_SetPunisherId", "NativeSetPunisherId", 0);
	//register_native("APS_CheckPlayer", "NativeCheckPlayer", 0);
}

public APS_Type:NativeRegisterType(const plugin, const argc) {
	enum { arg_type = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, APS_InvalidType)

	new type[APS_MAX_TYPE_LENGTH];
	get_string(arg_type, type, charsmax(type));
	return APS_Type:ArrayPushString(Types, type);
}

public bool:NativeIsValidType(const plugin, const argc) {
	enum { arg_type = 1 };
	if (argc < arg_type) {
		return false;
	}
	return bool:(0 <= get_param(arg_type) < TypesNum);
}

public NativeGetTypesNum(const plugin, const argc) {
	return TypesNum;
}

public APS_Type:NativeGetTypeIndex(const plugin, const argc) {
	enum { arg_type = 1 };

	CHECK_NATIVE_ARGS_NUM(argc, 1, APS_InvalidType)

	new type[APS_MAX_TYPE_LENGTH];
	get_string(arg_type, type, charsmax(type));
	return APS_Type:ArrayFindString(Types, type);
}

public NativeGetTypeName(const plugin, const argc) {
	enum { arg_type = 1, arg_value, arg_len };

	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)

	new typeIndex = get_param(arg_type);
	CHECK_NATIVE_TYPE_ERROR(typeIndex, 0)
	new type[APS_MAX_TYPE_LENGTH];
	ArrayGetString(Types, typeIndex, type, charsmax(type));
	return set_string(arg_value, type, get_param(arg_len));
}

public bool:NativePunishPlayer(const plugin, const argc) {
	enum { arg_player = 1, arg_type, arg_time, arg_reason, arg_details, arg_punisher_id, arg_extra };
	arrayset(Punishment, 0, sizeof Punishment);

	CHECK_NATIVE_ARGS_NUM(argc, 4, false)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, false)

	Punishment[PunishmentType] = get_param(arg_type);
	CHECK_NATIVE_TYPE_ERROR(Punishment[PunishmentType], false)

	Punishment[PunishmentTime] = get_param(arg_time);
	get_string(arg_reason, Punishment[PunishmentReason], charsmax(Punishment[PunishmentReason]));
	get_string(arg_details, Punishment[PunishmentDetails], charsmax(Punishment[PunishmentDetails]));
	new punisher = get_param(arg_punisher_id);
	if (punisher != 0 && is_user_connected(punisher) && GMX_PlayerIsLoaded(punisher)) {
		Punishment[PunishmentPunisherID] = GMX_PlayerGetPlayerId(punisher);
		Punishment[PunishmentPunisherType] = APS_PunisherTypePlayer;
	} else {
		Punishment[PunishmentPunisherID] = 0;
		Punishment[PunishmentPunisherType] = APS_PunisherTypeServer;
	}
	Punishment[PunishmentExtra] = get_param(arg_extra);

	return punishPlayer(player);
}

public bool:NativeAmnestyPlayer(const plugin, const argc) {
	enum { arg_player = 1, arg_type };

	CHECK_NATIVE_ARGS_NUM(argc, 2, false)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, false)

	new type = get_param(arg_type);
	CHECK_NATIVE_TYPE_ERROR(type, false)

	for (new i = 0, n = ArraySize(PlayersPunishment[player]); i < n; i++) {
		ArrayGetArray(PlayersPunishment[player], i, Punishment, sizeof Punishment);
		if (Punishment[PunishmentStatus] != APS_PunishmentStatusActive) {
			continue;
		}
		if (Punishment[PunishmentType] == type) {
			return amnestyPlayer(player);
		}
	}

	return false;
}

public bool:NativeGetPlayerPunishment(const plugin, const argc) {
	enum { arg_player = 1, arg_type };
	arrayset(Punishment, 0, sizeof Punishment);

	CHECK_NATIVE_ARGS_NUM(argc, 2, false)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, false)

	new type = get_param(arg_type);
	CHECK_NATIVE_TYPE_ERROR(type, false)

	for (new i = 0, n = ArraySize(PlayersPunishment[player]); i < n; i++) {
		ArrayGetArray(PlayersPunishment[player], i, Punishment, sizeof Punishment);
		if (Punishment[PunishmentStatus] != APS_PunishmentStatusActive) {
			continue;
		}
		if (Punishment[PunishmentType] == type) {
			return true;
		}
	}

	return false;
}

public NativeGetId(const plugin, const argc) {
	return Punishment[PunishmentID];
}

public NativeGetExtra(const plugin, const argc) {
	return Punishment[PunishmentExtra];
}

public NativeSetExtra(const plugin, const argc) {
	enum { arg_value = 1};
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	Punishment[PunishmentExtra] = get_param(arg_value);
	return 1;
}

public NativeGetTime(const plugin, const argc) {
	return Punishment[PunishmentTime];
}

public NativeSetTime(const plugin, const argc) {
	enum { arg_value = 1};
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	Punishment[PunishmentTime] = get_param(arg_value);
	return 1;
}

public NativeGetCreated(const plugin, const argc) {
	return Punishment[PunishmentCreated];
}

public NativeSetCreated(const plugin, const argc) {
	enum { arg_value = 1};
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	Punishment[PunishmentCreated] = get_param(arg_value);
	return 1;
}

public NativeGetExpired(const plugin, const argc) {
	return Punishment[PunishmentExpired];
}

public NativeSetExpired(const plugin, const argc) {
	enum { arg_value = 1};
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	Punishment[PunishmentExpired] = get_param(arg_value);
	return 1;
}

public NativeGetReason(const plugin, const argc) {
	enum { arg_value = 1, arg_len  };
	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	return set_string(arg_value, Punishment[PunishmentReason], get_param(arg_len));
}

public NativeSetReason(const plugin, const argc) {
	enum { arg_value = 1  };
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	return get_string(arg_value, Punishment[PunishmentReason], charsmax(Punishment[PunishmentReason]));
}

public NativeGetDetails(const plugin, const argc) {
	enum { arg_value = 1, arg_len  };
	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	return set_string(arg_value, Punishment[PunishmentDetails], get_param(arg_len));
}

public NativeSetDetails(const plugin, const argc) {
	enum { arg_value = 1  };
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	return get_string(arg_value, Punishment[PunishmentDetails], charsmax(Punishment[PunishmentDetails]));
}

public APS_PunisherType:NativeGetPunisherType(const plugin, const argc) {
	return Punishment[PunishmentPunisherType];
}

public NativeSetPunisherType(const plugin, const argc) {
	enum { arg_value = 1  };
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	Punishment[PunishmentPunisherType] = APS_PunisherType:get_param(arg_value);
	return 1;
}

public NativeGetPunisherId(const plugin, const argc) {
	return Punishment[PunishmentPunisherID];
}

public NativeSetPunisherId(const plugin, const argc) {
	enum { arg_value = 1  };
	CHECK_NATIVE_ARGS_NUM(argc, 1, 0)
	Punishment[PunishmentPunisherID] = get_param(arg_value);
	return 1;
}

checkAPIVersion() {
	for(new i, n = get_pluginsnum(), status[2], func; i < n; i++) {
		if(i == PluginId) {
			continue;
		}

		get_plugin(i, .status = status, .len5 = charsmax(status));

		//status debug || status running
		if(status[0] != 'd' && status[0] != 'r') {
			continue;
		}
	
		func = get_func_id("__aps_version_check", i);

		if(func == -1) {
			continue;
		}

		if(callfunc_begin_i(func, i) == 1) {
			callfunc_push_int(APS_MAJOR_VERSION);
			callfunc_push_int(APS_MINOR_VERSION);
			callfunc_end();
		}
	}
}
