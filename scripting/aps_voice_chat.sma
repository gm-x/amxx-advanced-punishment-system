#include <amxmodx>
#include <aps>
#include <aps_plmenu>

new APS_Type:TypeId;

public plugin_init() {
	register_plugin("[APS] Voice Chat", "0.1.1", "GM-X Team");
	register_dictionary("aps_voice_chat.txt");

	register_concmd("amx_mute", "CmdMute", ADMIN_CHAT);
}

public APS_Initing() {
	TypeId = APS_RegisterType("voice_chat");
}

public APS_PlMenu_Inited() {
	APS_PlMenu_Add(TypeId, "APS_TYPE_VOICE_CHAT");
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
