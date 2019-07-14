#pragma semicolon 1

#include <amxmodx>
#include <reapi>
#include <grip>
#include <gmx>
#include <aps_mixed>

#define clear_type() arrayset(Type, 0 , sizeof Type)
#define clear_reason() arrayset(Reason, 0 , sizeof Reason)
#define get_type(%1) clear_type(); \
	ArrayGetArray(Types, %1, Type, sizeof Type)
#define get_reason(%1) clear_type(); \
	ArrayGetArray(Reasons, %1, Reason, sizeof Reason)

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

const MAX_TYPE_TITLE_LENGTH = 64;
const MAX_REASON_TITLE_LENGTH = 64;

#define MENU_TAB "^t^t"
#define DEBUG
// #define HIDE_ME_IN_MENU

new TeamNames[][] = {
	"SPEC",
	"TT",
	"CT",
	"SPEC"
};

enum _:type_s {
	TypeHandler,
	bool:TypeReason,
	bool:TypeTime,
	TypeTitle[MAX_TYPE_TITLE_LENGTH]
};

enum _:reason_s {
	ReasonTime,
	ReasonTitle[MAX_REASON_TITLE_LENGTH]
};

enum _:player_menus_s {
	PlayerMenuName[MAX_NAME_LENGTH],
	PlayerMenuTarget,
	PlayerMenuTargetIndex,
	PlayerMenuPage,
	PlayerMenuType,
	PlayerMenuReason,
	PlayerMenuTime,
	PlayerMenuExtra,
	PlayerMenuNum,
	PlayerMenuList[MAX_PLAYERS],
	PlayerMenuIds[MAX_PLAYERS],
};

new FwReturn;
new Array:Types, TypesNum, Type[type_s];
new Array:Reasons, ReasonsNum, Reason[reason_s];
new Array:Times, TimesNum;
new PlayersMenu[MAX_PLAYERS + 1][player_menus_s];

public plugin_init() {
	register_plugin("[APS] Players Menu", "0.1.0", "GM-X Team");

	register_dictionary("common.txt");

	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "CBasePlayer_SetClientUserInfoName_Post", true);

	register_clcmd("aps_plmenu", "CmdPlayersMenu");

	register_menucmd(register_menuid("APS_PLAYERS_MENU"), 1023, "HandlePlayersMenu");
	register_menucmd(register_menuid("APS_TYPES_MENU"), 1023, "HandleTypesMenu");
	register_menucmd(register_menuid("APS_REASONS_MENU"), 1023, "HandleReasonsMenu");
	register_menucmd(register_menuid("APS_TIMES_MENU"), 1023, "HandleTimesMenu");
	register_menucmd(register_menuid("APS_CONFIRM_MENU"), 1023, "HandleConfirmMenu");

	Types = ArrayCreate(type_s, 0);
	Reasons = ArrayCreate(reason_s, 0);
	Times = ArrayCreate(1, 0);
}

public plugin_cfg() {
	ArrayPushCell(Times, 60);
	ArrayPushCell(Times, 120);
	TimesNum = ArraySize(Times);
}

public plugin_end() {
	ArrayDestroy(Types);
	ArrayDestroy(Reasons);
	ArrayDestroy(Times);
}

public GMX_Init() {
	// TODO: Cache reasons
	GMX_MakeRequest("punish/reasons", Invalid_GripJSONValue, "OnReasonsResponse");
}

public OnReasonsResponse(const GmxResponseStatus:status, const GripJSONValue:data, const userid) {
	if (status != GmxResponseStatusOk) {
		return;
	}

	new GripJSONValue:reasons = grip_json_object_get_value(data, "reasons");
	for (new i = 0, n = grip_json_array_get_count(reasons), GripJSONValue:element, GripJSONValue:time; i < n; i++) {
		element = grip_json_array_get_value(reasons, i);
		if (grip_json_get_type(element) == GripJSONObject) {
			clear_reason();

			time = grip_json_object_get_value(element, "time");
			Reason[ReasonTime] = grip_json_get_type(time) != GripJSONNull ? grip_json_get_number(time) : -1;
			grip_destroy_json_value(time);
			grip_json_object_get_string(element, "title", Reason[ReasonTitle], charsmax(Reason[ReasonTitle]));

			ArrayPushArray(Reasons, Reason, sizeof Reason);
		}
		grip_destroy_json_value(element);
	}
	grip_destroy_json_value(reasons);

	ReasonsNum = ArraySize(Reasons);
}

public client_putinserver(id) {
	get_user_name(id, PlayersMenu[id][PlayerMenuName], MAX_NAME_LENGTH - 1);
}

public CBasePlayer_SetClientUserInfoName_Post(const id, const infobuffer[], const name[]) {
	if (strcmp(name, PlayersMenu[id][PlayerMenuName]) != 0) {
		copy(PlayersMenu[id][PlayerMenuName], MAX_NAME_LENGTH - 1, name);
	}
}

public CmdPlayersMenu(const id) {
	displayMenu(id);
	return PLUGIN_HANDLED;
}

public APS_PlMenu_PushType_Handler(const title[], const handler, const bool:reason, const bool:time) {
	clear_type();

	copy(Type[TypeTitle], charsmax(Type[TypeTitle]), title);
	Type[TypeHandler] = handler;
	Type[TypeReason] = reason;
	Type[TypeTime] = time;
	new ret = ArrayPushArray(Types, Type, sizeof Type);
	TypesNum = ArraySize(Types);

	return ret;
}

displayMenu(const id) {
	clearPlayerMenu(id);
	findPlayersForMenu(id, TEAM_TERRORIST);
	findPlayersForMenu(id, TEAM_CT);
	findPlayersForMenu(id, TEAM_SPECTATOR);
	if (PlayersMenu[id][PlayerMenuNum] > 0) {
		showPlayersMenu(id);
	}
}

showPlayersMenu(const id, const page = 0) {
	if (page < 0) {
		return;
	}

	new start, end;
	PlayersMenu[id][PlayerMenuPage] = getMenuPage(page, PlayersMenu[id][PlayerMenuNum], 8, start, end);
	new pages = getMenuPagesNum(PlayersMenu[id][PlayerMenuNum], 8);
	new bool:firstPage = bool:(PlayersMenu[id][PlayerMenuPage] == 0);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_PLMENU_TITLE", PlayersMenu[id][PlayerMenuPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, player, team, item; i < end; i++) {
		player = PlayersMenu[id][PlayerMenuList][i];

		if (!is_user_connected(player)) {
			continue;
		}

		team = get_member(player, m_iTeam);

		if (id == player) {
			keys |= (1 << item);
			len += formatex(menu[len], charsmax(menu) - len, "%s\r[%d] \y[%s] ", MENU_TAB, ++item, TeamNames[team]);
		} else if (is_user_hltv(player)) {
			len += formatex(menu[len], charsmax(menu) - len, "%s\d[%d] [HLTV] ", MENU_TAB, ++item);
		} else if (is_user_bot(player)) {
#if defined DEBUG
			keys |= (1 << item);
#endif
			len += formatex(menu[len], charsmax(menu) - len, "%s\d[%d] [%s] [BOT] ", MENU_TAB, ++item, TeamNames[team]);
		} else {
//             flags = get_user_flags(player);
//             if ((flags & ADMIN_IMMUNITY) && !superFlag) {
//                 len += formatex(menu[len], charsmax(menu) - len, "%s\d[%d] [%s] [IMMUNITY] ", MENU_TAB, ++item, team);
//             } else {
				keys |= (1 << item);
				len += formatex(menu[len], charsmax(menu) - len, "%s\r[%d] \y[%s] ", MENU_TAB, ++item, TeamNames[team]);
//             }
		}

		len += formatex(menu[len], charsmax(menu) - len, " \w%s^n", PlayersMenu[player][PlayerMenuName]);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start), '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < PlayersMenu[id][PlayerMenuNum]) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, "^n%s\r[9] \w%l^n%s\r[0] \w%l", MENU_TAB, "MORE", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n^n%s\r[0] \w%l", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	}

	show_menu(id, keys, menu, -1, "APS_PLAYERS_MENU");
}

showTypesMenu(const id, const page = 0) {
	if (page < 0) {
		displayMenu(id);
		return;
	}

	SetGlobalTransTarget(id);

	new start, end;
	PlayersMenu[id][PlayerMenuPage] = getMenuPage(page, TypesNum, 8, start, end);
	new pages = getMenuPagesNum(TypesNum, 8);
	new bool:firstPage = bool:(PlayersMenu[id][PlayerMenuPage] == 0);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_MENU_PLAYERS_TITLE", PlayersMenu[id][PlayerMenuPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, item; i < end; i++) {
		get_type(i);
		keys |= (1 << item);
		len += formatex(menu[len], charsmax(menu) - len, "%s\r[%d] \w%s^n", MENU_TAB, ++item, Type[TypeTitle]);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start), '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < PlayersMenu[id][PlayerMenuNum]) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, "^n%s\r[9] \w%l^n%s\r[0] \w%l", MENU_TAB, "MORE", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n^n%s\r[0] \w%l", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	}

	show_menu(id, keys, menu, -1, "APS_TYPES_MENU");
}

showReasonsMenu(const id, const page = 0) {
	if (page < 0) {
		showTypesMenu(id);
		return;
	}

	SetGlobalTransTarget(id);

	new start, end;
	PlayersMenu[id][PlayerMenuPage] = getMenuPage(page, ReasonsNum, 8, start, end);
	new pages = getMenuPagesNum(ReasonsNum, 8);
	new bool:firstPage = bool:(PlayersMenu[id][PlayerMenuPage] == 0);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_MENU_REASONS_TITLE", PlayersMenu[id][PlayerMenuPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, item; i < end; i++) {
		get_reason(i);
		keys |= (1 << item);
		len += formatex(menu[len], charsmax(menu) - len, "%s\r[%d] \w%s^n", MENU_TAB, ++item, Reason[ReasonTitle]);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start), '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < ReasonsNum) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, "^n%s\r[9] \w%l^n%s\r[0] \w%l", MENU_TAB, "MORE", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n^n%s\r[0] \w%l", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	}

	show_menu(id, keys, menu, -1, "APS_REASONS_MENU");
}

showTimesMenu(const id, const page = 0) {
	if (page < 0) {
		showReasonsMenu(id);
		return;
	}

	SetGlobalTransTarget(id);

	new start, end;
	PlayersMenu[id][PlayerMenuPage] = getMenuPage(page, TimesNum, 8, start, end);
	new pages = getMenuPagesNum(TimesNum, 8);
	new bool:firstPage = bool:(PlayersMenu[id][PlayerMenuPage] == 0);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_MENU_TIMES_TITLE", PlayersMenu[id][PlayerMenuPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, item, time; i < end; i++) {
		time = ArrayGetCell(Times, i);
		keys |= (1 << item);
		len += formatex(menu[len], charsmax(menu) - len, "%s\r[%d] \w%d^n", MENU_TAB, ++item, time);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start), '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < TimesNum) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, "^n%s\r[9] \w%l^n%s\r[0] \w%l", MENU_TAB, "MORE", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n^n%s\r[0] \w%l", MENU_TAB, (firstPage ? "EXIT" : "BACK"));
	}

	show_menu(id, keys, menu, -1, "APS_TIMES_MENU");
}

showConfirmMenu(const id) {
	SetGlobalTransTarget(id);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^n^n", MENU_TAB, "APS_MENU_CONFIRM_TITLE");

	get_type(PlayersMenu[id][PlayerMenuType]);
	len += formatex(menu[len], charsmax(menu) - len, "%s\y%l\w: \y%s^n", MENU_TAB, "APS_MENU_TYPE", Type[TypeTitle]);
	if (PlayersMenu[id][PlayerMenuReason] >= 0) {
		get_reason(PlayersMenu[id][PlayerMenuReason]);
		len += formatex(menu[len], charsmax(menu) - len, "%s\y%l\w: \y%s^n", MENU_TAB, "APS_MENU_REASON", Reason[ReasonTitle]);
	}

	new keys = MENU_KEY_1 | MENU_KEY_2;
	len += formatex(menu[len], charsmax(menu) - len, "^n^n%s\r[1] \w%l^n%s\r[2] \w%l", MENU_TAB, "YES", MENU_TAB, "NO");

	show_menu(id, keys, menu, -1, "APS_CONFIRM_MENU");
}

public HandlePlayersMenu(const id, const key) {
	switch (key) {
		case 8: {
			showPlayersMenu(id, ++PlayersMenu[id][PlayerMenuPage]);
		}

		case 9: {
			showPlayersMenu(id, --PlayersMenu[id][PlayerMenuPage]);
		}

		default: {
			new index = (PlayersMenu[id][PlayerMenuPage] * 8) + key;
			new player = PlayersMenu[id][PlayerMenuList][index];
			if (is_user_connected(player) && get_user_userid(player) == PlayersMenu[id][PlayerMenuIds][index]) {
				PlayersMenu[id][PlayerMenuTarget] = player;
				PlayersMenu[id][PlayerMenuTargetIndex] = get_user_userid(player);
				showTypesMenu(id);
			}
		}
	}
}

public HandleTypesMenu(const id, const key) {
	if (!isTargetValid(id)) {
		displayMenu(id);
		return;
	}

	switch (key) {
		case 8: {
			showTypesMenu(id, ++PlayersMenu[id][PlayerMenuPage]);
		}

		case 9: {
			showTypesMenu(id, --PlayersMenu[id][PlayerMenuPage]);
		}

		default: {
			PlayersMenu[id][PlayerMenuType] = (PlayersMenu[id][PlayerMenuPage] * 8) + key;
			makeAction(id);
		}
	}
}

public HandleReasonsMenu(const id, const key) {
	if (!isTargetValid(id)) {
		displayMenu(id);
		return;
	}

	switch (key) {
		case 8: {
			showReasonsMenu(id, ++PlayersMenu[id][PlayerMenuPage]);
		}

		case 9: {
			showReasonsMenu(id, --PlayersMenu[id][PlayerMenuPage]);
		}

		default: {
			PlayersMenu[id][PlayerMenuReason] = (PlayersMenu[id][PlayerMenuPage] * 8) + key;
			get_reason(PlayersMenu[id][PlayerMenuReason]);
			if (Reason[ReasonTime] >= 0) {
				PlayersMenu[id][PlayerMenuReason] = Reason[ReasonTime];
			}
			makeAction(id);
		}
	}
}

public HandleTimesMenu(const id, const key) {
	if (!isTargetValid(id)) {
		displayMenu(id);
		return;
	}

	switch (key) {
		case 8: {
			showTimesMenu(id, ++PlayersMenu[id][PlayerMenuPage]);
		}

		case 9: {
			showTimesMenu(id, --PlayersMenu[id][PlayerMenuPage]);
		}

		default: {
			PlayersMenu[id][PlayerMenuTime] = (PlayersMenu[id][PlayerMenuPage] * 8) + key;
			makeAction(id);
		}
	}
}

public HandleConfirmMenu(const id, const key) {
	if (!isTargetValid(id)) {
		displayMenu(id);
		return;
	}

	if (key != 0) {
		return;
	}

	if (key == 0) {
		new reason[MAX_REASON_TITLE_LENGTH];
		if (PlayersMenu[id][PlayerMenuReason] >= 0) {
			get_reason(PlayersMenu[id][PlayerMenuReason]);
			copy(reason, charsmax(reason), Reason[ReasonTitle]);
		}
		get_type(PlayersMenu[id][PlayerMenuType]);
		new time = PlayersMenu[id][PlayerMenuTime] != -1 ? ArrayGetCell(Times, PlayersMenu[id][PlayerMenuTime]) : 0;
		ExecuteForward(Type[TypeHandler], FwReturn, id, PlayersMenu[id][PlayerMenuTarget], reason, time);
	}
}

makeAction(const id) {
	get_type(PlayersMenu[id][PlayerMenuType]);
	if (canShowReason(id)) {
		showReasonsMenu(id);
	} else if (canShowTime(id)) {
		showTimesMenu(id);
	} else {
		showConfirmMenu(id);
	}
}

bool:canShowReason(const id) {
	if (!Type[TypeReason] || ReasonsNum == 0) {
		return false;
	}

	return bool:(PlayersMenu[id][PlayerMenuReason] == -1);
}

bool:canShowTime(const id) {
	if (!Type[TypeTime]) {
		return false;
	}

	return bool:(PlayersMenu[id][PlayerMenuTime] == -1);
}

findPlayersForMenu(const id, const TeamName:team) {
	new num = PlayersMenu[id][PlayerMenuNum];
	for (new player = 1; player <= MaxClients; player++) {
		if (!is_user_connected(player) || TeamName:get_member(player, m_iTeam) != team) {
			continue;
		}

#if defined HIDE_ME_IN_MENU
		if (id == i) {
			continue;
		}
#endif

		PlayersMenu[id][PlayerMenuList][num] = player;
		PlayersMenu[id][PlayerMenuIds][num] = get_user_userid(player);
		num++;
	}

	PlayersMenu[id][PlayerMenuNum] = num;
}

bool:isTargetValid(const id) {
	new player = PlayersMenu[id][PlayerMenuTarget];
	return bool:(player != 0 && is_user_connected(player) && get_user_userid(player) == PlayersMenu[id][PlayerMenuTargetIndex]);
}

clearPlayerMenu(const id) {
	PlayersMenu[id][PlayerMenuTarget] = 0;
	PlayersMenu[id][PlayerMenuTargetIndex] = 0;
	PlayersMenu[id][PlayerMenuPage] = 0;
	PlayersMenu[id][PlayerMenuNum] = 0;
	PlayersMenu[id][PlayerMenuType] = -1;
	PlayersMenu[id][PlayerMenuReason] = -1;
	PlayersMenu[id][PlayerMenuTime] = -1;
	PlayersMenu[id][PlayerMenuExtra] = 0;
}

getMenuPage(cur_page, elements_num, per_page, &start, &end) {
	new max = min(cur_page * per_page, elements_num);
	start = max - (max % 8);
	end = min(start + per_page, elements_num);
	return start / per_page;
}

getMenuPagesNum(elements_num, per_page) {
	return (elements_num - 1) / per_page;
}

// NATIVES
// public plugin_natives() {
	// register_native("APS_PlMenu_PushItem", "NativePushItem", 0);
// }

// public NativePushItem(plugin, argc) {
// 	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
// 	enum { arg_title = 1, arg_func, arg_reason, arg_time };

// 	clear_type();

// 	Type[TypePluginID] = plugin;

// 	get_string(arg_title, Type[TypeTitle], charsmax(Type[TypeTitle]));

// 	new func[64];
// 	get_string(arg_func, func, charsmax(func));
// 	if (func[0] == EOS) {
// 		log_error(AMX_ERR_NATIVE, "Could not find function %s", func);
// 		return 0;
// 	}

// 	Type[TypeFuncID] = get_func_id(func, plugin);
// 	if (Type[TypeFuncID] == -1) {
// 		log_error(AMX_ERR_NATIVE, "Could not find function %s", func);
// 		return -1;
// 	}

// 	if (argc >= arg_reason) {
// 		Type[TypeReason] = bool:get_param(arg_reason);
// 	} else {
// 		Type[TypeReason] = false;
// 	}

// 	if (argc >= arg_time) {
// 		Type[TypeTime] = bool:get_param(arg_time);
// 	} else {
// 		Type[TypeTime] = false;
// 	}

// 	ArrayPushArray(Types, Type, sizeof Type);
// 	TypesNum = ArraySize(Types);
// 	return 1;
// }
