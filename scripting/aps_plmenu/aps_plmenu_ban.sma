#include <amxmodx>
#include <aps>
#include <aps_plmenu>

new APS_Type:TypeId;

public plugin_init() {
    register_plugin("[APS] Player Menu Ban", "0.1.0", "GM-X Team");
}

public APS_Inited() {
    TypeId = APS_GetTypeIndex("ban")
    if (TypeId != APS_InvalidType) {
        APS_PlMenu_PushItem("Ban", "HandleAction", true, true);
    }
}

public HandleAction(const admin, const player, const reason[], const time) {
    APS_PunishPlayer(player, TypeId, time, reason, "", admin);
}
