#include <amxmodx>
#include <aps>
#include <aps_plmenu>

new APS_Type:TypeId;

public plugin_init() {
    register_plugin("[APS] Player Menu Chat", "0.1.0", "GM-X Team");
}

public APP_Inited() {
    TypeId = APS_GetTypeIndex("chat")
    if (TypeId != APS_InvalidType) {
        APS_PlMenu_PushItem("Chat", "HandleAction", true, true);
    }
}

public HandleAction(const admin, const player, const reason[], const time) {
    APS_PunishPlayer(player, TypeId, time, reason, "", admin);
}
