#include <amxmodx>
#include <gmx>
#include <aps>
// #include <aps_ban>
// #include <aps_chat>
#include <aps_mixed>

#define DISPLAY_CHAT(%1,%2,%3,%4) \
	new players[MAX_PLAYERS]; \
	new num = getPlayers(players, %1, %2); \
	if (num > 0) { \
		for (new i = 0, buffer[192]; i < num; i++) { \
			SetGlobalTransTarget(players[i]); \
			vformat(buffer, charsmax(buffer), %3, %4); \
			client_print_color(players[i], id, "%l %s", "APS_LOG_PREFIX", buffer); \
		} \
	}

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

new APS_Type:BanTypeID;

public plugin_init() {
	register_plugin("[APS] Mixed", "0.1.0", "GM-X Team");
	register_dictionary("aps_log.txt");

	new pcvar = get_cvar_pointer("amx_show_activity");
	if (!pcvar) {
		pcvar = create_cvar("amx_show_activity", "2", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 5.0);
	}
	bind_pcvar_num(pcvar, ShowActivity);
}

public APS_Inited() {
	BanTypeID = APS_GetTypeIndex("ban");
}

public APS_PlayerPunished(const player, const APS_Type:type) {
	if (type == BanTypeID) {
		// log_amx("Ban: %N ban %N (time %d mins.) (reason ^"%s^") (details ^"%s^")", admin, id, time, reason, details);
	}
}

/*
public APS_PlayerBanned(const admin, const id, const time, const reason[], const details[]) {
	log_amx("Punishment: %N ban %N (time %d mins.) (reason ^"%s^") (details ^"%s^")", admin, id, time, reason, details);
}

public APS_PlayerBlockedChat(const admin, const id, const time, const reason[], const details[], const extra) {
	if ((extra & (APS_Chat_Voice | APS_Chat_Text)) == (APS_Chat_Voice | APS_Chat_Text)) {
		log_amx("Punishment: %N block voice and text chat %N (time %d mins.) (reason ^"%s^") (details ^"%s^")", admin, id, time, reason, details);
	} else if (extra & APS_Chat_Voice) {
		log_amx("Punishment: %N block voice chat %N (time %d mins.) (reason ^"%s^") (details ^"%s^")", admin, id, time, reason, details);
	} else if (extra & APS_Chat_Text) {
		log_amx("Punishment: %N block text chat %N (time %d mins.) (reason ^"%s^") (details ^"%s^")", admin, id, time, reason, details);
	}
}
*/

public APS_PlayerKicked(const admin, const player, const reason[]) {
	log_amx("Kick: %N kick %N (reason ^"%s^")", admin, player, reason);
	if (admin == 0) {
		if (ShowActivity != ShowActivityDisabled) {
			showActivityServer(player, "%l", "APS_LOG_KICK_SERVER", player, reason);
		}
	} else {
		if (showActivityName()) {
			showActivity(true, player, "%l", "APS_LOG_KICK_ADMIN", admin, player, reason);
		}
		if (hideActivityName()) {
			showActivity(false, player, "%l", "APS_LOG_KICK", player, reason);
		}
	}
}

public APS_PlayerSlaped(const admin, const player, const damage) {
	log_amx("Cmd: %N slap with %d damage %N", admin, damage, player);
	if (admin == 0) {
		if (ShowActivity != ShowActivityDisabled) {
			showActivityServer(player, "%l", "APS_LOG_SLAP_SERVER", player, damage);
		}
	} else {
		if (showActivityName()) {
			showActivity(true, player, "%l", "APS_LOG_SLAP_ADMIN", admin, player, damage);
		}
		if (hideActivityName()) {
			showActivity(false, player, "%l", "APS_LOG_SLAP", player, damage);
		}
	}
}

public APS_PlayerSlayed(const admin, const player) {
	log_amx("Cmd: %N slay %N", admin, player);
	if (admin == 0) {
		if (ShowActivity != ShowActivityDisabled) {
			showActivityServer(player, "%l", "APS_LOG_SLAY_SERVER", player);
		}
	} else {
		if (showActivityName()) {
			showActivity(true, player, "%l", "APS_LOG_SLAY_ADMIN", admin, player);
		}
		if (hideActivityName()) {
			showActivity(false, player, "%l", "APS_LOG_SLAY", player);
		}
	}
}

showActivityServer(const id, const fmt[], any:...) {
	DISPLAY_CHAT(true, showActivityServerForPlayers(), fmt, 3)
}

showActivity(const bool:adminnick, const id, const fmt[], any:...) {
	switch (ShowActivity) {
		case ShowActivityHideName: {
			if (!adminnick) {
				DISPLAY_CHAT(true, true, fmt, 4)
			}
		}
		case ShowActivityAll: {
			if (adminnick) {
				DISPLAY_CHAT(true, true, fmt, 4)
			}
		}
		
		case ShowActivityHideNamePlayers: {
			if (adminnick) {
				DISPLAY_CHAT(true, false, fmt, 4)
			} else {
				DISPLAY_CHAT(false, true, fmt, 4)
			}
		}
		
		case ShowActivityDisablePlayers: {
			if (adminnick) {
				DISPLAY_CHAT(true, false, fmt, 4)
			}
		}
		
		case ShowActivityHideNameDisablePlayers: {
			if (!adminnick) {
				DISPLAY_CHAT(true, false, fmt, 4)
			}
		}
	}
}

stock bool:showActivityServerForPlayers() {
	return bool: (
		ShowActivity == ShowActivityHideName
		|| ShowActivity == ShowActivityAll
		|| ShowActivity == ShowActivityHideNamePlayers
	);
}

bool:showActivityName() {
	return bool: (
		ShowActivity == ShowActivityAll
		|| ShowActivity == ShowActivityHideNamePlayers
		|| ShowActivity == ShowActivityDisablePlayers
	);
}

bool:hideActivityName() {
	return bool: (
		ShowActivity == ShowActivityHideName
		|| ShowActivity == ShowActivityHideNamePlayers
		|| ShowActivity == ShowActivityHideNameDisablePlayers
	);
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