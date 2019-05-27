#include <amxmodx>
//#include <amxmisc>
//#include <PersistentDataStorage>
//#include <reapi>
#include <grip>
#include <gmx>
#include <aps>
//#include <uac>

new const FILE_NAME[] = "aps_settings.json";

/*enum _:Type {
    TypeName[MAX_TYPE_NAME_LEN],
    TypePunishHandler,
    TypeUnPunishHandler,
}

enum PunishmentStatus {
    PunishmentStatusActive,
    PunishmentStatusExpired,
    PunishmentStatusUnpunished,
}

enum _:Punishment {
    PunishmentType,
    PunishmentExpired,
    PunishmentReason[],
    PunishmentComment[],
    PunishmentPunisherType,
    PunishmentPunisher,
}*/

/*const MAX_COMMENT_LENGTH = 64;
const MAX_REASON_LENGTH = 64;
const MAX_INFO_LENGTH = 64;
const MAX_TIME_STRING_LENGTH = 12;*/

enum _:InfoType {
    Name[MAX_PUNISH_NAME_LENGTH],
    Description[MAX_PUNISH_DESC_LENGTH]
};

enum CORE_FORWARDS {
    FW_REGISTERED_TYPE = 0,
    FW_PUNISH_PLAYER_PRE,
    FW_PUNISH_PLAYER_POST,
    FW_CHECK_PLAYER_PRE,
    FW_CHECK_PLAYER_POST,
    FW_UNPUNISH_PLAYER_PRE,
    FW_UNPUNISH_PLAYER_POST
};

new g_Forwards[CORE_FORWARDS];

new Trie:g_JsonData;
new g_ParsingInfo[InfoType];
new g_PunishNums;

public plugin_init() {
    register_plugin("[APS] Core", "0.0.1b", "");

    RegisterCoreForwards();
}    

public plugin_cfg() {
    new filePath[128];
 
    get_localinfo("amxx_configsdir", filePath, charsmax(filePath));
    formatex(filePath, charsmax(filePath), "%s/%s", filePath, FILE_NAME);
 
    if(file_exists(filePath)) {
        new error[128];
        new GripJSONValue:data = grip_json_parse_file(filePath, error, charsmax(error));
 
        if(data != Invalid_GripJSONValue) {
            if(grip_json_get_type(data) != GripJSONArray) {
                grip_destroy_json_value(data);
                set_fail_state("Coudn't open %s. Bad format", filePath);
            }
 
            parseData(data);
            grip_destroy_json_value(data);

            new ret, fwd = CreateMultiForward("APS_Init", ET_IGNORE);
            ExecuteForward(fwd, ret);
            DestroyForward(fwd);
        } else {
            set_fail_state("Coudn't open %s. Error %s", filePath, error);  
        }
    }

    log_amx("g_PunishNums = %d", g_PunishNums);
}
 
parseData(const GripJSONValue:data) {
    g_JsonData = TrieCreate();

    for(new i, n = grip_json_array_get_count(data), GripJSONValue:tmp; i < n; i++) {
        tmp = grip_json_array_get_value(data, i);
 
        if(grip_json_get_type(tmp) == GripJSONObject) {
            arrayset(g_ParsingInfo, 0, sizeof g_ParsingInfo);
 
            grip_json_object_get_string(tmp, "name", g_ParsingInfo[Name], charsmax(g_ParsingInfo[Name]));
            grip_json_object_get_string(tmp, "desc", g_ParsingInfo[Description], charsmax(g_ParsingInfo[Description]));
 
            TrieSetArray(g_JsonData, fmt("punish_%d", i), g_ParsingInfo, sizeof g_ParsingInfo);

            log_amx("i = %d | g_ParsingInfo[Name] = %s | g_ParsingInfo[Description] = %s", i, g_ParsingInfo[Name], g_ParsingInfo[Description]);
        }
 
        grip_destroy_json_value(tmp);
    }
 
    g_PunishNums = TrieGetSize(g_JsonData);
}

RegisterCoreForwards() {
    g_Forwards[FW_REGISTERED_TYPE] = CreateMultiForward("APS_RegisteredType", ET_CONTINUE, FP_STRING, FP_STRING);
    g_Forwards[FW_PUNISH_PLAYER_PRE] = CreateMultiForward("APS_PunishPlayerPre", ET_CONTINUE, FP_CELL, FP_CELL);
    g_Forwards[FW_PUNISH_PLAYER_POST] = CreateMultiForward("APS_PunishPlayerPost", ET_IGNORE, FP_CELL, FP_CELL);
    g_Forwards[FW_CHECK_PLAYER_PRE] = CreateMultiForward("APS_CheckPlayerPre", ET_CONTINUE, FP_CELL);
    g_Forwards[FW_CHECK_PLAYER_POST] = CreateMultiForward("APS_CheckPlayerPost", ET_IGNORE, FP_CELL, FP_CELL);
    g_Forwards[FW_UNPUNISH_PLAYER_PRE] = CreateMultiForward("APS_UnPunishPlayerPre", ET_CONTINUE, FP_CELL, FP_CELL);
    g_Forwards[FW_UNPUNISH_PLAYER_POST] = CreateMultiForward("APS_UnPunishPlayerPost", ET_IGNORE);

    //forward PS_PunishPlayerPre(const id, const type);
    //forward PS_PunishPlayerPost(const id, const type);
    //forward PS_CheckPlayerPre(const id);
    //forward PS_CheckPlayerPost(const id, const bool:is_punished);
    //forward PS_UnPunishPlayerPre(const id, const type);
    //forward PS_UnPunishPlayerPost();    
}

public plugin_natives() {
    register_native("APS_RegisterType", "NativeRegisterType", 0);
    //register_native("APS_GetTypeID", "NativeGetTypeID", 0);
    //register_native("APS_PunishPlayer", "NativePunishPlayer", 0);
    //register_native("APS_UnPunishPlayer", "NativeUnPunishPlayer", 0);
    //register_native("APS_CheckPlayer", "NativeCheckPlayer", 0);
    //register_native("APS_GetPunishmentExpired", "NativeGetPunishmentExpired", 0);
    //register_native("APS_SetPunishmentExpired", "NativeSetPunishmentExpired", 0);
    //register_native("APS_GetPunishmentReason", "NativeGetPunishmentReason", 0);
    //register_native("APS_SetPunishmentReason", "NativeSetPunishmentReason", 0);
    //register_native("APS_GetPunishmentDetails", "NativeGetPunishmentDetails", 0);
    //register_native("APS_SetPunishmentComment", "NativeSetPunishmentComment", 0);  
}

public NativeRegisterType(plugin, params) {
    enum { arg_name = 1, arg_desc };

    new punish_name[MAX_PUNISH_NAME_LENGTH], punish_desc[MAX_PUNISH_DESC_LENGTH], ret;

    get_string(arg_name, punish_name, charsmax(punish_name));
    get_string(arg_desc, punish_desc, charsmax(punish_desc));

    for(new i; i < TrieGetSize(g_JsonData); i++) {
        arrayset(g_ParsingInfo, 0, sizeof g_ParsingInfo);

        TrieGetArray(g_JsonData, fmt("punish_%d", i), g_ParsingInfo, charsmax(g_ParsingInfo));

        if(!g_ParsingInfo[Name][0]) {
            continue;
        }

        if(equali(g_ParsingInfo[Name], punish_name)) {
            ExecuteForward(g_Forwards[FW_REGISTERED_TYPE], ret, punish_name, punish_desc);
            break;
        }

        //if(equali(g_ParsingInfo[Name], punish_name)) {
        //    log_amx("Тип наказаний есть в кэше, вызываем форвард FW_REGISTERED_TYPE");
        //    ExecuteForward(g_Forwards[FW_REGISTERED_TYPE], ret, punish_index, punish_name);

        //    break;
        //} else {
            //GamexMakeRequest("punishment/type", Invalid_GripJSONValue, "OnResponse");
            // отправить реквест на создание и после удачного запроса вызвать форвард
        //}
    }
}

public NativeGetTypeID(plugin, params) {
    // const type[]

}

public NativePunishPlayer(plugin, params) {
    //const id, const type, const expired, const reason[], const comment[]

    /*enum {
        arg_index = 1,
        arg_type,
        arg_expired,
        arg_reason,
        arg_comment
    };*/

    ExecuteForward(g_Forwards[FW_PUNISH_PLAYER_PRE]);


    ExecuteForward(g_Forwards[FW_PUNISH_PLAYER_POST]);
}

public NativeUnPunishPlayer(plugin, params) {
    /*enum {
        arg_index = 1,
        arg_type
    };

    new index = get_param(arg_index);
    new punish_type = get_param(arg_type);*/

    ExecuteForward(g_Forwards[FW_UNPUNISH_PLAYER_PRE]);


    ExecuteForward(g_Forwards[FW_UNPUNISH_PLAYER_POST]);
}

public NativeCheckPlayer(plugin, params) {
    /*enum { arg_index = 1 };

    new index = get_param(arg_index);*/

    ExecuteForward(g_Forwards[FW_CHECK_PLAYER_PRE]);


    ExecuteForward(g_Forwards[FW_CHECK_PLAYER_POST]);
}

public NativeGetPunishmentExpired(plugin, params) {

}

public NativeSetPunishmentExpired(plugin, params) {
   /* enum { arg_expired = 1 };

    new expired = get_param(arg_expired);*/
}

public NativeGetPunishmentReason(plugin, params) {
    /*enum {
        arg_reason = 1,
        arg_len 
    };

    new reason[MAX_REASON_LENGTH];

    set_string(arg_reason, reason, get_param(arg_len));

    return reason;*/
}

public NativeSetPunishmentReason(plugin, params) {
    // const comment[]
}

/*
    Получение детальной причины бана
    использовать в APS_PunishPlayerPre
*/
public NativeGetPunishmentDetails(plugin, params) {
    /*enum { arg_comment = 1 };
    
    new comment[MAX_COMMENT_LENGTH];

    set_string(arg_comment, comment, charsmax(comment));

    return comment;*/
}

public NativeSetPunishmentComment(plugin, params) {
    // const comment[]
}
