#include <amxmodx>
#include <aps>
#include <aps_plmenu>

const FLAG_ACCESS = ADMIN_CHAT;      // Gags flag access

new APS_Type:TypeId, APS_PlMenu_Item:ItemId = APS_PlMenu_InvalidItem;

public plugin_init() {
	register_plugin("[APS] Text Chat", APS_VERSION_STR, "GM-X Team");
	register_dictionary("aps_text_chat.txt");

	register_concmd("aps_gag", "CmdGag", FLAG_ACCESS);
	register_concmd("aps_chatmenu", "CmdMenu", FLAG_ACCESS);
}

public APS_Initing() {
	TypeId = APS_RegisterType("text_chat");
}

public APS_PlMenu_Inited() {
	ItemId = APS_PlMenu_Add(TypeId, "APS_TYPE_TEXT_CHAT");
}

public APS_PlMenu_CheckAccess(const player, const target, const APS_PlMenu_Item:item) {
	if (item == ItemId) {
		return (!APS_CanUserPunish(player, target, FLAG_ACCESS, APS_CheckAccess|APS_CheckImmunityLevel)) ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
	} 

	return PLUGIN_CONTINUE;
}

public CmdGag(const id, const access) {
	if (!APS_CanUserPunish(id, _, access, APS_CheckAccess)) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;        
	}

	enum { arg_player = 1, arg_time, arg_reason, arg_details };

	if (read_argc() < 3) {
		console_print(id, "USAGE: aps_gag <steamID or nickname or #authid or IP> <time in mins> <reason> [details]");
		return PLUGIN_HANDLED;
	}

	new tmp[32];
	read_argv(arg_player, tmp, charsmax(tmp));

	new player = APS_FindPlayerByTarget(tmp);
	if (!player) {
		console_print(id, "Invalid player %s", tmp);
		return PLUGIN_HANDLED;
	}

	if (!APS_CanUserPunish(id, player, _, APS_CheckImmunityLevel)) {
		console_print(id, "Player has immunity!");
		return PLUGIN_HANDLED;        
	}

	new time = read_argv_int(arg_time) * 60;
	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];

	read_argv(arg_reason, reason, charsmax(reason));
	read_argv(arg_details, details, charsmax(details));

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
