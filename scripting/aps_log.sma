#include <amxmodx>
#include <gmx>
#include <aps>
#include <aps_mixed>
#include <aps_time>

#define FOREACH_PLAYERS(%0) for (new i = 0, %0 = Players[i]; i < PlayersNum; %0 = Players[++i])

// Show admins activity
// 0 - disabled
// 1 - show without admin name
// 2 - show with name
// 3 - show name only to admins, hide name from normal users
// 4 - show name only to admins, show nothing to normal users
// 5 - hide name only to admins, show nothing to normal users
enum (+=1) {
	ShowActivityDisabled = 0,
	ShowActivityHideName,
	ShowActivityAll,
	ShowActivityHideNamePlayers,
	ShowActivityDisablePlayers,
	ShowActivityHideNameDisablePlayers,
};

new ShowActivity;
new Players[MAX_PLAYERS], PlayersNum;
new bool:IsLoading[MAX_PLAYERS + 1] = { false, ... };
const SLAP_TASK_ID = 100;

enum _:slap_s{
	SlapAdmin,
	SlapTimes,
	SlapDamage
}
new SlapData[MAX_PLAYERS + 1][slap_s];

new APS_Type:BanTypeID, APS_Type:VoiceChatTypeID, APS_Type:TextChatTypeID;

public plugin_init() {
	register_plugin("[APS] Mixed", APS_VERSION_STR, "GM-X Team");

	register_dictionary("aps_log.txt");
	register_dictionary("aps_time.txt");

	new pcvar = get_cvar_pointer("amx_show_activity");
	if (!pcvar) {
		pcvar = create_cvar("amx_show_activity", "2", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 5.0);
	}
	bind_pcvar_num(pcvar, ShowActivity);
}

public client_putinserver(id) {
	SlapData[id][SlapAdmin] = -1;
	SlapData[id][SlapTimes] = 0;
	SlapData[id][SlapDamage] = 0;
	remove_task(id + SLAP_TASK_ID);
}

public client_disconnected(id) {
	SlapData[id][SlapAdmin] = -1;
	SlapData[id][SlapTimes] = 0;
	SlapData[id][SlapDamage] = 0;
	remove_task(id + SLAP_TASK_ID);
}

public APS_Inited() {
	BanTypeID = APS_GetTypeIndex("ban");
	VoiceChatTypeID = APS_GetTypeIndex("voice_chat");
	TextChatTypeID = APS_GetTypeIndex("text_chat");
}

public APS_PlayerChecking(const id) {
	IsLoading[id] = true;
}

public APS_PlayerChecked(const id) {
	IsLoading[id] = false;
}

public APS_PlayerPunished(const player, const APS_Type:type) {
	if (IsLoading[player]) {
		return;
	}

	if (type == BanTypeID) {
		playerBanned(player);
	} else if (type == VoiceChatTypeID) {
		playerBlockedVoice(player);
	} else if (type == TextChatTypeID) {
		playerBlockedText(player);
	}
}

public APS_PlayerKicked(const admin, const player, const reason[]) {
	log_amx("Kick: %N kick %N (reason ^"%s^")", admin, player, reason);
	if (admin == 0) {
		if (findPlayersForActivity(true, true)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_KICK_SERVER", player, reason);
			}
		}
	} else {
		if (findPlayersForActivity(true, false)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_KICK_ADMIN", admin, player, reason);
			}
		}
		if (findPlayersForActivity(false, false)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_KICK", player, reason);
			}
		}
	}
}

public APS_PlayerSlaped(const admin, const player, const damage) {
	log_amx("Cmd: %N slap %N with %d damage", admin, player, damage);

	if (!task_exists(player + SLAP_TASK_ID)) {
		SlapData[player][SlapAdmin] = admin;
		set_task(1.0, "TaskSlapNotify", player + SLAP_TASK_ID);
	} else if (SlapData[player][SlapAdmin] != admin) {
		slapFlush(player);
		SlapData[player][SlapAdmin] = admin;
		set_task(1.0, "TaskSlapNotify", player + SLAP_TASK_ID);
	} else {
		SlapData[player][SlapTimes]++;
		SlapData[player][SlapDamage] += damage;
		change_task(player + SLAP_TASK_ID, 1.0);
	}
}

public APS_PlayerSlayed(const admin, const player) {
	log_amx("Cmd: %N slay %N", admin, player);
	if (admin == 0) {
		if (findPlayersForActivity(true, true)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_SLAY_SERVER", player);
			}
		}
	} else {
		if (findPlayersForActivity(true, false)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_SLAY_ADMIN", admin, player);
			}
		}
		if (findPlayersForActivity(false, false)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_SLAY", player);
			}
		}
	}
}

public TaskSlapNotify(id) {
	id -= SLAP_TASK_ID;
	if (is_user_connected(id)) {
		slapFlush(id);
	} else if (1 <= id <= MaxClients) {
		SlapData[id][SlapAdmin] = -1;
		SlapData[id][SlapTimes] = 0;
		SlapData[id][SlapDamage] = 0;
		remove_task(id + SLAP_TASK_ID);
	}
}

slapFlush(const player) {
	if (SlapData[player][SlapAdmin] == 0) {
		if (findPlayersForActivity(true, true)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_SLAP_SERVER", player, SlapData[player][SlapTimes], SlapData[player][SlapDamage]);
			}
		}
	} else {
		if (findPlayersForActivity(true, false)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_SLAP_ADMIN", SlapData[player][SlapAdmin], player, SlapData[player][SlapTimes], SlapData[player][SlapDamage]);
			}
		}
		if (findPlayersForActivity(false, false)) {
			FOREACH_PLAYERS(id) {
				client_print_color(id, player, "%l", "APS_LOG_SLAP", player, SlapData[player][SlapTimes], SlapData[player][SlapDamage]);
			}
		}
	}

	SlapData[player][SlapAdmin] = -1;
	SlapData[player][SlapTimes] = 0;
	SlapData[player][SlapDamage] = 0;
	remove_task(player + SLAP_TASK_ID);
}

playerBanned(const player) {
	new admin = APS_GetPunisherId();
	new time = APS_GetTime();
	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];
	APS_GetReason(reason, charsmax(reason));
	APS_GetDetails(details, charsmax(details));

	log_amx("Ban: %N banned %N (time %d sec.) (reason ^"%s^") (details ^"%s^")", admin, player, time, reason, details);

	if (admin == 0) {
		if (findPlayersForActivity(true, true)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_BAN_SERVER", player, timeStr, reason);
			}
		}
	} else {
		if (findPlayersForActivity(true, false)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_BAN_ADMIN", admin, player, timeStr, reason);
			}
		}
		if (findPlayersForActivity(false, false)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_BAN", player, timeStr, reason);
			}
		}
	}
}

playerBlockedVoice(const player) {
	new admin = APS_GetPunisherId();
	new time = APS_GetTime();
	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];
	APS_GetReason(reason, charsmax(reason));
	APS_GetDetails(details, charsmax(details));

	log_amx("Voice Chat: %N blocked %N (time %d sec.) (reason ^"%s^") (details ^"%s^")", admin, player, time, reason, details);

	if (admin == 0) {
		if (findPlayersForActivity(true, true)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_VOICE_CHAT_SERVER", player, timeStr, reason);
			}
		}
	} else {
		if (findPlayersForActivity(true, false)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_VOICE_CHAT_ADMIN", admin, player, timeStr, reason);
			}
		}
		if (findPlayersForActivity(false, false)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_VOICE_CHAT", player, timeStr, reason);
			}
		}
	}
}

playerBlockedText(const player) {
	new admin = APS_GetPunisherId();
	new time = APS_GetTime();
	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];
	APS_GetReason(reason, charsmax(reason));
	APS_GetDetails(details, charsmax(details));

	log_amx("Text Chat: %N blocked %N (time %d sec.) (reason ^"%s^") (details ^"%s^")", admin, player, time, reason, details);

	if (admin == 0) {
		if (findPlayersForActivity(true, true)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_TEXT_CHAT_SERVER", player, timeStr, reason);
			}
		}
	} else {
		if (findPlayersForActivity(true, false)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_TEXT_CHAT_ADMIN", admin, player, timeStr, reason);
			}
		}
		if (findPlayersForActivity(false, false)) {
			new timeStr[64];
			FOREACH_PLAYERS(id) {
				aps_get_time_length(id, time, timeStr, charsmax(timeStr));
				client_print_color(id, player, "%l", "APS_LOG_TEXT_CHAT", player, timeStr, reason);
			}
		}
	}
}

bool:findPlayersForActivity(const bool:showNick, const bool:isServer) {
	if (ShowActivity == ShowActivityDisabled) {
		return false;
	}

	if (isServer) {
		findPlayers(true, true);
		return bool:(PlayersNum > 0);
	}

	switch (ShowActivity) {
		case ShowActivityHideName: {
			if (!showNick) {
				findPlayers(true, true);
				return bool:(PlayersNum > 0);
			}
		}
		case ShowActivityAll: {
			if (showNick) {
				findPlayers(true, true);
				return bool:(PlayersNum > 0);
			}
		}
		
		case ShowActivityHideNamePlayers: {
			if (showNick) {
				findPlayers(true, false);
				return bool:(PlayersNum > 0);
			} else {
				findPlayers(false, true);
				return bool:(PlayersNum > 0);
			}
		}
		
		case ShowActivityDisablePlayers: {
			if (showNick) {
				findPlayers(true, false);
				return bool:(PlayersNum > 0);
			}
		}
		
		case ShowActivityHideNameDisablePlayers: {
			if (!showNick) {
				findPlayers(true, false);
				return bool:(PlayersNum > 0);
			}
		}
	}

	return false;
}

findPlayers(const bool:admin, const bool:player) {
	arrayset(Players, 0, MAX_PLAYERS);
	PlayersNum = 0;
	for (new id = 1, isAdmin; id <= MaxClients; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) {
			continue;
		}
		
		if (admin && player) {
			Players[PlayersNum++] = id;
		} else {
			isAdmin = is_user_admin(id);
			if ((player && !isAdmin) || (admin && isAdmin)) {
				Players[PlayersNum++] = id;
			}
		}
	}
}

stock bool:is_user_admin(const id) {
	new __flags = get_user_flags(id);
	return bool:(__flags > 0 && !(__flags & ADMIN_USER));
}

stock getPlayers(players[MAX_PLAYERS], const bool:admin, const bool:player) {
	arrayset(players, 0, MAX_PLAYERS);
	new num = 0;
	for (new id = 1, isAdmin; id <= MaxClients; id++) {
		if (!is_user_connected(id) || is_user_hltv(id) || is_user_bot(id)) {
			continue;
		}
		
		if (admin && player) {
			players[num++] = id;
		} else {
			isAdmin = is_user_admin(id);
			if ((player && !isAdmin) || (admin && isAdmin)) {
				players[num++] = id;
			}
		}
	}
	
	return num;
}