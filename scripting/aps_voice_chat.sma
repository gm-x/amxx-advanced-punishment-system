#include <amxmodx>
#include <aps>
#include <aps_plmenu>

const FLAG_ACCESS           = ADMIN_CHAT;			// Флаг доступа к блокировке чата
const FLAG_IMMUNITY         = ADMIN_IMMUNITY;       // Флаг иммунитета к блокировке чата
const FLAG_IGNORE_IMMUNITY  = ADMIN_RCON;           // Флаг, который может игнорировать иммунитет к блокировке чата 

new APS_Type:TypeId, APS_PlMenu_Item:ItemId = APS_PlMenu_InvalidItem;

#define has_user_acess(%0,%1)           bool:((get_user_flags(%0) & %1) == %1) 

public plugin_init() {
	register_plugin("[APS] Voice Chat", APS_VERSION_STR, "GM-X Team");
	register_dictionary("aps_voice_chat.txt");

	register_concmd("amx_mute", "CmdMute", FLAG_ACCESS);
	register_concmd("aps_voicemenu", "CmdMenu", FLAG_ACCESS);
}

public APS_Initing() {
	TypeId = APS_RegisterType("voice_chat");
}

public APS_PlMenu_Inited() {
	ItemId = APS_PlMenu_Add(TypeId, "APS_TYPE_VOICE_CHAT");
}

public APS_PlMenu_CheckAccess(const player, const target, const APS_PlMenu_Item:item) {
    if(item != ItemId) {
        return PLUGIN_CONTINUE;
    }

    if(!has_user_acess(player, FLAG_IGNORE_IMMUNITY) && has_user_acess(target, FLAG_IMMUNITY)) {
        return PLUGIN_HANDLED;
    }

    if(has_user_acess(player, FLAG_IGNORE_IMMUNITY)) {
        return PLUGIN_CONTINUE;
    }

    return PLUGIN_CONTINUE;
}

public CmdMute(const id, const access) {
	if(~get_user_flags(id) & access) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	enum { arg_player = 1, arg_time, arg_reason, arg_details };

	if(read_argc() < 3) {
		console_print(id, "USAGE: amx_mute <steamID or nickname or #authid or IP> <time in mins> <reason> [details]");
		return PLUGIN_HANDLED;
	}

	new tmp[32];
	read_argv(arg_player, tmp, charsmax(tmp));

	new player = APS_FindPlayerByTarget(tmp);
	if(!player) {
		console_print(id, "Invalid player %s", tmp);
		return PLUGIN_HANDLED;
	}

	new time = read_argv_int(arg_time) * 60;
	new reason[APS_MAX_REASON_LENGTH], details[APS_MAX_DETAILS_LENGTH];

	read_argv(arg_reason, reason, charsmax(reason));
	read_argv(arg_details, details, charsmax(details));

	APS_PunishPlayer(player, TypeId, time, reason, details, id);
	return PLUGIN_HANDLED;
}

public CmdMenu(const id, const level) {
	if(~get_user_flags(id) & level) {
		console_print(id, "You have not access to this command!");
		return PLUGIN_HANDLED;
	}

	APS_PlMenu_Show(id, .item = ItemId);
	return PLUGIN_HANDLED;
}
