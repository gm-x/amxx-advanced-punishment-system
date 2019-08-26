#if defined _aps_plmenu_included
    #endinput
#endif
#define _aps_plmenu_included

enum APS_PlMenu_Handler {
	APS_PlMenu_Handler_Default = -2,
	APS_PlMenu_Handler_Invaild = -1,
};

forward APS_PlMenu_Inited();

// handler(const admin, const player, const reason[], const itme, const extra)
stock APS_PlMenu_Handler:APS_PlMenu_CreateHandler(const handler[]) {
    return APS_PlMenu_Handler:CreateOneForward(get_plugin(-1), handler, FP_CELL, FP_CELL, FP_STRING, FP_CELL, FP_CELL);
}

stock APS_PlMenu_DestroyHandler(APS_PlMenu_Handler:handler) {
	if (handler >= 0) {
		DestroyForward(handler);
	}
}

stock bool:APS_PlMenu_Add(
	const type[], const title[], 
	const APS_PlMenu_Handler:handler = APS_PlMenu_Handler_Default, 
	const APS_PlMenu_Handler:resonHandler = APS_PlMenu_Handler_Default, 
	const APS_PlMenu_Handler:timeHandler = APS_PlMenu_Handler_Default, 
	const APS_PlMenu_Handler:extraHandler = APS_PlMenu_Handler_Invaild,
	const bool:needConfirm = true
) {
	new pluginID = APS_GetPluginID();
	if (pluginID == -1) {
		return false;
	}
	new func = get_func_id("APS_PlMenu_Add", pluginID);
	if (func == -1) {
		return false;
	}
	
	if (callfunc_begin_i(func, pluginID) != 1) {
		return false;
	}
	callfunc_push_str(type);
	callfunc_push_str(title);
	callfunc_push_int(_:handler);
	callfunc_push_int(_:resonHandler);
	callfunc_push_int(_:timeHandler);
	callfunc_push_int(_:extraHandler);
	callfunc_push_int(_:needConfirm);
	callfunc_end();
	
	return true;
}

stock bool:APS_PlMenu_NextStep(const admin, const value) {
	new pluginID = APS_GetPluginID();
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
	new pluginID = APS_GetPluginID();
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
	new pluginID = APS_GetPluginID();
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

stock APS_GetPluginID() {
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
