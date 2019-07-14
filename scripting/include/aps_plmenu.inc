#if defined _aps_plmenu_included
    #endinput
#endif
#define _aps_plmenu_included

stock APS_PlMenu_PushType(const title[], const handler[], const bool:reason = false, const time = false, const confirm = false) {
    new pluginID = get_plugin(-1);
    new fwd = CreateOneForward(pluginID, handler, FP_CELL, FP_CELL, FP_STRING, FP_CELL);

    for(new i, n = get_pluginsnum(), status[2], func; i < n; i++) {
		get_plugin(i, .status = status, .len5 = charsmax(status));

		//status debug || status running
		if(status[0] != 'd' && status[0] != 'r') {
			continue;
		}
	
		func = get_func_id("APS_PlMenu_PushType_Handler", i);

		if(func == -1) {
			continue;
		}

		if(callfunc_begin_i(func, i) == 1) {
			callfunc_push_str(title);
			callfunc_push_int(fwd);
			callfunc_push_int(_:reason);
			callfunc_push_int(_:time);
			callfunc_push_int(_:confirm);
			callfunc_end();
		}
    }
}
