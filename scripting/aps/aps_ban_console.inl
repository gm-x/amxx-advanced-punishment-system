#if defined _aps_ban_console_included
	#endinput
#endif

#define _aps_ban_console_included

enum TokenEnum (+=1) {
	TokenInvalid = -1,
	TokenPercent,
	TokenNewLine,
	TokenString,
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

			case TokenExpired: {
				len += format_time(buffer[len], charsmax(buffer) - len - 1, "%d/%m/%Y %H:%M:%S", APS_GetExpired());
			}
		}
	}
}
