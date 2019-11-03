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

#define _GAMEX_MACRO_API
#define _GAMEX_PLAYERMANAGER
#include <GameX>

#pragma newdecls  required
#pragma semicolon 1

Handle  g_hForward;
float   g_flRetryFrequency;

/**
 * First:  user id.
 * Second: session id.
 * Third:  gamex id.
 *
 * So, array size always multiple 3.
 */
#define _GAMEX_USERID     0 // u
#define _GAMEX_SESSIONID  1 // s
#define _GAMEX_PLAYERID   2 // p

ArrayList g_hSessions;
bool      g_bLate;

#define _JSONObject(%0)  (view_as<JSONObject>(%0))
#define _JSONArray(%0)   (view_as<JSONArray>(%0))

public Plugin myinfo = {
  description = "Player Manager for GameX",
  version     = "0.0.0.8",
  author      = "CrazyHackGUT aka Kruzya",
  name        = "[GameX] Player Manager",
  url         = GAMEX_HOMEPAGE
};

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iBufferLength) {
  g_hForward = CreateGlobalForward("GameX_OnPlayerLoaded", ET_Ignore, Param_Cell, Param_Cell);
  GMX_AddNative(GetClientSessionId);
  g_bLate = bLate;

  RegPluginLibrary("GameX::PlayerManager");
}

public void OnPluginStart()
{
  _GMX_STDDBGINIT()

  g_hSessions = new ArrayList(ByteCountToCells(4));
  _GMX_DBGLOG("OnPluginStart(): %x", g_hSessions)
  if (g_bLate)
    for (int iClient = MaxClients; iClient != 0; --iClient)
      if (IsClientInGame(iClient) && IsClientAuthorized(iClient))
        UTIL_ConnectClient(iClient);

  RegConsoleCmd("gmx_assign", Cmd_Assign, "Assigns the player account to user on site");
  LoadTranslations("gamex_common.phrases");
  LoadTranslations("gamex_pm.phrases");
}

public void GameX_OnReload()
{
  _GMX_DBGLOG("GameX_OnReload()")

  g_flRetryFrequency = GameX_GetFloatConfigValue("RetryFrequency", 45.0);
  g_hSessions.Clear();

  _GMX_DBGLOG("GameX_OnReload(): RetryFrequency - %f", g_flRetryFrequency)
}

public void OnAllPluginsLoaded()
{
  _GMX_DBGLOG("OnAllPluginsLoaded()")
  GameX_OnReload();
}

public Action OnRequestUserInformation(Handle hTimer, int iClient) {
  _GMX_DBGLOG("OnRequestUserInformation(): %d", iClient)

  if ((iClient = GetClientOfUserId(iClient)) != 0) 
    OnClientAuthorized(iClient, NULL_STRING);
  return Plugin_Stop;
}

public void OnClientPutInServer(int iClient)
{
  _GMX_DBGLOG("OnClientPutInServer(): %L", iClient)
  if (!IsClientAuthorized(iClient))
  {
    return;
  }

  UTIL_ConnectClient(iClient);
}

public void OnClientAuthorized(int iClient, const char[] szAuthID) {
  _GMX_DBGLOG("OnClientAuthorized(): %L", iClient)
  if (!IsClientInGame(iClient))
  {
    return;
  }

  UTIL_ConnectClient(iClient);
}

void UTIL_ConnectClient(int iClient)
{
  _GMX_DBGLOG("UTIL_ConnectClient(): %L (%d %d)", iClient, IsFakeClient(iClient), GameX_IsReady())
  if (IsFakeClient(iClient))
  {
    return;
  }

  if (!GameX_IsReady())
  {
    return;
  }

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

  int iSessionId = UTIL_GetSessionIdByClient(iClient);
  if (iSessionId != -1)
  {
    int iId = UTIL_GetGMXIdBySessionId(iSessionId);
    hRequest.SetInt("id", iId);
    hRequest.SetInt("session_id", iSessionId);
  }

  GameX_DoRequest("player/connect", hRequest, OnGetUserFinished, GetClientUserId(iClient));

  CloseHandle(hRequest);
}

void UTIL_DisconnectClient(int iClient)
{
  _GMX_DBGLOG("UTIL_ConnectClient(): %L (%d)", iClient, IsFakeClient(iClient))
  if (IsFakeClient(iClient))
  {
    return;
  }

  int iSessionId = UTIL_GetSessionIdByClient(iClient);
  if (iSessionId == -1)
  {
    // client is not authorized.
    return;
  }

  UTIL_DisconnectSession(iSessionId);
}

void UTIL_DisconnectSession(int iSessionId)
{
  _GMX_DBGLOG("UTIL_DisconnectSession(): %d (%d)", iSessionId, GameX_IsReady())
  if (!GameX_IsReady())
  {
    return;
  }

  JSONObject hRequest = new JSONObject();
  hRequest.SetInt("session_id", iSessionId);
  GameX_DoRequest("player/disconnect", hRequest);
  hRequest.Close();
}

public void OnGetUserFinished(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, int iClient) {
  _GMX_DBGLOG("OnGetUserFinished(): %d (%L); '%s', %d, %x", iClient, GetClientOfUserId(iClient), szError, iStatusCode, hResponse)

  if ((iClient = GetClientOfUserId(iClient)) == 0)
  {
    // client disconnected.
    if (!szError[0] || iStatusCode == HTTPStatus_OK)
    {
      // Close session.
      UTIL_DisconnectSession(_JSONObject(hResponse).GetInt("session_id"));
    }

    return;
  }

  if (szError[0]) {
    LogError("[GameX Player Manager] Can't retrieve data about player %L: %s", iClient, szError);
    CreateTimer(g_flRetryFrequency, OnRequestUserInformation, GetClientUserId(iClient));
    return;
  }

  if (iStatusCode != HTTPStatus_OK)
  {
    LogError("[GameX Player Manager] Can't retrieve data about player %L: invalid HTTP status code (%d)", iClient, iStatusCode);
    CreateTimer(g_flRetryFrequency, OnRequestUserInformation, GetClientUserId(iClient));
    return;
  }

  _OnPlayerLoaded(iClient, hResponse);
}

void _OnPlayerLoaded(int iClient, JSON hResponse) {
  _GMX_DBGLOG("_OnPlayerLoaded(%d, %x)", iClient, hResponse)

  // Write new session to our storage, if doesn't exists.
  int iSessionId = _JSONObject(hResponse).GetInt("session_id");
  int iGameXId   = _JSONObject(hResponse).GetInt("player_id");
  UTIL_WriteSessionForClient(iClient, iSessionId, iGameXId);

  Call_StartForward(g_hForward);
  Call_PushCell(iClient);
  Call_PushCell(hResponse);
  Call_Finish();
}

public void OnClientDisconnect(int iClient)
{
  _GMX_DBGLOG("OnClientDisconnect(): %L", iClient)

  UTIL_DisconnectClient(iClient);
}

GMX_NativeCall(GetClientSessionId)
{
  int iClient = GetNativeCell(1);
  if (iClient < 0 || iClient > MaxClients)
  {
    GMX_InterruptCall("Invalid client id (%d)", iClient);
  }

  if (!IsClientConnected(iClient))
  {
    GMX_InterruptCall("Client is not connected (%d)", iClient);
  }

  return UTIL_GetSessionIdByClient(iClient);
}

stock int UTIL_GetSessionIdByClient(int iClient)
{
  _GMX_DBGLOG("UTIL_GetSessionIdByClient(): %L", iClient)
  return UTIL_GetSessionIdByUserId(GetClientUserId(iClient));
}

stock int UTIL_GetSessionIdByUserId(int iUserId)
{
  _GMX_DBGLOG("UTIL_GetSessionIdByUserId(): %d", iUserId)
  return UTIL_GetArrayValueByValDiff(g_hSessions, iUserId, _GAMEX_USERID, -1, 1);
}

stock int UTIL_GetGMXIdByClient(int iClient)
{
  _GMX_DBGLOG("UTIL_GetGMXIdByClient(): %L", iClient)
  return UTIL_GetGMXIdByUserId(GetClientUserId(iClient));
}

stock int UTIL_GetGMXIdByUserId(int iUserId)
{
  _GMX_DBGLOG("UTIL_GetGMXIdByUserId(): %d", iUserId)
  return UTIL_GetArrayValueByValDiff(g_hSessions, iUserId, _GAMEX_USERID, -1, 2);
}

stock int UTIL_GetGMXIdBySessionId(int iSession)
{
  _GMX_DBGLOG("UTIL_GetGMXIdBySessionId(): %d", iSession)
  return UTIL_GetArrayValueByValDiff(g_hSessions, iSession, _GAMEX_SESSIONID, -1, 1);
}

stock int UTIL_GetUserIdByGMXId(int iGameXId)
{
  _GMX_DBGLOG("UTIL_GetUserIdByGMXId(): %d", iGameXId)
  return UTIL_GetArrayValueByValDiff(g_hSessions, iGameXId, _GAMEX_PLAYERID, 0, -2);
}

stock int UTIL_GetUserIdBySessionId(int iSession)
{
  _GMX_DBGLOG("UTIL_GetUserIdBySessionId(): %d", iSession)
  return UTIL_GetArrayValueByValDiff(g_hSessions, iSession, _GAMEX_SESSIONID, 0, -1);
}

stock void UTIL_WriteSessionForClient(int iClient, int iSessionId, int iPlayerId)
{
  _GMX_DBGLOG("UTIL_WriteSessionForClient(): %L %d %d", iClient, iSessionId, iPlayerId)
  UTIL_WriteSession(GetClientUserId(iClient), iSessionId, iPlayerId);
}

stock void UTIL_WriteSession(int iUserId, int iSessionId, int iPlayerId)
{
  _GMX_DBGLOG("UTIL_WriteSession(): %d %d %d", iUserId, iSessionId, iPlayerId)

  // First, check session existing in our cache.
  if (UTIL_GetUserIdBySessionId(iSessionId) != 0)
  {
    return;
  }

  // Now write.
  char szData[16];

  FormatEx(szData, sizeof(szData), "u%d", iUserId);
  g_hSessions.PushString(szData);

  FormatEx(szData, sizeof(szData), "s%d", iSessionId);
  g_hSessions.PushString(szData);

  FormatEx(szData, sizeof(szData), "p%d", iPlayerId);
  g_hSessions.PushString(szData);
}

stock void UTIL_SetPlayerIdBySessionId(int iSessionId, int iPlayerId)
{
  _GMX_DBGLOG("UTIL_SetPlayerIdBySessionId(): %d", iSessionId)

  char szData[16];
  FormatEx(szData, sizeof(szData), "s%d", iSessionId);
  int iId = g_hSessions.FindString(szData);
  if (iId == -1)
  {
    return;
  }

  FormatEx(szData, sizeof(szData), "u%d", iPlayerId);
  g_hSessions.SetString(iId + 1, szData);
}

stock int UTIL_GetArrayValueByValDiff(ArrayList hList, any iSearchableValue, int iValueType, any iDefaultValue = 0, int iOffset = 0)
{
  _GMX_DBGLOG("UTIL_GetArrayValueByValDiff(): %x -> %d (%d) %d", hList, iSearchableValue, iValueType, iOffset)

  char szData[16];
  IntToString(iSearchableValue, szData[1], sizeof(szData)-1);
  switch (iValueType)
  {
    case _GAMEX_SESSIONID:  szData[0] = 's';
    case _GAMEX_PLAYERID:   szData[0] = 'p';
    case _GAMEX_USERID:     szData[0] = 'u';
  }

  int iPos = hList.FindString(szData);
  if (iPos == -1)
  {
    return iDefaultValue;
  }

  hList.GetString(iPos + iOffset, szData, sizeof(szData));
  return StringToInt(szData[1]);
}

/**
 * Assigning
 */
public Action Cmd_Assign(int iClient, int iArgC)
{
  _GMX_DBGLOG("Cmd_Assign() -> %L %d", iClient, iArgC)
  if (!iClient)
  {
    ReplyToCommand(iClient, "%t%t", GMX_CHATPREFIX, "GameX.Common.InGame");
    return Plugin_Handled;
  }

  if (iArgC != 1)
  {
    ReplyToCommand(iClient, "%t%t", GMX_CHATPREFIX, "GameX.PM.AssignUsage");
    return Plugin_Handled;
  }

  int iUser = UTIL_GetGMXIdByClient(iClient);
  if (iUser == -1)
  {
    ReplyToCommand(iClient, "%t%t %t", GMX_CHATPREFIX, "GameX.Common.DataIsNotReady", "GameX.Common.PleaseTryAgain");
    return Plugin_Handled;
  }

  char szToken[64];
  GetCmdArg(1, szToken, sizeof(szToken));

  JSONObject hRequest = new JSONObject();
  hRequest.SetInt("id", iUser);
  hRequest.SetString("token", szToken);

  GameX_DoRequest("player/assign", hRequest, OnAssignUserFinished, GetClientUserId(iClient));
  hRequest.Close();

  return Plugin_Handled;
}

public void OnAssignUserFinished(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, int iClient)
{
  _GMX_DBGLOG("OnAssignUserFinished(): %d (%L); '%s', %d, %x", iClient, GetClientOfUserId(iClient), szError, iStatusCode, hResponse)

  if ((iClient = GetClientOfUserId(iClient)) == 0)
  {
    return;
  }

  if (szError[0]) {
    LogError("[GameX Player Manager] Can't assign user account to %L: %s", iClient, szError);
    ReplyAssignResult(iClient, false);
    return;
  }

  if (iStatusCode != HTTPStatus_OK)
  {
    LogError("[GameX Player Manager] Can't assign user account to %L: invalid HTTP status code (%d)", iClient, iStatusCode);
    ReplyAssignResult(iClient, false);
    return;
  }

  ReplyAssignResult(iClient, true);
  int iSessionId = UTIL_GetSessionIdByClient(iClient);
  if (iSessionId == -1)
  {
    return; // it looks like user doesn't loaded too.
  }

  UTIL_SetPlayerIdBySessionId(iSessionId, _JSONObject(hResponse).GetInt("user_id"));
}

void ReplyAssignResult(int iClient, bool bSuccess)
{
  char szPhraseName[28];
  FormatEx(szPhraseName, sizeof(szPhraseName), "GameX.PM.AssignResult_%c", bSuccess ? 'Y' : 'N');

  PrintToChat(iClient, "%t%t", GMX_CHATPREFIX, szPhraseName);
}