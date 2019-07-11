#if defined _aps_chat_included
	#endinput
#endif

#define _aps_chat_included

enum (<<=1) {
    APS_Chat_Voice = 1,
    APS_Chat_Text,
}

native APS_ChatGetBlocketType(const player);
native bool:APS_ChatGetBlocketText(const player);
native bool:APS_ChatGetBlocketVoice(const player);
