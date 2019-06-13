void Information_SendStart()
{
    DBGLOG("Information_SendStart()")
    char szCurrentMap[256];
    GetCurrentMap(szCurrentMap, sizeof(szCurrentMap));

    JSONObject hRequest = new JSONObject();
    hRequest.SetString("map", szCurrentMap);
    hRequest.SetInt("max_players", Information_MaxPlayers());

    DBGLOG("Information_SendStart(): Map '%s', MaxPlayers '%d'", szCurrentMap, Information_MaxPlayers())
    GameX_DoRequest("server/info", hRequest, Information_OnStartDelivered);
    CloseHandle(hRequest);
}

void Information_SendPing()
{
    DBGLOG("Information_SendPing()")
    JSONObject hRequest = new JSONObject();
    hRequest.SetInt("num_players", GetClientCount(false));

    DBGLOG("Information_SendPing(): Current players %d", GetClientCount(false))
    GameX_DoRequest("server/ping", hRequest, Information_OnPingDelivered);
    CloseHandle(hRequest);
}

/**
 * @section Callbacks
 */
bool UTIL_Information_IsOk(HTTPStatus iStatusCode, const char[] szError)
{
    DBGLOG("UTIL_Information_IsOk(%d, '%s')", iStatusCode, szError)
    if (szError[0])
    {
        LogError("[GameX] HTTP Request error: %s", szError);
        return false;
    }

    if (iStatusCode == HTTPStatus_Forbidden)
    {
        LogError("[GameX] Bad token. Check your configuration file.");
        return false;
    }

    return true;
}

public void Information_OnStartDelivered(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, any data)
{
    DBGLOG("Information_OnStartDelivered(%d, %x, '%s', %d)", iStatusCode, hResponse, szError, data)
    if (UTIL_Information_IsOk(iStatusCode, szError))
        Information_SendPing();
}

public void Information_OnPingDelivered(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, any data)
{
    DBGLOG("Information_OnPingDelivered(%d, %x, '%s', %d)", iStatusCode, hResponse, szError, data)
    UTIL_Information_IsOk(iStatusCode, szError);

    CreateTimer(60.0, Information_ResendPing);
}

/**
 * @section Timer
 */
public Action Information_ResendPing(Handle hTimer)
{
    Information_SendPing();
}

/**
 * @section Helper functions
 */
static int Information_MaxPlayers()
{
    DBGLOG("Information_MaxPlayers()")
    int iSlots = MaxClients;

    // Setting for respecting max visible players.
    char szValue[4];
    GameX_GetConfigValue("RespectMaxVisiblePlayers", szValue, sizeof(szValue), "0");
    if (szValue[0] != '0')
    {
        DBGLOG("Information_MaxPlayers(): We respect Max visible players. Going to subfunction...")
        int iMaxVisiblePlayers = Information_MaxVisiblePlayers();

        iSlots = (iMaxVisiblePlayers != -1 ? iMaxVisiblePlayers : iSlots);
    }

    return iSlots;
}

static int Information_MaxVisiblePlayers()
{
    static Handle hVisibleMaxPlayers = null;
    static bool bIsSupported = true;

    DBGLOG("Information_MaxVisiblePlayers(): sv_visiblemaxplayers = %x", hVisibleMaxPlayers)
    DBGLOG("Information_MaxVisiblePlayers(): Is feature supported on game? %d", bIsSupported)
    if (!bIsSupported)
    {
        return -1;
    }

    // Initialize convar handle.
    if (hVisibleMaxPlayers == null)
    {
        hVisibleMaxPlayers = FindConVar("sv_visiblemaxplayers");

        // Some games doesn't support `sv_visiblemaxplayers` console variable.
        if (hVisibleMaxPlayers == null)
        {
            DBGLOG("Information_MaxVisiblePlayers(): Game doesn't supported. Disabling feature...")
            bIsSupported = false;
            return -1;
        }
    }

    return GetConVarInt(hVisibleMaxPlayers);
}