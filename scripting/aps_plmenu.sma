#include <amxmodx>
#include <reapi> // TODO: Remove dependency
#include <aps_mixed>

enum _:PlayerMenu {
	PlayerMenuName[MAX_NAME_LENGTH],
	PlayerMenuTarget,
	PlayerMenuPage,
	PlayerMenuNum,
	PlayerMenuList[MAX_PLAYERS],
	PlayerMenuIds[MAX_PLAYERS],
}

new PlayersMenu[MAX_PLAYERS + 1][PlayerMenu];

public plugin_init() {
	register_plugin("[APS] Players Menu", "0.1.0", "GM-X Team");
	RegisterHookChain(RG_CBasePlayer_SetClientUserInfoName, "CBasePlayer_SetClientUserInfoName_Post", true);

	register_clcmd("aps_plmenu", "CmdPlayersMenu");

	register_menucmd(register_menuid("APS_PLAYERS_MENU"), 1023, "HandlePlayersMenu");
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
	findPlayersForMenu(id, TEAM_TERRORIST);
	findPlayersForMenu(id, TEAM_CT);
	findPlayersForMenu(id, TEAM_SPECTATOR);
	if (PlayersMenu[id][PlayerMenuNum] > 0) {
		showPlayersMenu(id, 0);
	}
	return PLUGIN_HANDLED;
}

#define MENU_TAB "^t^t"

new TeamNames[][] = {
	"SPEC",
	"TT",
	"CT",
	"SPEC"
}
showPlayersMenu(const id, const page) {
	new start, end;
	PlayersMenu[id][PlayerMenuPage] = getMenuPage(page, PlayersMenu[id][PlayerMenuNum], 8, start, end);
	new pages = getMenuPagesNum(PlayersMenu[id][PlayerMenuNum], 8);
	new bool:firstPage = bool:(PlayersMenu[id][PlayerMenuPage] == 0);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^t\d%d/%d^n^n", MENU_TAB, "STB_MENU_TITLE", PlayersMenu[id][PlayerMenuNum] + 1, pages + 1);

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
		len += formatex(menu[len], charsmax(menu) - len, "^n%s\r[9] \w%L^n%s\r[0] \w%L", MENU_TAB, id, "MORE", MENU_TAB, id, (firstPage ? "EXIT" : "BACK"));
	} else {
		len += formatex(menu[len], charsmax(menu) - len, "^n^n%s\r[0] \w%L", MENU_TAB, id, (firstPage ? "EXIT" : "BACK"));
	}

	show_menu(id, keys, menu, -1, "APS_PLAYERS_MENU");
}

public HandlePlayersMenu(id, key) {
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
				// action
			}
		}
	}
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

stock getMenuPage(cur_page, elements_num, per_page, &start, &end) {
	new max = min(cur_page * per_page, elements_num);
	start = max - (max % 8);
	end = min(start + per_page, elements_num);
	return start / per_page;
}

stock getMenuPagesNum(elements_num, per_page) {
	return (elements_num - 1) / per_page;
}