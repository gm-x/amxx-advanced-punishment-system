#if defined _aps_chat_included
	#endinput
#endif

#define _aps_chat_included

enum (<<=1) {
	APS_Chat_Voice = 1,
	APS_Chat_Text,
}

native APS_ChatGetBlockedType(const player);
native bool:APS_ChatGetBlockedText(const player);
native bool:APS_ChatGetBlockedVoice(const player);
