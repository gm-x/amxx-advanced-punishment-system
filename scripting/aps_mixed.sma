#include <amxmodx>
#include <aps>
#include <aps_plmenu>

#define MENU_TAB "^t^t"

const FLAG_KICK_ACCESS = ADMIN_KICK;      // Kick flag access
const FLAG_SLAP_ACCESS = ADMIN_SLAY;      // Slap flag access
const FLAG_SLAY_ACCESS = ADMIN_SLAY;      // Slay flag access

const MAX_DAMAGE_NUM = 7;

enum FWD {
	FWD_PlayerKick,
	FWD_PlayerKicked,
	FWD_PlayerSlap,
	FWD_PlayerSlaped,
	FWD_PlayerSlay,
	FWD_PlayerSlayed,
}

new Forwards[FWD], FwdReturn;

new Damage[] = {
	0, 5, 10, 15, 20
};

new APS_Type:KickTypeId, APS_Type:SlapTypeId, APS_Type:SlayTypeId;
new APS_PlMenu_Item:KickItemId = APS_PlMenu_InvalidItem, APS_PlMenu_Item:SlapItemId = APS_PlMenu_InvalidItem, APS_PlMenu_Item:SlayItemId = APS_PlMenu_InvalidItem;
new DamageNum = sizeof Damage;
new Players[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Mixed", APS_VERSION_STR, "GM-X Team");
	register_dictionary("aps_mixed.txt");

	// register_dictionary("admincmd.txt");
	// register_dictionary("common.txt");
	// register_dictionary("adminhelp.txt");

	register_concmd("amx_kick", "CmdKick", FLAG_KICK_ACCESS);
	register_concmd("amx_slap", "CmdSlap", FLAG_SLAP_ACCESS);
	register_concmd("amx_slay", "CmdSlay", FLAG_SLAY_ACCESS);

	register_concmd("amx_kickmenu", "CmdMenuKick", FLAG_KICK_ACCESS);
	register_concmd("amx_slapmenu", "CmdMenuSlap", FLAG_SLAP_ACCESS);
	register_concmd("amx_slaymenu", "CmdMenuSlay", FLAG_SLAY_ACCESS);

	register_menucmd(register_menuid("APS_SLAP_MENU"), 1023, "HandleSlapMenu");

	Forwards[FWD_PlayerKick] = CreateMultiForward("APS_PlayerKick", ET_STOP, FP_CELL, FP_CELL, FP_STRING);
	Forwards[FWD_PlayerKicked] = CreateMultiForward("APS_PlayerKicked", ET_IGNORE, FP_CELL, FP_CELL, FP_STRING);
	Forwards[FWD_PlayerSlap] = CreateMultiForward("APS_PlayerSlap", ET_STOP, FP_CELL, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerSlaped] = CreateMultiForward("APS_PlayerSlaped", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerSlay] = CreateMultiForward("APS_PlayerSlay", ET_STOP, FP_CELL, FP_CELL);
	Forwards[FWD_PlayerSlayed] = CreateMultiForward("APS_PlayerSlayed", ET_IGNORE, FP_CELL, FP_CELL);
}

public plugin_end() {
	DestroyForward(Forwards[FWD_PlayerKick]);
	DestroyForward(Forwards[FWD_PlayerKicked]);
	DestroyForward(Forwards[FWD_PlayerSlap]);
	DestroyForward(Forwards[FWD_PlayerSlaped]);
	DestroyForward(Forwards[FWD_PlayerSlay]);
	DestroyForward(Forwards[FWD_PlayerSlayed]);
}

public APS_Initing() {
	KickTypeId = APS_RegisterType("kick");
	SlapTypeId = APS_RegisterType("slap");
	SlayTypeId = APS_RegisterType("slay");
}

public APS_PlMenu_Inited() {
	KickItemId = APS_PlMenu_Add(
		KickTypeId, "APS_TYPE_KICK", 
		APS_PlMenu_CreateHandler("HandlePlMenuKickAction"),
		.timeHandler = APS_PlMenu_Handler_Invaild
	);
	SlapItemId = APS_PlMenu_Add(
		SlapTypeId, "APS_TYPE_SLAP",
		APS_PlMenu_CreateHandler("HandlePlMenuSlapAction"),
		.resonHandler = APS_PlMenu_Handler_Invaild, 
		.timeHandler = APS_PlMenu_Handler_Invaild, 
		.extraHandler = APS_PlMenu_Handler_Invaild,
		.needConfirm = false
	);
	SlayItemId = APS_PlMenu_Add(
		SlayTypeId, "APS_TYPE_SLAY",
		APS_PlMenu_CreateHandler("HandlePlMenuSlayAction"),
		.resonHandler = APS_PlMenu_Handler_Invaild, 
		.timeHandler = APS_PlMenu_Handler_Invaild, 
		.extraHandler = APS_PlMenu_Handler_Invaild,
		.needConfirm = true
	);
}

public APS_PlMenu_CheckAccess(const player, const target, const APS_PlMenu_Item:item) {
	if (item == KickItemId) {
		return (!APS_CanUserPunish(player, target, FLAG_KICK_ACCESS, APS_CheckAccess|APS_CheckImmunityLevel)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
	} else if (item == SlapItemId) {
		return (!APS_CanUserPunish(player, target, FLAG_SLAP_ACCESS, APS_CheckAccess|APS_CheckImmunityLevel)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
	} else if (item == SlayItemId) {
		return (!APS_CanUserPunish(player, target, FLAG_SLAY_ACCESS, APS_CheckAccess|APS_CheckImmunityLevel)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
	}

	return PLUGIN_CONTINUE;
}

public HandlePlMenuKickAction(const admin, const player, const reason[], const itme, const extra) {
	playerKick(admin, player, reason);
}

public HandlePlMenuSlapAction(const admin, const player) {
	Players[admin] = player;
	showSlapSlayMenu(admin);
}

public HandlePlMenuSlayAction(const admin, const player) {
	playerSlay(admin, player);
}

showSlapSlayMenu(const id) {
	SetGlobalTransTarget(id);

	new menu[MAX_MENU_LENGTH];
	new len = formatex(menu, charsmax(menu), "%s\r%l^n^n", MENU_TAB, "APS_MENU_SLAP_TITLE");

	new keys = MENU_KEY_0;

	for (new i = 0, item; i < DamageNum; i++) {
		keys |= (1 << item);
		len += formatex(menu[len], charsmax(menu) - len, "%s\r[%d] \w%l^n", MENU_TAB, ++item, "APS_MENU_ITEM_SLAP", Damage[i]);
	}

	len += formatex(menu[len], charsmax(menu) - len, "^n^n%s\r[0] \w%l", MENU_TAB, "BACK");

	show_menu(id, keys, menu, -1, "APS_SLAP_MENU");
}

public HandleSlapMenu(const id, const key) {
	switch (key) {
		case 9: {
			APS_PlMenu_PrevStep(id);
		}
		default: {
			playerSlap(id, Players[id], Damage[key]);
			showSlapSlayMenu(id);
		}
	}
}

public CmdKick(const id, const access) {
	enum { arg_player = 1, arg_reason };

	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	if (read_argc() < 1) {
		console_print(id, "USAGE: amx_kick <steamID or nickname or #authid or IP>  <reason>");
		return PLUGIN_HANDLED;
	}
	
	new target[32];
	read_argv(arg_player, target, charsmax(target));
	remove_quotes(target);
	new player = APS_FindPlayerByTarget(target);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}

	if (!APS_CanUserPunish(id, player, _, APS_CheckImmunityLevel)) {
		console_print(id, "Player has immunity!");
		return PLUGIN_HANDLED;        
	}

	new reason[APS_MAX_REASON_LENGTH];
	read_argv(arg_reason, reason, charsmax(reason));
	remove_quotes(reason);

	if (!playerKick(id, player, reason)) {
		console_print(id, "Kick was canceled");
	} else {
		console_print(id, "Player ^"%n^" kicked with reason ^"%s^"", player, reason);
	}
	return PLUGIN_HANDLED;
}

public CmdSlap(const id, const access) {
	enum { arg_player = 1, arg_damage };

	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	if (read_argc() < 2) {
		console_print(id, "USAGE: amx_slap <steamID or nickname or #authid or IP> <damage>");
		return PLUGIN_HANDLED;
	}
	
	new target[32];
	read_argv(arg_player, target, charsmax(target));
	remove_quotes(target);
	new player = APS_FindPlayerByTarget(target);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}

	if (!APS_CanUserPunish(id, player, _, APS_CheckImmunityLevel)) {
		console_print(id, "Player has immunity!");
		return PLUGIN_HANDLED;        
	}
	
	new damage = read_argv_int(arg_damage);

	if (!playerSlap(id, player, damage)) {
		console_print(id, "Slap was canceled");
	} else {
		console_print(id, "Player ^"%n^" slaped with %d damage", player, damage);
	}
	return PLUGIN_HANDLED;
}

public CmdSlay(const id, const access) {
	enum { arg_player = 1  };

	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	if (read_argc() < 2) {
		console_print(id, "USAGE: amx_slay <steamID or nickname or #authid or IP>");
		return PLUGIN_HANDLED;
	}
	
	new target[32];
	read_argv(arg_player, target, charsmax(target));
	remove_quotes(target);
	new player = APS_FindPlayerByTarget(target);
	if (!player) {
		console_print(id, "Player not found");
		return PLUGIN_HANDLED;
	}
	
	if (!APS_CanUserPunish(id, player, _, APS_CheckImmunityLevel)) {
		console_print(id, "Player has immunity!");
		return PLUGIN_HANDLED;        
	}
	
	if (!playerSlay(id, player)) {
		console_print(id, "Slap was canceled");
	} else {
		console_print(id, "Player ^"%n^" slayed", player);
	}
	return PLUGIN_HANDLED;
}

public CmdMenuKick(const id, const access) {
	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	APS_PlMenu_Show(id, .item = KickItemId);
	return PLUGIN_HANDLED;
}

public CmdMenuSlap(const id, const access) {
	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	APS_PlMenu_Show(id, .item = SlapItemId);
	return PLUGIN_HANDLED;
}

public CmdMenuSlay(const id, const access) {
	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	APS_PlMenu_Show(id, .item = SlayItemId);
	return PLUGIN_HANDLED;
}

bool:playerKick(const admin, const player, const reason[]) {
	ExecuteForward(Forwards[FWD_PlayerKick], FwdReturn, admin, player, reason);
	if (FwdReturn == PLUGIN_HANDLED) {
		return false;
	}

	if (!is_user_bot(player) && reason[0] != EOS) {
		rh_drop_client(player, reason);
	} else {
		rh_drop_client(player);
	}
	
	ExecuteForward(Forwards[FWD_PlayerKicked], FwdReturn, admin, player, reason);
	return true;
}

bool:playerSlap(const admin, const player, const damage) {
	ExecuteForward(Forwards[FWD_PlayerSlap], FwdReturn, admin, player, damage);
	if (FwdReturn == PLUGIN_HANDLED) {
		return false;
	}
	user_slap(player, damage);
	ExecuteForward(Forwards[FWD_PlayerSlaped], FwdReturn, admin, player, damage);
	return true;
}

bool:playerSlay(const admin, const player) {
	ExecuteForward(Forwards[FWD_PlayerSlay], FwdReturn, admin, player);
	if (FwdReturn == PLUGIN_HANDLED) {
		return false;
	}
	user_kill(player);
	ExecuteForward(Forwards[FWD_PlayerSlayed], FwdReturn, admin, player);
	return true;
}

public plugin_natives() {
	register_native("APS_PlayerKick", "NativeKick", 0);
	register_native("APS_PlayerSlap", "NativeSlap", 0);
	register_native("APS_PlayerSlay", "NativeSlay", 0);
}

public NativeKick(plugin, argc) {
	enum { arg_admin = 1, arg_player, arg_reason };

	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	
	new admin = get_param(arg_admin);
	if (admin != 0) {
		CHECK_NATIVE_PLAYER(admin, 0)
	}

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)
	
	new reason[APS_MAX_REASON_LENGTH];
	get_string(arg_reason, reason, charsmax(reason));
	
	return playerKick(admin, player, reason) ? 1 : 0;
}

public NativeSlap(plugin, argc) {
	enum { arg_admin = 1, arg_player, arg_damage };

	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	
	new admin = get_param(arg_admin);
	if (admin != 0) {
		CHECK_NATIVE_PLAYER(admin, 0)
	}

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)
	
	new damage = get_param(arg_damage);
	return playerSlap(admin, player, damage) ? 1 : 0;
}

public NativeSlay(plugin, argc) {
	enum { arg_admin = 1, arg_player };

	CHECK_NATIVE_ARGS_NUM(argc, 2, 0)
	
	new admin = get_param(arg_admin);
	if (admin != 0) {
		CHECK_NATIVE_PLAYER(admin, 0)
	}

	new player = get_param(arg_player);
	CHECK_NATIVE_PLAYER(player, 0)

	return playerSlay(admin, player) ? 1 : 0;
}
