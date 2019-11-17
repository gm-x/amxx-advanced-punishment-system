#pragma semicolon 1

#define MENU_TAB "^t^t"
// #define HIDE_ME_IN_MENU

#include <amxmodx>
#include <reapi>
#include <grip>
#include <gmx>
#include <aps>
#include <aps_time>

#define ACTIVE_ITEM(%0) MENU_TAB + "\r%d. " + #%0
#define INACTIVE_ITEM(%0) MENU_TAB + "\d%d. " + #%0

#define destroy_handler(%1) if (Item[%1] > Handler_Invaild) DestroyForward(Item[%1])
#define clear_item() arrayset(Item, 0 , sizeof Item)
#define clear_reason() arrayset(Reason, 0 , sizeof Reason)
#define get_item(%1) clear_item(); \
	ArrayGetArray(Items, %1, Item, sizeof Item)
#define get_reason(%1) clear_reason(); \
	ArrayGetArray(Reasons, %1, Reason, sizeof Reason)

#define show_item_step(%1,%2,%3,%4) \
	if (Item[%2] == Handler_Default) { \
		%3(%1); \
		return; \
	} else if (Item[%2] != Handler_Invaild) { \
		callHandler(%1, %2); \
		return; \
	} else \
		Players[%1][PlayerStep]+=%4

const MAX_TYPE_TITLE_LENGTH = 64;
const MAX_REASON_TITLE_LENGTH = 64;

new TeamNames[][] = {
	"SPEC",
	"TT",
	"CT",
	"SPEC"
};

const Handler_Default = -2;
const Handler_Invaild = -1;

enum {
	Step_Item,
	Step_Reason,
	Step_Time,
	Step_Extra,
	Step_Confirm,
};

enum item_s {
	APS_Type:ItemType,
	ItemTitle[32],
	ItemHandler,
	ItemResonHandler,
	ItemTimeHandler,
	ItemExtraHandler,
	bool:ItemNeedConfirm
};

enum _:reason_s {
	ReasonTime,
	ReasonTitle[MAX_REASON_TITLE_LENGTH]
};

enum _:player_s {
	PlayerName[MAX_NAME_LENGTH],
	PlayerTarget,
	PlayerTargetIndex,
	PlayerTargetID,
	PlayerPage,
	PlayerStep,
	PlayerItem,
	PlayerReason,
	PlayerTime,
	PlayerExtra,
	PlayerNum,
	PlayerList[MAX_PLAYERS],
	PlayerIds[MAX_PLAYERS],
};

new FwReturn;
new Array:Items, Item[item_s];
new Array:Reasons, Reason[reason_s];
new Array:Times, TimesNum;
new Players[MAX_PLAYERS + 1][player_s];

public plugin_init() {
	register_plugin("[APS] Players Menu", APS_VERSION_STR, "GM-X Team");

	register_dictionary("aps_plmenu.txt");
	register_dictionary("common.txt");
	register_dictionary("aps_time.txt");

	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "CBasePlayer_SetClientUserInfoName_Post", true);

	register_clcmd("aps_plmenu", "CmdPlayersMenu");

	register_menucmd(register_menuid("APS_PLAYERS_MENU"), 1023, "HandlePlayersMenu");
	register_menucmd(register_menuid("APS_TYPES_MENU"), 1023, "HandleTypesMenu");
	register_menucmd(register_menuid("APS_REASONS_MENU"), 1023, "HandleReasonsMenu");
	register_menucmd(register_menuid("APS_TIMES_MENU"), 1023, "HandleTimesMenu");
	register_menucmd(register_menuid("APS_CONFIRM_MENU"), 1023, "HandleConfirmMenu");

	Items = ArrayCreate(item_s, 0);
	Reasons = ArrayCreate(reason_s, 0);
	Times = ArrayCreate(1, 0);

	hook_cvar_change(create_cvar(
		"aps_plmenu_times",
		"1i 1d 1w 1m 1y"
	), "HooCvarTimes");
}

public plugin_cfg() {
	new times[128];
	get_cvar_string("aps_plmenu_times", times, charsmax(times));
	parseTimes(times);


	new fwdInited = CreateMultiForward("APS_PlMenu_Inited", ET_IGNORE);
	ExecuteForward(fwdInited, FwReturn);
	DestroyForward(fwdInited);
}

public plugin_end() {
	for (new i = 0, n = ArraySize(Items); i < n; i++) {
		ArrayGetArray(Items, i, Item, sizeof Item);
		destroy_handler(ItemHandler);
		destroy_handler(ItemResonHandler);
		destroy_handler(ItemTimeHandler);
		destroy_handler(ItemExtraHandler);
	}

	ArrayDestroy(Reasons);
	ArrayDestroy(Times);
}

public HooCvarTimes(const pcvar, const oldValue[], const newValue[]) {
	parseTimes(newValue);
}

public APS_PlMenu_Main() {}

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
}

public client_putinserver(id) {
	get_user_name(id, Players[id][PlayerName], MAX_NAME_LENGTH - 1);
}

public CBasePlayer_SetClientUserInfoName_Post(const id, const infobuffer[], const name[]) {
	if (strcmp(name, Players[id][PlayerName]) != 0) {
		copy(Players[id][PlayerName], MAX_NAME_LENGTH - 1, name);
	}
}

public CmdPlayersMenu(const id) {
	displayMenu(id);
	return PLUGIN_HANDLED;
}

public APS_PlMenu_Add(const APS_Type:type, const title[], const handler, const resonHandler, const timeHandler, const extraHandler, const bool:needConfirm) {
	clear_item();
	if (!APS_IsValidType(type)) {
		return -1;
	}

	Item[ItemType] = type;
	copy(Item[ItemTitle], charsmax(Item[ItemTitle]), title);
	Item[ItemHandler] = handler != Handler_Invaild ? handler : Handler_Default;
	Item[ItemResonHandler] = resonHandler;
	Item[ItemTimeHandler] = timeHandler;
	Item[ItemExtraHandler] = extraHandler != Handler_Default ? extraHandler : Handler_Invaild;
	Item[ItemNeedConfirm] = needConfirm;
	return ArrayPushArray(Items, Item, sizeof Item);
}

public APS_PlMenu_NextStep(const id, const value) {
	if (!is_user_connected(id)) {
		return;
	}

	switch (Players[id][PlayerStep]) {
		case Step_Reason: {
			Players[id][PlayerReason] = value;
		}

		case Step_Time: {
			Players[id][PlayerTime] = value;
		}

		case Step_Extra: {
			Players[id][PlayerExtra] = value;
		}
	}

	nextStep(id);
}

public APS_PlMenu_PrevStep(const id) {
	if (!is_user_connected(id)) {
		return;
	}

	prevStep(id);
}

displayMenu(const id) {
	clearPlayer(id);
	findPlayersForMenu(id, TEAM_TERRORIST);
	findPlayersForMenu(id, TEAM_CT);
	findPlayersForMenu(id, TEAM_SPECTATOR);
	if (Players[id][PlayerNum] > 0) {
		showPlayersMenu(id);
	}
}

showPlayersMenu(const id, const page = 0) {
	if (page < 0) {
		return;
	}

	new start, end;
	Players[id][PlayerPage] = getMenuPage(page, Players[id][PlayerNum], 8, start, end);
	new pages = getMenuPagesNum(Players[id][PlayerNum], 8);
	new bool:firstPage = bool:(Players[id][PlayerPage] == 0);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_MENU_PLAYERS_TITLE", Players[id][PlayerPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, player, team, item; i < end; i++) {
		player = Players[id][PlayerList][i];

		if (!is_user_connected(player)) {
			continue;
		}

		team = get_member(player, m_iTeam);

		if (id == player) {
			keys |= (1 << item);
			len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\y[%s] ), ++item, TeamNames[team]);
		} else if (is_user_hltv(player)) {
			len += formatex(menu[len], charsmax(menu) - len, INACTIVE_ITEM([HLTV] ), ++item);
		} else if (is_user_bot(player)) {
			len += formatex(menu[len], charsmax(menu) - len, INACTIVE_ITEM([BOT] ), ++item, TeamNames[team]);
		} else {
			keys |= (1 << item);
			len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\y[%s] ), ++item, TeamNames[team]);
		}

		len += formatex(menu[len], charsmax(menu) - len, " \w%s^n", Players[player][PlayerName]);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start) + 1, '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < Players[id][PlayerNum]) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 9, "MORE");
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n");
	}

	len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 0, firstPage ? "EXIT" : "BACK");

	show_menu(id, keys, menu, -1, "APS_PLAYERS_MENU");
}

showItemsMenu(const id, const page = 0) {
	if (page < 0) {
		displayMenu(id);
		return;
	}

	SetGlobalTransTarget(id);

	new num = ArraySize(Items);

	new start, end;
	Players[id][PlayerPage] = getMenuPage(page, num, 8, start, end);
	new pages = getMenuPagesNum(num, 8);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_MENU_TYPES_TITLE", Players[id][PlayerPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, item; i < end; i++) {
		get_item(i);
		keys |= (1 << item);
		len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), ++item, Item[ItemTitle]);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start) + 1, '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < num) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 9, "MORE");
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n");
	}
	len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 0, "BACK");

	show_menu(id, keys, menu, -1, "APS_TYPES_MENU");
}

showReasonsMenu(const id, const page = 0) {
	if (page < 0) {
		prevStep(id);
		return;
	}

	SetGlobalTransTarget(id);

	new num = ArraySize(Reasons);

	new start, end;
	Players[id][PlayerPage] = getMenuPage(page, num, 8, start, end);
	new pages = getMenuPagesNum(num, 8);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_MENU_REASONS_TITLE", Players[id][PlayerPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, item; i < end; i++) {
		get_reason(i);
		keys |= (1 << item);
		len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%s^n), ++item, Reason[ReasonTitle]);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start) + 1, '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < num) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 9, "MORE");
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n");
	}

	len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 0, "BACK");

	show_menu(id, keys, menu, -1, "APS_REASONS_MENU");
}

showTimesMenu(const id, const page = 0) {
	if (page < 0) {
		prevStep(id);
		return;
	}

	SetGlobalTransTarget(id);

	new start, end;
	Players[id][PlayerPage] = getMenuPage(page, TimesNum, 8, start, end);
	new pages = getMenuPagesNum(TimesNum, 8);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "APS_MENU_TIMES_TITLE", Players[id][PlayerPage] + 1, pages + 1);

	new keys = MENU_KEY_0;
	for (new i = start, item, time, title[64]; i < end; i++) {
		time = ArrayGetCell(Times, i);
		keys |= (1 << item);
		aps_get_time_length(id, time, title, charsmax(title));
		len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%s^n), ++item, title);
	}

	new tmp[15];
	setc(tmp, 8 - (end - start) + 1, '^n');
	len += copy(menu[len], charsmax(menu) - len, tmp);

	if (end < TimesNum) {
		keys |= MENU_KEY_9;
		len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 9, "MORE");
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n");
	}

	len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 0, "BACK");

	show_menu(id, keys, menu, -1, "APS_TIMES_MENU");
}

showExtraMenu(const id) {
	#pragma unused id
}
// #pragma unused showExtraMenu

showConfirmMenu(const id) {
	SetGlobalTransTarget(id);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^n^n", MENU_TAB, "APS_MENU_CONFIRM_TITLE");

	get_item(Players[id][PlayerItem]);
	len += formatex(menu[len], charsmax(menu) - len, "%s\y%l\w: \y%l^n", MENU_TAB, "APS_MENU_TYPE", Item[ItemTitle]);
	if (Players[id][PlayerReason] >= 0) {
		get_reason(Players[id][PlayerReason]);
		len += formatex(menu[len], charsmax(menu) - len, "%s\y%l\w: \y%s^n", MENU_TAB, "APS_MENU_REASON", Reason[ReasonTitle]);
	}

	if (Players[id][PlayerTime] >= 0) {
		new time[64];
		aps_get_time_length(id, Players[id][PlayerTime], time, charsmax(time));
		len += formatex(menu[len], charsmax(menu) - len, "%s\y%l\w: \y%s^n", MENU_TAB, "APS_MENU_TIME", time);
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "%s\y%l\w: \r%l^n", MENU_TAB, "APS_MENU_TIME", "APS_MENU_FOREVER");
	}

	new keys = MENU_KEY_1 | MENU_KEY_2;
	len += formatex(menu[len], charsmax(menu) - len, "^n^n");
	len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 1, "YES");
	len += formatex(menu[len], charsmax(menu) - len, ACTIVE_ITEM(\w%l^n), 2, "NO");

	show_menu(id, keys, menu, -1, "APS_CONFIRM_MENU");
}

public HandlePlayersMenu(const id, const key) {
	switch (key) {
		case 8: {
			showPlayersMenu(id, ++Players[id][PlayerPage]);
		}

		case 9: {
			showPlayersMenu(id, --Players[id][PlayerPage]);
		}

		default: {
			new index = (Players[id][PlayerPage] * 8) + key;
			new player = Players[id][PlayerList][index];
			if (is_user_connected(player) && get_user_userid(player) == Players[id][PlayerIds][index]) {
				Players[id][PlayerTarget] = player;
				Players[id][PlayerTargetIndex] = get_user_userid(player);
				Players[id][PlayerTargetID] = GMX_PlayerGetPlayerId(player);
				showItemsMenu(id);
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
			showItemsMenu(id, ++Players[id][PlayerPage]);
		}

		case 9: {
			showItemsMenu(id, --Players[id][PlayerPage]);
		}

		default: {
			Players[id][PlayerItem] = (Players[id][PlayerPage] * 8) + key;
			nextStep(id);
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
			showReasonsMenu(id, ++Players[id][PlayerPage]);
		}

		case 9: {
			showReasonsMenu(id, --Players[id][PlayerPage]);
		}

		default: {
			Players[id][PlayerReason] = (Players[id][PlayerPage] * 8) + key;
			get_reason(Players[id][PlayerReason]);
			if (Reason[ReasonTime] >= 0) {
				Players[id][PlayerReason] = Reason[ReasonTime];
			}
			nextStep(id);
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
			showTimesMenu(id, ++Players[id][PlayerPage]);
		}

		case 9: {
			showTimesMenu(id, --Players[id][PlayerPage]);
		}

		default: {
			new item = (Players[id][PlayerPage] * 8) + key;
			if (0 <= item < TimesNum) {
				Players[id][PlayerTime] = ArrayGetCell(Times, item);
			}
			nextStep(id);
		}
	}
}

public HandleConfirmMenu(const id, const key) {
	if (!isTargetValid(id)) {
		displayMenu(id);
		return;
	}

	if (key != 0) {
		prevStep(id);
		return;
	}

	get_item(Players[id][PlayerItem]);
	makeAction(id);
}

nextStep(const id) {
	Players[id][PlayerStep]++;
	if (Players[id][PlayerStep] <= Step_Item) {
		showItemsMenu(id);
		return;
	}

	get_item(Players[id][PlayerItem]);
	if (Players[id][PlayerStep] == Step_Reason) {
		show_item_step(id, ItemResonHandler, showReasonsMenu, 1);
	}

	if (Players[id][PlayerStep] == Step_Time) {
		show_item_step(id, ItemTimeHandler, showTimesMenu, 1);
	}

	if (Players[id][PlayerStep] == Step_Extra) {
		show_item_step(id, ItemExtraHandler, showExtraMenu, 1);
	}

	if (Item[ItemNeedConfirm]) {
		showConfirmMenu(id);
	} else {
		makeAction(id);
	}
}

prevStep(const id) {
	Players[id][PlayerStep]--;
	if (Players[id][PlayerStep] <= Step_Item) {
		showItemsMenu(id);
		return;
	}

	get_item(Players[id][PlayerItem]);
	if (Players[id][PlayerStep] == Step_Extra) {
		show_item_step(id, ItemExtraHandler, showExtraMenu, 1);
	}

	if (Players[id][PlayerStep] == Step_Time) {
		show_item_step(id, ItemTimeHandler, showTimesMenu, 1);
	}

	if (Players[id][PlayerStep] == Step_Reason) {
		show_item_step(id, ItemResonHandler, showReasonsMenu, 1);
	}

	showItemsMenu(id);
}

makeAction(const id) {
	if (0 <= Players[id][PlayerReason] < ArraySize(Reasons)) {
		get_reason(Players[id][PlayerReason]);
	}
	if (Item[ItemHandler] != Handler_Default) {
		ExecuteForward(Item[ItemHandler], FwReturn, id, Players[id][PlayerTarget], Reason[ReasonTitle], Players[id][PlayerTime], Players[id][PlayerExtra]);
	} else if (Item[ItemType] != APS_InvalidType) {
		APS_PunishPlayer(Players[id][PlayerTarget], Item[ItemType], Players[id][PlayerTime], Reason[ReasonTitle], "", id, Players[id][PlayerExtra]);
	}
}

callHandler(const id, const item_s:handler) {
	if (0 <= Players[id][PlayerReason] < ArraySize(Reasons)) {
		get_reason(Players[id][PlayerReason]);
	}
	ExecuteForward(Item[handler], FwReturn, id, Players[id][PlayerTarget], Reason[ReasonTitle], Players[id][PlayerTime], Players[id][PlayerExtra]);
}

findPlayersForMenu(const id, const TeamName:team) {
	new num = Players[id][PlayerNum];
	for (new player = 1; player <= MaxClients; player++) {
		if (!is_user_connected(player) || TeamName:get_member(player, m_iTeam) != team) {
			continue;
		}

#if defined HIDE_ME_IN_MENU
		if (id == i) {
			continue;
		}
#endif

		Players[id][PlayerList][num] = player;
		Players[id][PlayerIds][num] = get_user_userid(player);
		num++;
	}

	Players[id][PlayerNum] = num;
}

bool:isTargetValid(const id) {
	new player = Players[id][PlayerTarget];
	return bool:(player != 0 && is_user_connected(player) && get_user_userid(player) == Players[id][PlayerTargetIndex]);
}

clearPlayer(const id) {
	Players[id][PlayerTarget] = 0;
	Players[id][PlayerTargetIndex] = 0;
	Players[id][PlayerTargetID] = 0;
	Players[id][PlayerPage] = 0;
	Players[id][PlayerNum] = 0;
	Players[id][PlayerStep] = Step_Item;
	Players[id][PlayerItem] = -1;
	Players[id][PlayerReason] = -1;
	Players[id][PlayerTime] = -1;
	Players[id][PlayerExtra] = 0;
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

stock parseTimes(const value[]) {
	ArrayClear(Times);
	new i, t, k;
	while (value[i] != EOS) {
		switch (value[i]) {
			case '0'..'9': {
				t = (t * 10) + (value[i] - '0');
			}

			case 'i': {
				k += t * 60;
				t = 0;
			}

			case 'h': {
				k += t * 3600;
				t = 0;
			}

			case 'd': {
				k += t * 86400;
				t = 0;
			}

			case 'w': {
				k += t * 604800;
				t = 0;
			}

			case 'm': {
				k += t * 2592000;
				t = 0;
			}

			case 'y': {
				k += t * 31104000;
				t = 0;
			}

			case ' ': {
				if (k + t > 0) {
					ArrayPushCell(Times, k + t);
				}
				t = 0;
				k = 0;
			}
		}

		i++;
	}

	if (i > 0) {
		ArrayPushCell(Times, k + t);
	}

	TimesNum = ArraySize(Times);
}