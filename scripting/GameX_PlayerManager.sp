/**
 * GameX - Player Manager
 * Player Manager for GameX
 * Copyright (C) 2018 CrazyHackGUT aka Kruzya
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

Handle  g_hForward;
float   g_flRetryFrequency;

public Plugin myinfo = {
  description = "Player Manager for GameX",
  version     = "0.0.0.6",
  author      = "CrazyHackGUT aka Kruzya",
  name        = "[GameX] Player Manager",
  url         = GAMEX_HOMEPAGE
};

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iBufferLength) {
  RegPluginLibrary("GameX::PlayerManager");
  g_hForward = CreateGlobalForward("GameX_OnPlayerLoaded", ET_Ignore, Param_Cell, Param_Cell);
}

public void OnAllPluginsLoaded() {
  _GMX_STDDBGINIT()

  g_flRetryFrequency = GameX_GetFloatConfigValue("RetryFrequency", 45.0);
  _GMX_DBGLOG("OnAllPluginsLoaded(): RetryFrequency - %f", g_flRetryFrequency)
}

public Action OnRequestUserInformation(Handle hTimer, int iClient) {
  _GMX_DBGLOG("OnRequestUserInformation(): %d", iClient)

  if ((iClient = GetClientOfUserId(iClient)) != 0) 
    OnClientAuthorized(iClient, NULL_STRING);
  return Plugin_Stop;
}

public void OnClientAuthorized(int iClient, const char[] szAuthID) {
  _GMX_DBGLOG("OnClientAuthorized(): %L (%d, %d)", iClient, IsFakeClient(iClient), GameX_IsReady())
  if (IsFakeClient(iClient))
    return;

  if (!GameX_IsReady())
    return;

  // we retrieve SteamID manually, because szAuthID can contains Community ID, v3 or NULL_STRING
  char szSteamID[32]; 
  GetClientAuthId(iClient, AuthId_Steam2, szSteamID, sizeof(szSteamID));
  szSteamID[6] = '0'; // unify steam (for CS:GO, L4D, L4D2, Alien Swarm and another modes, who uses STEAM_1, STEAM_2 or another)

  // retrieve username
  char szName[128];
  GetClientName(iClient, szName, sizeof(szName));

  // retrieve IP
  char szIP[32];
  GetClientIP(iClient, szIP, sizeof(szIP));

  JSONObject hRequest = new JSONObject();
  hRequest.SetInt("emulator",   0);
  hRequest.SetString("steamid", szSteamID);
  hRequest.SetString("nick",    szName);
  hRequest.SetString("ip",      szIP);

  GameX_DoRequest("player", hRequest, OnGetUserFinished, GetClientUserId(iClient));
  CloseHandle(hRequest);
}

public void OnGetUserFinished(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, int iClient) {
  _GMX_DBGLOG("OnGetUserFinished(): %d (%L); '%s', %d, %x", iClient, GetClientOfUserId(iClient), szError, iStatusCode, hResponse)

  if ((iClient = GetClientOfUserId(iClient)) == 0)
    return; // client disconnected.

  if (szError[0]) {
    LogError("[GameX Player Manager] Can't retrieve data about player %L: %s", iClient, szError);
    CreateTimer(g_flRetryFrequency, OnRequestUserInformation, GetClientUserId(iClient));
    return;
  }

  _OnPlayerLoaded(iClient, hResponse);
}

void _OnPlayerLoaded(int iClient, JSON hResponse) {
  _GMX_DBGLOG("_OnPlayerLoaded(%d, %x)", iClient, hResponse)

  Call_StartForward(g_hForward);
  Call_PushCell(iClient);
  Call_PushCell(hResponse);
  Call_Finish();
}