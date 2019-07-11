#include <amxmodx>
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

enum FWD {
	FWD_PlayerBanKick,
}

new Forwards[FWD], FwdReturn;

new APS_Type:TypeId;

public plugin_init() {
	register_plugin("[APS] Ban", "0.1.0", "GM-X Team");
	
	register_concmd("aps_ban", "CmdBan", ADMIN_BAN);

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

public APS_PlayerPunished(const id, const APS_Type:type) {
	if(type != TypeId) {
		return;
	}

	ExecuteForward(Forwards[FWD_PlayerBanKick], FwdReturn, id);
	if (FwdReturn == PLUGIN_HANDLED) {
		return;
	}
	
	consolePrint(id);
	RequestFrame("HandleKick", id);
}

public HandleKick(const id) {
	if (is_user_connected(id) || is_user_connecting(id)) {
		server_cmd("kick #%d ^"%s^"", get_user_userid(id), "Вы были забанены! Детали в консоли или на сайте.");
	}
}

public CmdBan(const id, const level) {
	enum { arg_player = 1, arg_time, arg_reason, arg_details };

	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	if (read_argc() < 2) {
		console_print(id, "USAGE: aps_ban <steamID or nickname or #authid or IP> <time in mins> <reason> [details]");
		return PLUGIN_HANDLED;
	}

	new tmp[32];
	read_argv(arg_player, tmp, charsmax(tmp));
	new player = APS_FindPlayerByTarget(tmp);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}

	new time = read_argv_int(arg_time) * 60;

	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];
	read_argv(arg_reason, reason, charsmax(reason));
	read_argv(arg_details, details, charsmax(details));

	APS_PunishPlayer(player, TypeId, time, reason, details, id);

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
	add(path, charsmax(path), "/abs_ban_console.txt");

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
				tkn = consoleGetTocken(tmp);
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

TokenEnum:consoleGetTocken(const token[]) {
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

			case TokenCreated : {}
			case TokenTime : {}
			case TokenLeft : {}

			case TokenExpired: {
				len += format_time(buffer[len], charsmax(buffer) - len - 1, "%d/%m/%Y %H:%M:%S", APS_GetExpired());
			}
		}
	}
}

// NATIVES
public plugin_natives() {
	register_native("APS_Ban", "NativeBan", 0);
}

public NativeBan(plugin, argc) {
	CHECK_NATIVE_ARGS_NUM(argc, 4, 0)
	enum { arg_admin = 1, arg_player, arg_time, arg_reason, arg_details };

	new admin = get_param(arg_admin);
	CHECK_NATIVE_PLAYER(admin, 0)

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	new time = get_param(arg_time);

	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];
	get_string(arg_reason, reason, charsmax(reason));
	get_string(arg_details, details, charsmax(details));

	APS_PunishPlayer(player, TypeId, time, reason, details, admin);	
	return 1;
}
