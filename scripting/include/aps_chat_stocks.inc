#if defined _aps_chat_stocks_included
	#endinput
#endif

#define _aps_chat_stocks_included

#include <celltrie>
#include <file>

stock Trie:APS_TextIgnoreList = Invalid_Trie;

stock APS_TextIgnoreListInit() {
	APS_TextIgnoreList = TrieCreate();
}

stock APS_TextIgnoreListDestroy() {
	if (APS_TextIgnoreList != Invalid_Trie) {
		TrieDestroy(APS_TextIgnoreList);
	}
}

stock bool:APS_TextIgnoreListPush(const message[]) {
	if (APS_TextIgnoreList == Invalid_Trie) {
		log_error(AMX_ERR_NONE, "Text ignore list not inited");
		return false;
	}
	TrieSetCell(APS_TextIgnoreList, message, 1);
	return true;
}

stock bool:APS_TextIgnoreListCheck(const message[]) {
	if (APS_TextIgnoreList == Invalid_Trie) {
		log_error(AMX_ERR_NONE, "Text ignore list not inited");
		return false;
	}
	return TrieKeyExists(APS_TextIgnoreList, message);
}

stock bool:APS_TextIgnoreListLoad(const path[]) {
	if (APS_TextIgnoreList == Invalid_Trie) {
		log_error(AMX_ERR_NONE, "Text ignore list not inited");
		return false;
	}

	new file = fopen(path, "rt");
	if (!file) {
		log_error(AMX_ERR_NONE, "Can't open file %s", path);
		return false;
	}

	new line[128], semicolon;
	while (!feof(file)) {
		fgets(file, line, charsmax(line));
		
		semicolon = contain(line, ";");
		if (semicolon >= 0) {
			line[semicolon] = EOS;
		}
		trim(line);
		if (line[0] == EOS) {
			continue;
		}
		
		APS_TextIgnoreListPush(line);
	}
	
	fclose(file);
	return true;
}
