#include <amxmodx>
#include <aps>
#include <aps_chat>
#include <aps_chat_stocks>

new APS_Type:TypeId;
new bool:Blocked[MAX_PLAYERS + 1];

public plugin_init() {
	register_plugin("[APS] Chat CM Addon", "0.1.0", "GM-X Team");

	register_clcmd("say", "CmdSay");
	register_clcmd("say_team", "CmdSay");

	APS_TextIgnoreListInit();
}

public plugin_cfg() {
	new path[128];
	get_localinfo("amxx_configsdir", path, charsmax(path));
	add(path, charsmax(path), "/aps_text_ingore_list.ini");
	APS_TextIgnoreListLoad(path);
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

public client_connect(id) {
	Blocked[id] = false;
}

public client_disconnected(id) {
	Blocked[id] = false;
}

public APS_Inited() {
	TypeId = APS_GetTypeIndex("chat");
	if (TypeId == APS_InvalidType) {
		set_fail_state("[APS CHAT TEXT] chat module not found");
	}
}

public APS_PlayerPunished(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Text) {
		Blocked[id] = true;
	}
}

public APS_PlayerExonerated(const id, const APS_Type:type) {
	if (type == TypeId && APS_GetExtra() & APS_Chat_Text) {
		Blocked[id] = false;
	}
}
