/**
 * GameX - Server Information
 * Updates information about server in GameX database with API.
 * Copyright (C) 2019 CrazyHackGUT aka Kruzya
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see http://www.gnu.org/licenses/
 */

#include <sourcemod>

#define _GAMEX_PLAYERMANAGER
#include <GameX>

#pragma newdecls  required
#pragma semicolon 1

public Plugin myinfo = {
    description = "Updates information about server in GameX database with API.",
    version     = "0.0.0.1",
    author      = "CrazyHackGUT aka Kruzya",
    name        = "[GameX] Server Information",
    url         = GAMEX_HOMEPAGE
};

public void OnPluginStart()
{
    _GMX_STDDBGINIT()
    _GMX_DBGLOG("OnPluginStart()")
}

public void GameX_OnReload()
{
    _GMX_DBGLOG("GameX_OnReload()")
    Information_SendStart();
}

public void OnMapStart()
{
    _GMX_DBGLOG("OnMapStart()")
    Information_SendStart();
}

void Information_SendStart()
{
    _GMX_DBGLOG("Information_SendStart()")
    char szCurrentMap[256];
    GetCurrentMap(szCurrentMap, sizeof(szCurrentMap));

    JSONObject hRequest = new JSONObject();
    hRequest.SetString("map", szCurrentMap);
    hRequest.SetInt("max_players", Information_MaxPlayers());

    _GMX_DBGLOG("Information_SendStart(): Map '%s', MaxPlayers '%d'", szCurrentMap, Information_MaxPlayers())
    GameX_DoRequest("server/info", hRequest, Information_OnStartDelivered);
    CloseHandle(hRequest);
}

void Information_SendPing()
{
    _GMX_DBGLOG("Information_SendPing()")
    JSONObject hRequest = new JSONObject();
    JSONArray hSessions = new JSONArray();
    UTIL_FillBySessions(hSessions);
    hRequest.SetInt("num_players", GetClientCount(false));
    hRequest.Set("sessions", hSessions);

    _GMX_DBGLOG("Information_SendPing(): Current players %d", GetClientCount(false))
    GameX_DoRequest("server/ping", hRequest, Information_OnPingDelivered);
    CloseHandle(hSessions);
    CloseHandle(hRequest);
}

/**
 * @section Callbacks
 */
bool UTIL_Information_IsOk(HTTPStatus iStatusCode, const char[] szError)
{
    _GMX_DBGLOG("UTIL_Information_IsOk(%d, '%s')", iStatusCode, szError)
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
    _GMX_DBGLOG("Information_OnStartDelivered(%d, %x, '%s', %d)", iStatusCode, hResponse, szError, data)
    if (UTIL_Information_IsOk(iStatusCode, szError))
        Information_SendPing();
}

public void Information_OnPingDelivered(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, any data)
{
    _GMX_DBGLOG("Information_OnPingDelivered(%d, %x, '%s', %d)", iStatusCode, hResponse, szError, data)
    UTIL_Information_IsOk(iStatusCode, szError);

    CreateTimer(45.0, Information_ResendPing);
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
    _GMX_DBGLOG("Information_MaxPlayers()")
    int iSlots = MaxClients;

    // Setting for respecting max visible players.
    if (GameX_GetBoolConfigValue("RespectMaxVisiblePlayers"))
    {
        _GMX_DBGLOG("Information_MaxPlayers(): We respect Max visible players. Going to subfunction...")
        int iMaxVisiblePlayers = Information_MaxVisiblePlayers();

        iSlots = (iMaxVisiblePlayers != -1 ? iMaxVisiblePlayers : iSlots);
    }

    return iSlots;
}

static int Information_MaxVisiblePlayers()
{
    static Handle hVisibleMaxPlayers = null;
    static bool bIsSupported = true;

    _GMX_DBGLOG("Information_MaxVisiblePlayers(): sv_visiblemaxplayers = %x", hVisibleMaxPlayers)
    _GMX_DBGLOG("Information_MaxVisiblePlayers(): Is feature supported on game? %d", bIsSupported)
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
            _GMX_DBGLOG("Information_MaxVisiblePlayers(): Game doesn't supported. Disabling feature...")
            bIsSupported = false;
            return -1;
        }
    }

    return GetConVarInt(hVisibleMaxPlayers);
}

void UTIL_FillBySessions(JSONArray hArray)
{
    _GMX_DBGLOG("UTIL_FillBySessions(): %x", hArray)

    int iSessionId = 0;
    for (int iClient = MaxClients; iClient != 0; --iClient)
    {
        if (IsClientInGame(iClient) && !IsFakeClient(iClient))
        {
            iSessionId = GameX_GetClientSessionId(iClient);
            _GMX_DBGLOG("UTIL_FillBySessions(): %L -> %d", iClient, iSessionId)
            if (iSessionId == -1)
            {
                continue;
            }

            hArray.PushInt(iSessionId);
        }
    }
}