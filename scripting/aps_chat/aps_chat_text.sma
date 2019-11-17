#include <amxmodx>
#include <aps>
#include <aps_chat>
#include <aps_chat_stocks>

new APS_Type:TypeId;
new bool:Blocked[MAX_PLAYERS + 1];

public plugin_precache() {
	register_clcmd("say", "CmdSay");
	register_clcmd("say_team", "CmdSay");
}

public plugin_init() {
	register_plugin("[APS] Chat CM Addon", APS_VERSION_STR, "GM-X Team");

	APS_TextIgnoreListInit();
}

public plugin_cfg() {
	new path[128];
	get_localinfo("amxx_configsdir", path, charsmax(path));
	add(path, charsmax(path), "/aps_text_ingore_list.ini");
	APS_TextIgnoreListLoad(path);
}

public client_disconnected(id) {
	Blocked[id] = false;
}

public APS_PlayerChecking(const id) {
	Blocked[id] = false;
}

public APS_Inited() {
	TypeId = APS_GetTypeIndex("text_chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS CHAT REAPI] Type text_chat not registered");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId) {
		Blocked[id] = true;
	}
}

public APS_PlayerAmnestying(const id, const APS_Type:type) {
	if (type == TypeId) {
		Blocked[id] = false;
	}
}

public CmdSay(const id) {
	if (!is_user_connected(id) || !Blocked[id]) {
		return PLUGIN_CONTINUE;
	}

	new message[128]
	read_args(message, charsmax(message));
	remove_quotes(message);
	trim(message);
	if (message[0] == '/' || APS_TextIgnoreListCheck(message)) {
		return PLUGIN_CONTINUE;
	}

	return PLUGIN_HANDLED;
}
