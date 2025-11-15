/* Sublime AMXX Editor v4.2 */

#include <amxmodx>
#include <reapi>
#include <easy_http>
#include <geoip>

#define PLUGIN  "Dynamic DownloadURL"
#define VERSION "1.0.0"
#define AUTHOR  "Shadows Adi"

// Show what download url was sent to the player through POST hook of RH_SV_SendResources
//#define DEBUG

#define MAX_DOWNLOADURL_SIZE 128

new const DEFAULT_URL[]			=		"DEFAULT_URL"
new const REGION_FASTDL[]		=		"REGION_BASED_FASTDL"
new const DWDURL_STATUS[]		=		"DOWNLOADURL_STATUS"
new const DWDURL_CHECK_TIME[]	=		"DOWNLOADURL_CHECK_INTERVAL"
new const LOG_FILE[]			=		"LOG_FILE"
new const LOG_TYPE[]			=		"LOG_TYPE"

enum
{
	GENERAL_SETTINGS = 1,
	FASTDL_SERVERS
}

enum _:Settings
{
	sDefaultUrl[MAX_DOWNLOADURL_SIZE + 1],
	bool:bRegionBasedUrl,
	bool:bCheckUrlStatus,
	iCheckUrlInterval,
	sLogFileName[64],
	iLogType
}

new g_ePluginSettings[Settings]

new Trie:g_tUrlTrie
new Trie:g_tServerStatus

new g_pCvar
new g_szCvar[64]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_cvar("dyn_dwdurl", AUTHOR, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)
}

public plugin_precache()
{
	server_cmd("exec server.cfg")
	server_exec()

	g_pCvar = get_cvar_pointer("sv_downloadurl")
	get_pcvar_string(g_pCvar, g_szCvar, charsmax(g_szCvar))

	RegisterHookChain(RH_SV_SendResources, "RH_SV_SendResources_Pre")

	#if defined DEBUG
	RegisterHookChain(RH_SV_SendResources, "RH_SV_SendResources_Post", 1)
	#endif

	// Tries have O(1) time complexity
	g_tUrlTrie = TrieCreate()
	g_tServerStatus = TrieCreate()

	ReadConfig()
}

public plugin_end()
{

	TrieDestroy(g_tUrlTrie)
	TrieDestroy(g_tServerStatus)
}

public RH_SV_SendResources_Pre()
{
	new sIP[16], sResult[3], sUrl[MAX_DOWNLOADURL_SIZE + 1], iUrlStatus
	rh_get_net_from(sIP, charsmax(sIP))

	new iPos = contain(sIP, ":")

	if(iPos != -1) 
	{
		sIP[iPos] = EOS
	}

	if(g_ePluginSettings[bRegionBasedUrl])
		geoip_continent_code(sIP, sResult)
	else
		geoip_code2_ex(sIP, sResult)

#if defined DEBUG
	get_pcvar_string(g_pCvar, sUrl, charsmax(sUrl))

	log_to_file(g_ePluginSettings[sLogFileName], "[%s] Before sending to IP %s : %s", PLUGIN, sIP, sUrl)
#endif

	if(TrieKeyExists(g_tUrlTrie, sResult))
	{
		TrieGetString(g_tUrlTrie, sResult, sUrl, charsmax(sUrl))
	}

	if(TrieKeyExists(g_tServerStatus, sUrl))
	{
		TrieGetCell(g_tServerStatus, sUrl, iUrlStatus)
	}

	if(!iUrlStatus)
	{
		if(strlen(g_ePluginSettings[sDefaultUrl]))
		{
			copy(sUrl, charsmax(sUrl), g_ePluginSettings[sDefaultUrl])
		}
		else // fallback if there is no download url in default field
		{
			get_pcvar_string(g_pCvar, sUrl, charsmax(sUrl))
		}
	}

	set_pcvar_string(g_pCvar, sUrl)

	if(g_ePluginSettings[iLogType])
	{
		log_to_file(g_ePluginSettings[sLogFileName], "[%s] Sent to IP %s : %s", PLUGIN, sIP, sUrl)
	}
}

#if defined DEBUG
public RH_SV_SendResources_Post()
{
	new szCvar[128], sIP[16]
	rh_get_net_from(sIP, charsmax(sIP))

	new iPos = contain(sIP, ":")

	if(iPos != -1) 
	{
		sIP[iPos] = EOS
	}

	get_pcvar_string(g_pCvar, szCvar, charsmax(szCvar))

	log_to_file(g_ePluginSettings[sLogFileName], "[%s] Requested from %s : %s", PLUGIN, sIP, szCvar)
}
#endif

ReadConfig()
{
	new szConfigsDir[256], szFileDir[64]
	get_localinfo("amxx_configsdir", szConfigsDir, charsmax(szConfigsDir))

	add(szConfigsDir, charsmax(szConfigsDir), "/dynamic_downloadurl")

	formatex(szFileDir, charsmax(szFileDir), "%s/dynamic_dwdurl.ini", szConfigsDir)

	new iFile = fopen(szFileDir, "rt")

	if(!iFile)
	{
		log_amx("[%s] File %s is missing", PLUGIN, szFileDir)
		return
	}
		
	new szData[(MAX_DOWNLOADURL_SIZE + 1) * 2], iSection, szString[MAX_DOWNLOADURL_SIZE + 1], szValue[MAX_DOWNLOADURL_SIZE + 1]

	while(!feof(iFile))
	{
		fgets(iFile, szData, charsmax(szData))
		trim(szData)
		
		if(szData[0] == '#' || szData[0] == EOS || szData[0] == ';')
			continue

		if(szData[0] == '[')
		{
			iSection += 1
			continue
		}

		switch(iSection)
		{
			case GENERAL_SETTINGS:
			{
				strtok2(szData, szString, charsmax(szString), szValue, charsmax(szValue), '=', TRIM_INNER)

				if(szValue[0] == EOS || !szValue[0])
					continue

				if(equal(szString, DEFAULT_URL))
				{
					copy(g_ePluginSettings[sDefaultUrl], charsmax(g_ePluginSettings[sDefaultUrl]), szValue)
				}
				else if(equal(szString, REGION_FASTDL))
				{
					g_ePluginSettings[bRegionBasedUrl] = bool:clamp(str_to_num(szValue), 0, 1)
				}
				else if(equal(szString, DWDURL_STATUS))
				{
					g_ePluginSettings[bCheckUrlStatus] = bool:clamp(str_to_num(szValue), 0, 1)
				}
				else if(equal(szString, DWDURL_CHECK_TIME))
				{
					g_ePluginSettings[iCheckUrlInterval] = str_to_num(szValue)
				}
				else if(equal(szString, LOG_FILE))
				{
					copy(g_ePluginSettings[sLogFileName], charsmax(g_ePluginSettings[sLogFileName]), szValue)
				}
				else if(equal(szString, LOG_TYPE))
				{
					g_ePluginSettings[iLogType] = str_to_num(szValue)
				}
			}
		}
	}
	fclose(iFile)

	ReadDownloadUrls(szConfigsDir)

	if(g_ePluginSettings[bCheckUrlStatus])
	{
		set_task(1.0, "task_check_dwdurls")
	}
}

public task_check_dwdurls()
{
	new sDownloadURL[MAX_DOWNLOADURL_SIZE + 1]

	new TrieIter:tIterator = TrieIterCreate(g_tUrlTrie)

	while (!TrieIterEnded(tIterator))
	{
		TrieIterGetString(tIterator, sDownloadURL, charsmax(sDownloadURL))

		new EzHttpOptions:httpOptions = ezhttp_create_options()
		ezhttp_option_set_user_agent(httpOptions, "Valve/Steam HTTP Client 1.0 (10)")
		ezhttp_option_set_user_data(httpOptions, sDownloadURL, charsmax(sDownloadURL))

		ezhttp_get(sDownloadURL, "SetDownloadUrlServerStatus", httpOptions)

		TrieIterNext(tIterator)
	}

	TrieIterDestroy(tIterator)

	set_task(float(g_ePluginSettings[iCheckUrlInterval]), "task_check_dwdurls")
}

public SetDownloadUrlServerStatus(EzHttpRequest:httpReqID)
{
	new sDownloadURL[MAX_DOWNLOADURL_SIZE + 1]
	ezhttp_get_user_data(httpReqID, sDownloadURL)
	if(ezhttp_get_http_code(httpReqID) != 200)
	{
		new szError[128]
		ezhttp_get_error_message(httpReqID, szError, charsmax(szError))
		log_to_file(g_ePluginSettings[sLogFileName], "[%s] Download URL Server down: %s", PLUGIN, sDownloadURL)
		TrieSetCell(g_tServerStatus, sDownloadURL, 0)
		return
	}

	TrieSetCell(g_tServerStatus, sDownloadURL, 1)
}

ReadDownloadUrls(szConfigsDir[])
{
	new EzJSON:jsonConfig = ezjson_parse(fmt("%s/dynamic_fastdl.json", szConfigsDir), true, true)

	if(jsonConfig == EzInvalid_JSON)
	{
		log_to_file(g_ePluginSettings[sLogFileName], "[%s] No valid JSON Object loaded. Fallback to %s", PLUGIN, g_ePluginSettings[sDefaultUrl])
		return
	}

	new sDownloadURL[MAX_DOWNLOADURL_SIZE + 1], sLocation[5]
	new iCount = ezjson_object_get_count(jsonConfig)
	if(iCount)
	{
		for(new i = 0, EzJSON:objType, szTemp[2]; i < iCount; i++)
		{
			ezjson_object_get_name(jsonConfig, i, sLocation, charsmax(sLocation))
			strtok2(sLocation, szTemp, charsmax(szTemp), sLocation, charsmax(sLocation), ':')

			if(!g_ePluginSettings[bRegionBasedUrl] && !str_to_num(szTemp)
			   || g_ePluginSettings[bRegionBasedUrl] && str_to_num(szTemp))
				continue

			objType = ezjson_object_get_value_at(jsonConfig, i)

			for(new j = 0; j < ezjson_array_get_count(objType); j++)
			{
				ezjson_array_get_string(objType, j, sDownloadURL, charsmax(sDownloadURL))

				TrieSetString(g_tUrlTrie, sLocation, sDownloadURL)
				TrieSetCell(g_tServerStatus, sDownloadURL, 1)
			}
			ezjson_free(objType)
		}
	}
	ezjson_free(jsonConfig)
}
