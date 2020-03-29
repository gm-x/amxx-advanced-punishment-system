#if defined _aps_plmenu_included
    #endinput
#endif
#define _aps_plmenu_included

enum APS_PlMenu_Item {
	APS_PlMenu_InvalidItem = -1,
};

enum APS_PlMenu_Handler {
	APS_PlMenu_Handler_Default = -2,
	APS_PlMenu_Handler_Invaild = -1,
};

forward APS_PlMenu_Inited();
forward APS_PlMenu_CheckAccess(const player, const target, const APS_PlMenu_Item:item);

// handler(const admin, const player, const reason[], const itme, const extra)
stock APS_PlMenu_Handler:APS_PlMenu_CreateHandler(const handler[]) {
    return APS_PlMenu_Handler:CreateOneForward(get_plugin(-1), handler, FP_CELL, FP_CELL, FP_STRING, FP_CELL, FP_CELL);
}

stock APS_PlMenu_DestroyHandler(APS_PlMenu_Handler:handler) {
	if (handler >= 0) {
		DestroyForward(handler);
	}
}

stock APS_PlMenu_Item:APS_PlMenu_Add(
	const APS_Type:type, const title[], 
	const APS_PlMenu_Handler:handler = APS_PlMenu_Handler_Default, 
	const APS_PlMenu_Handler:resonHandler = APS_PlMenu_Handler_Default, 
	const APS_PlMenu_Handler:timeHandler = APS_PlMenu_Handler_Default, 
	const APS_PlMenu_Handler:extraHandler = APS_PlMenu_Handler_Invaild,
	const bool:needConfirm = true
) {
	new pluginID = APS_PlMenu_GetPluginID();
	if (pluginID == -1) {
		return APS_PlMenu_InvalidItem;
	}
	new func = get_func_id("APS_PlMenu_Add", pluginID);
	if (func == -1) {
		return APS_PlMenu_InvalidItem;
	}
	
	if (callfunc_begin_i(func, pluginID) != 1) {
		return APS_PlMenu_InvalidItem;
	}
	callfunc_push_int(_:type);
	callfunc_push_str(title);
	callfunc_push_int(_:handler);
	callfunc_push_int(_:resonHandler);
	callfunc_push_int(_:timeHandler);
	callfunc_push_int(_:extraHandler);
	callfunc_push_int(_:needConfirm);
	return APS_PlMenu_Item:callfunc_end();
}

stock bool:APS_PlMenu_NextStep(const admin, const value) {
	new pluginID = APS_PlMenu_GetPluginID();
	if (pluginID == -1) {
		return false;
	}
	new func = get_func_id("APS_PlMenu_NextStep", pluginID);
	if (func == -1) {
		return false;
	}
	
	if (callfunc_begin_i(func, pluginID) != 1) {
		return false;
	}
	callfunc_push_int(admin);
	callfunc_push_int(value);
	callfunc_end();
	
	return true;
}

stock bool:APS_PlMenu_PrevStep(const admin) {
	new pluginID = APS_PlMenu_GetPluginID();
	if (pluginID == -1) {
		return false;
	}
	new func = get_func_id("APS_PlMenu_PrevStep", pluginID);
	if (func == -1) {
		return false;
	}
	
	if (callfunc_begin_i(func, pluginID) != 1) {
		return false;
	}
	callfunc_push_int(admin);
	callfunc_end();
	
	return true;
}

stock APS_PlMenu_GetPlayer(const admin) {
	new pluginID = APS_PlMenu_GetPluginID();
	if (pluginID == -1) {
		return -1;
	}
	new func = get_func_id("APS_PlMenu_GetPlayer", pluginID);
	if (func == -1) {
		return -1;
	}
	
	if (callfunc_begin_i(func, pluginID) != 1) {
		return -1;
	}
	callfunc_push_int(admin);
	return callfunc_end();
}

stock bool:APS_PlMenu_Show(const admin, const player = 0, const APS_PlMenu_Item:item = APS_PlMenu_InvalidItem, const reason = -1, const time = -1, const extra = 0) {
	new pluginID = APS_PlMenu_GetPluginID();
	if (pluginID == -1) {
		return false;
	}
	new func = get_func_id("APS_PlMenu_Show", pluginID);
	if (func == -1) {
		return false;
	}
	
	if (callfunc_begin_i(func, pluginID) != 1) {
		return false;
	}
	callfunc_push_int(admin);
	callfunc_push_int(player);
	callfunc_push_int(_:item);
	callfunc_push_int(reason);
	callfunc_push_int(time);
	callfunc_push_int(extra);
	return bool:callfunc_end();
}

stock APS_PlMenu_GetPluginID() {
	static pluginID = -1;
	if (pluginID == -1) {
		new plugin = get_plugin(-1);
		
		for(new i, n = get_pluginsnum(), status[2], func; i < n; i++) {
			if (plugin == i) {
				continue;
			}
			
			get_plugin(i, .status = status, .len5 = charsmax(status));

			//status debug || status running
			if (status[0] != 'd' && status[0] != 'r') {
				continue;
			}
		
			func = get_func_id("APS_PlMenu_Main", i);

			if (func != -1) {
				pluginID = i;
				break;
			}
		}
	}
	
	return pluginID;
}
