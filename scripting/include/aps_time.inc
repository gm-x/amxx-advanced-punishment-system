#if defined _aps_time_included
	#endinput
#endif
#define _aps_time_included

enum _:APS_TIME_ELEMENT {
	APS_TIME_ELEMENT_SECONDS,
	APS_TIME_ELEMENT_TITLE[64]
};

new const APS_TIME_ELEMENTS[][APS_TIME_ELEMENT] = {
	{ 60, "APS_TIME_ELEMENT_MINUTES" },
	{ 3600, "APS_TIME_ELEMENT_HOURS" },
	{ 86400, "APS_TIME_ELEMENT_DAYS" },
	{ 604800, "APS_TIME_ELEMENT_WEEKS" },
	{ 2592000, "APS_TIME_ELEMENT_MONTHS" },
	{ 31104000, "APS_TIME_ELEMENT_YEARS" },
};

stock aps_get_time_length(const id, const unitCnt, output[], const outputLen, const everKey[] = "APS_TIME_ELEMENT_PERMANENTLY")
{
	SetGlobalTransTarget(id);
	if (unitCnt <= 0) {
		return formatex(output, outputLen, "%l", everKey);
	}

	new secondCnt = unitCnt, count, element = sizeof APS_TIME_ELEMENTS - 1, len = 0;
	do {
		count = secondCnt / APS_TIME_ELEMENTS[element][APS_TIME_ELEMENT_SECONDS];
		secondCnt -= (count * APS_TIME_ELEMENTS[element][APS_TIME_ELEMENT_SECONDS]);
		if (count <= 0) {
			element--;
			continue;
		}

		if (secondCnt > 0 || len == 0) {
			len += formatex(output[len], outputLen - len, len > 0 ? " %d %l" : "%d %l", count, APS_TIME_ELEMENTS[element][APS_TIME_ELEMENT_TITLE]);
		} else {
			len += formatex(output[len], outputLen - len, " %l %d %l", "APS_TIME_ELEMENT_AND", count, APS_TIME_ELEMENTS[element][APS_TIME_ELEMENT_TITLE]);
		}
		element--;
		
	} while (secondCnt > 0 && element >= 0);

	if (secondCnt > 0) {
		if (len > 0) {
			len += formatex(output[len], outputLen - len, " %l %d %l", "APS_TIME_ELEMENT_AND", secondCnt, "APS_TIME_ELEMENT_SECONDS");
		} else {
			len += formatex(output[len], outputLen - len, "%d %l", secondCnt, "APS_TIME_ELEMENT_SECONDS");
		}
	}

	return len;
}