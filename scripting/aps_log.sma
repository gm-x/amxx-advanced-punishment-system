#include <amxmodx>
// #include <aps>
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
			client_print_color(players[i], id, "% %s", "APS_LOG_PREFIX", buffer); \
		} \
	}

enum (<<=1) {
    APS_Chat_Voice = 1,
    APS_Chat_Text,
}

forward APS_PlayerBanned(const admin, const id, const time, const reason[], const details[]);

forward APS_PlayerBlockedChat(const admin, const id, const time, const reason[], const details[], const extra);

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

public plugin_init() {
	register_plugin("[APS] Mixed", "0.1.0", "GM-X Team");

	new pcvar = get_cvar_pointer("amx_show_activity");
	if (!pcvar) {
		pcvar = create_cvar("amx_show_activity", "2", .has_min = true, .min_val = 0.0, .has_max = true, .max_val = 5.0);
	}
	bind_pcvar_num(pcvar, ShowActivity);
}

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

public APS_PlayerKicked(const admin, const player, const reason[]) {
	log_amx("Kick: %N kick %N (reason ^"%s^")", admin, player, reason);
	if (admin == 0) {
		if (ShowActivity != ShowActivityDisabled) {
			showActivityServer(player, "^1Server kick ^3%n^1. Reason: ^4%s", player, reason);
		}
	} else {
		if (showActivityName()) {
			showActivity(true, player, "^1Admin ^4%n ^1kick ^3%n^1. Reason: ^4%s", admin, player, reason);
		}
		if (hideActivityName()) {
			showActivity(false, player, "^1Admin kick ^3%n^1. Reason: ^4%s", player, reason);
		}
	}
}

public APS_PlayerSlaped(const admin, const player, const damage) {
	log_amx("Cmd: %N slap with %d damage %N", admin, damage, player);
	if (admin == 0) {
		if (ShowActivity != ShowActivityDisabled) {
			showActivityServer(player, "^1Server slap ^3%n ^1with ^4%d ^1damage", player, damage);
		}
	} else {
		if (showActivityName()) {
			showActivity(true, player, "^1Admin ^4%n ^1slap ^3%n ^1with ^4%d ^1damage", admin, player, damage);
		}
		if (hideActivityName()) {
			showActivity(false, player, "^1Admin slap ^3%n ^1with ^4%d ^1damage", player, damage);
		}
	}
}

public APS_PlayerSlayed(const admin, const player) {
	log_amx("Cmd: %N slay %N", admin, player);
	if (admin == 0) {
		if (ShowActivity != ShowActivityDisabled) {
			showActivityServer(player, "^1Server kill ^3%n", player);
		}
	} else {
		if (showActivityName()) {
			showActivity(true, player, "^1Admin ^4%n ^1kill ^3%n", admin, player);
		}
		if (hideActivityName()) {
			showActivity(false, player, "^1Admin kill ^3%n", player);
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