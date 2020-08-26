#include <amxmodx>
#include <aps>
#include <aps_plmenu>
#include <aps_time>

const FLAG_ACCESS = ADMIN_BAN;      // Bans flag access

enum FWD {
	FWD_PlayerBanKick,
}

new Forwards[FWD], FwdReturn;

new APS_Type:TypeId, APS_PlMenu_Item:ItemId = APS_PlMenu_InvalidItem;

public plugin_init() {
	register_plugin("[APS] Ban", APS_VERSION_STR, "GM-X Team");

	register_dictionary("aps_ban.txt");
	register_dictionary("aps_time.txt");

	register_concmd("aps_ban", "CmdBan", FLAG_ACCESS);
	register_concmd("aps_banmenu", "CmdMenu", FLAG_ACCESS);
	Forwards[FWD_PlayerBanKick] = CreateMultiForward("APS_PlayerBanKick", ET_STOP, FP_CELL);
}

public plugin_cfg() {
	consoleParseConfig();
}

public plugin_end() {
	consoleClear();
	DestroyForward(Forwards[FWD_PlayerBanKick]);
}

public APS_Initing() {
	TypeId = APS_RegisterType("ban");
}

public APS_PlMenu_Inited() {
	ItemId = APS_PlMenu_Add(TypeId, "APS_TYPE_BAN");
}

public APS_PlMenu_CheckAccess(const player, const target, const APS_PlMenu_Item:item) {
	if (item == ItemId) {
		return (!APS_CanUserPunish(player, target, FLAG_ACCESS, APS_CheckAccess|APS_CheckImmunityLevel)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
	} 

	return PLUGIN_CONTINUE;
}

public HandlePlMenuAction(const admin, const player, const reason[], const time) {
	APS_PunishPlayer(player, TypeId, time, reason, "", admin);
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type != TypeId) {
		return;
	}

	ExecuteForward(Forwards[FWD_PlayerBanKick], FwdReturn, id);
	if (FwdReturn == PLUGIN_HANDLED) {
		return;
	}

	consolePrint(id);
	set_task(0.3, "TaskKick", id)
}

public TaskKick(const id) {
	if (is_user_connected(id) || is_user_connecting(id)) {
		rh_drop_client(id, "Вы были забанены! Детали в консоли или на сайте.");
	}
}

public CmdBan(const id, const access) {
	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	new cmd[256], arg[64], pos;
	read_args(cmd, charsmax(cmd));

	pos = argparse(cmd, pos, arg, charsmax(arg));
	new player = APS_FindPlayerByTarget(arg);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}

	pos = argparse(cmd, pos, arg, charsmax(arg));
	new time = str_to_num(arg);

	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];
	if (cmd[pos + 1] == '"') {
		pos = argparse(cmd, pos, reason, charsmax(reason));
		argparse(cmd, pos, details, charsmax(details));
	} else {
		copy(reason, charsmax(reason), cmd[pos + 1]);
	}
	if (reason[0] == EOS) {
		console_print(id, "USAGE: aps_ban <steamID or nickname or #authid or IP> <time in mins> <reason> [details]");
		return PLUGIN_HANDLED;
	}

	APS_PunishPlayer(player, TypeId, time, reason, details, id);
	return PLUGIN_HANDLED;
}

public CmdMenu(const id, const access) {
	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	APS_PlMenu_Show(id, .item = ItemId);
	return PLUGIN_HANDLED;
}

// CONSOLE OUTPUT
enum TokenEnum (+=1) {
	TokenInvalid = -1,
	TokenPercent,
	TokenNewLine,
	TokenString,
	TokenBanId,
	TokenPlayerName,
	TokenPlayerIP,
	TokenPlayerSteamID,
	TokenReason,
	TokenCreated,
	TokenTime,
	TokenLeft,
	TokenExpired,
}

enum _:TokenStruct {
	TokenEnum:TokenInfoID,
	TokenInfoExtra
}
new Array:ConsoleTokens = Invalid_Array;
new Array:ConsoleStrings = Invalid_Array;
new Token[TokenStruct];

consoleParseConfig() {
	new path[128];
	get_localinfo("amxx_configsdir", path, charsmax(path));
	add(path, charsmax(path), "/aps_ban_console.txt");

	new file = fopen(path, "rt");
	if (!file) {
		return;
	}

	ConsoleTokens = ArrayCreate(TokenStruct, 0);
	ConsoleStrings = ArrayCreate(192, 0);

	new line[256];
	new semicolonPos;

	while (!feof(file)) {
		fgets(file, line, charsmax(line));
		if ((semicolonPos = contain(line, ";")) != -1) {
			line[semicolonPos] = EOS;
		}

		trim(line);
		consoleParseLine(line);
	}

	fclose(file);

	arrayset(Token, 0, sizeof Token);
	ArrayGetArray(ConsoleTokens, ArraySize(ConsoleTokens) - 1, Token, sizeof Token);
	if (Token[TokenInfoID] != TokenNewLine) {
		arrayset(Token, 0, sizeof Token);
		Token[TokenInfoID] = TokenNewLine;
		ArrayPushArray(ConsoleTokens, Token, sizeof Token);
	}
}

consoleParseLine(const tpl[]) {
	new bool:newLine = true, bool:opened = false, tmp[192], len = 0, TokenEnum:tkn;
	for (new i = 0; tpl[i] != EOS; i++) {
		if (opened) {
			if (tpl[i] != '%') {
				tmp[len++] = tpl[i];
			} else if (len == 0) {
				newLine = consolePushToken(TokenPercent, newLine);
				opened = false;
				tmp = "";
				len = 0;
			} else {
				tmp[len] = EOS;
				tkn = consoleGetToken(tmp);
				if (tkn != TokenInvalid) {
					newLine = consolePushToken(tkn, newLine);
				}
				opened = false;
				tmp = "";
				len = 0;
			}
		} else if (tpl[i] == '%') {
			newLine = consolePushString(tmp, newLine);
			opened = true;
			tmp = "";
			len = 0;
		} else {
			tmp[len++] = tpl[i];
		}
	}

	if (len > 0 && !opened && !(len == 1 && tmp[0] == EOS)) {
		tmp[len] = EOS;
		consolePushString(tmp, newLine);
	}
}

TokenEnum:consoleGetToken(const token[]) {
	if (equal(token, "ID")) {
		return TokenBanId;
	}

	if (equal(token, "PLAYER_NAME")) {
		return TokenPlayerName;
	}

	if (equal(token, "PLAYER_IP")) {
		return TokenPlayerIP;
	}

	if (equal(token, "PLAYER_STEAMID")) {
		return TokenPlayerSteamID;
	}

	if (equal(token, "REASON")) {
		return TokenReason;
	}

	if (equal(token, "CREATED")) {
		return TokenCreated;
	}

	if (equal(token, "TIME")) {
		return TokenTime;
	}

	if (equal(token, "LEFT")) {
		return TokenLeft;
	}

	if (equal(token, "EXPIRED")) {
		return TokenExpired;
	}

	return TokenInvalid;
}

bool:consolePushToken(const TokenEnum:token, bool:newLine) {
	if (newLine && ArraySize(ConsoleTokens) > 0) {
		arrayset(Token, 0, sizeof Token);
		Token[TokenInfoID] = TokenNewLine;
		ArrayPushArray(ConsoleTokens, Token, sizeof Token);
		newLine = false;
	}
	arrayset(Token, 0, sizeof Token);
	Token[TokenInfoID] = token;
	ArrayPushArray(ConsoleTokens, Token, sizeof Token);

	return newLine;
}

bool:consolePushString(const buffer[], bool:newLine) {
	if (newLine && ArraySize(ConsoleTokens) > 0) {
		arrayset(Token, 0, sizeof Token);
		Token[TokenInfoID] = TokenNewLine;
		ArrayPushArray(ConsoleTokens, Token, sizeof Token);
		newLine = false;
	}
	new index = ArrayPushString(ConsoleStrings, buffer);
	arrayset(Token, 0, sizeof Token);
	Token[TokenInfoID] = TokenString;
	Token[TokenInfoExtra] = index;
	ArrayPushArray(ConsoleTokens, Token, sizeof Token);

	return newLine;
}

consoleClear() {
	if (ConsoleTokens != Invalid_Array) {
		ArrayDestroy(ConsoleTokens);
	}
	if (ConsoleStrings != Invalid_Array) {
		ArrayDestroy(ConsoleStrings);
	}
}

consolePrint(const id) {
	if (ConsoleTokens == Invalid_Array) {
		return;
	}

	SetGlobalTransTarget(id);

	new buffer[192], len;
	for (new i = 0, n = ArraySize(ConsoleTokens); i < n; i++ ) {
		arrayset(Token, 0, sizeof Token);
		ArrayGetArray(ConsoleTokens, i, Token, sizeof Token);
		switch (Token[TokenInfoID]) {

			case TokenPercent: {
				len = add(buffer, charsmax(buffer) - 1, "%");
			}

			case TokenNewLine: {
				buffer[len] = '^n';
				buffer[len + 1] = EOS;
				message_begin(MSG_ONE, SVC_PRINT, .player = id);
				write_string(buffer);
				message_end();
				buffer = "";
				len = 0;
			}

			case TokenString: {
				len += ArrayGetString(ConsoleStrings, Token[TokenInfoExtra], buffer[len], charsmax(buffer) - len - 1);
			}

			case TokenBanId: {
				len += formatex(buffer[len], charsmax(buffer) - len - 1, "%d", APS_GetId());
			}

			case TokenPlayerName: {
				len += get_user_name(id,  buffer[len], charsmax(buffer) - len - 1);
			}

			case TokenPlayerIP: {
				len += get_user_ip(id,  buffer[len], charsmax(buffer) - len, 1);
			}

			case TokenPlayerSteamID: {
				len += get_user_authid(id,  buffer[len], charsmax(buffer) - len - 1);
			}

			case TokenReason: {
				len += APS_GetReason(buffer[len], charsmax(buffer) - len - 1);
			}

			case TokenCreated : {
				len += format_time(buffer[len], charsmax(buffer) - len - 1, "%d/%m/%Y %H:%M:%S", APS_GetCreated() + GMX_GetServerTimeDiff());
			}
			case TokenTime : {
				len += aps_get_time_length(id, APS_GetTime(), buffer[len], charsmax(buffer) - len - 1);
			}

			case TokenLeft : {
				if (APS_GetTime() > 0) {
					len += aps_get_time_length(id, APS_GetExpired() - get_systime()  + GMX_GetServerTimeDiff(), buffer[len], charsmax(buffer) - len - 1);
				} else {
					len += formatex(buffer[len], charsmax(buffer) - len - 1, "%l", "APS_BAN_NEVER");
				}
			}

			case TokenExpired: {
				len += format_time(buffer[len], charsmax(buffer) - len - 1, "%d/%m/%Y %H:%M:%S", APS_GetExpired() + GMX_GetServerTimeDiff());
			}
		}
	}
}
