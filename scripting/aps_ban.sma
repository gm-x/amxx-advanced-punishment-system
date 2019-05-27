#include <amxmodx>
#include <grip>
#include <gmx>
//#include <aps>

const ACCESS_FLAG = ADMIN_BAN;

new const BANCMD[] = "amx_ban";
new const PUNISH_TYPE_NAME[] = "ban";

#if !defined NOT_CLIENT
	const NOT_CLIENT = 0;
#endif

#if !defined MAX_REASON_LENGTH
    const MAX_REASON_LENGTH = 64;
#endif

#if !defined MAX_INFO_LENGTH
    const MAX_INFO_LENGTH = 64;
#endif

#if !defined MAX_TIME_STRING_LENGTH
    const MAX_TIME_STRING_LENGTH = 12;
#endif

enum _:ArgsType {
    ARG_Time = 1,
    ARG_PlayerInfo,
    ARG_Reason
};

enum APS_PunisherType {
    APS_PunisherTypePlayer,
    APS_PunisherTypeUser,
    APS_PunisherTypeServer
};

new g_BanTypeId;

forward GMX_PlayerLoaded(const id, const arg2, const GripJSONValue:data);

forward APS_Init();
forward APS_TypeRegistered(const typeId, const name[]);
forward APS_PunishedPlayerPost(const id, const typeId, const expired);

native APS_RegisterType(const name[], const description[]);
native APS_PunishPlayer(const id, const typeId, const expired, const reason[], const details[] = "", const APS_PunisherType:punisherType = APS_PunisherTypeServer, const punisherId = 0);

public plugin_init() {
    register_plugin("[APS] Ban", "0.1.0", "GM-X Team");
    
    register_concmd(BANCMD, "CmdBan", ACCESS_FLAG);
}

public APS_Init() {
    APS_RegisterType(PUNISH_TYPE_NAME, "Ban");
}

public APS_TypeRegistered(const typeId, const name[]) {
    if(equal(name, PUNISH_TYPE_NAME)) {
        g_BanTypeId = typeId;
    }
}

public GMX_PlayerLoaded(const id, const arg2, const GripJSONValue:data) {

}

public APS_PunishedPlayerPost(const id, const typeId, const expired) {
    if(typeId != g_BanTypeId) {
        return PLUGIN_CONTINUE;
    }
    
    server_cmd("kick #%d", get_user_userid(id));

    return PLUGIN_CONTINUE;
}

public CmdBan(const id, const level) {
    if(~get_user_flags(id) & level) {
        client_print(id, print_console, "You have not access to this command!");
        return PLUGIN_HANDLED;
    }

    if(read_argc() < ArgsType) {
        // Посылаем сообщения по отдельности, потому что клиенсткая консоль ограничена 127 байтами (дабы не упереться в лимит)
        // https://github.com/alliedmodders/amxmodx/blob/1cc7786a4c260ca9ad55fa9fd1c8c415115ead89/amxmodx/amxmodx.cpp#L181
        console_print(id, "* Invalid command syntax!");
        console_print(id, "* Structure: %s <time> <#userid/name/steamid> <reason>", BANCMD);
        console_print(id, "* Example: %s 60 ^"Player Name^" ^"Example Reason^"", BANCMD);
        console_print(id, "* Importantly! Nickname or reason with a space must be limited to quotes!");

        return PLUGIN_HANDLED;
    }

    new time[MAX_TIME_STRING_LENGTH], playerData[MAX_INFO_LENGTH], reason[MAX_REASON_LENGTH];

    read_argv(ARG_Time, time, charsmax(time)); 
    read_argv(ARG_PlayerInfo, playerData, charsmax(playerData)); 
    read_argv(ARG_Reason, reason, charsmax(reason));

    new playerId = FindClientIndexByTarget(id, playerData);
    new banTime = str_to_num(time);

    APS_PunishPlayer(playerId, g_BanTypeId, banTime, reason, "Descriptin: Игрок получил бан", APS_PunisherTypePlayer, id);

    return PLUGIN_HANDLED;
}

FindClientIndexByTarget(const id, const buffer[]) {
    new clientId = find_player_ex(FindPlayer_MatchNameSubstring|FindPlayer_CaseInsensitive, buffer);

    if(clientId) {
        if(clientId != find_player_ex(FindPlayer_MatchNameSubstring|FindPlayer_CaseInsensitive|FindPlayer_LastMatched, buffer)) {
            console_print(id, "* No players found for your request!");
            return NOT_CLIENT;
        }
    } else if(
    	buffer[0] == '#' && buffer[1] &&
    	!(clientId = find_player_ex(FindPlayer_MatchAuthId, buffer)) || 
    	!(clientId = find_player_ex(FindPlayer_MatchIP, buffer))) 
    {
        clientId = find_player_ex(FindPlayer_MatchUserId, str_to_num(buffer[1]));
	} else {
        console_print(id, "* Player with this nickname or userID not found!");
        return NOT_CLIENT;
    }

    return clientId;
}