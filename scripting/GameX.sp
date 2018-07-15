/**
 * GameX SourceMod API Plugin
 * SourceMod plugin for working with GameX
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
#include <base64>
#include <GameX>

#pragma newdecls  required
#pragma semicolon 1

#define PLUGIN_VERSION  "0.0.0.2"

stock Handle  g_hCorePlugin;

HTTPClient    g_hWebClient;
StringMap     g_hValues;

char          g_szConfiguration[256];

public Plugin myinfo = {
  description = "SourceMod plugin for working with GameX",
  version     = PLUGIN_VERSION,
  author      = "CrazyHackGUT aka Kruzya",
  name        = "[GameX] Core",
  url         = GAMEX_HOMEPAGE
};

public void OnPluginStart() {
  g_hValues = new StringMap();
  BuildPath(Path_SM, g_szConfiguration, sizeof(g_szConfiguration), "configs/GameX/Core.cfg");

  Configuration_Load();

  RegServerCmd("sm_reloadgamex", Cmd_ReloadGameX);
}

public APLRes AskPluginLoad2(Handle hPlugin, bool bLate, char[] szBuffer, int iBufferLength) {
  g_hCorePlugin = hPlugin;
  API_Initialize();
  return APLRes_Success;
}

public Action Cmd_ReloadGameX(int iArgC) {
  Configuration_Load();
  PrintToServer("[GameX] Configuration succesfully reloaded!");
  return Plugin_Handled;
}

public void OnAPICallFinished(HTTPResponse hResponse, DataPack hPack, const char[] szError) {
  hPack.Reset();
  Handle hPlugin = hPack.ReadCell();
  GameXCall pFunction = view_as<GameXCall>(hPack.ReadFunction());
  any data = hPack.ReadCell();
  CloseHandle(hPack);

  if (szError[0]) {
    if (pFunction != INVALID_FUNCTION && IsValidPlugin(hPlugin)) {
      Call_StartFunction(hPlugin, pFunction);
      Call_PushCell(HTTPStatus_Invalid);
      Call_PushCell(INVALID_HANDLE);
      Call_PushString(szError);
      Call_PushCell(data);
      Call_Finish();
    } else {
      LogError("[GameX] Core failed when processing request: %s", szError);
    }

    return;
  }

  if (pFunction == INVALID_FUNCTION || !IsValidPlugin(hPlugin)) {
    return;
  }

  Call_StartFunction(hPlugin, pFunction);
  Call_PushCell(hResponse.Status);
  Call_PushCell(hResponse.Data);
  Call_PushNullString();
  Call_PushCell(data);
  Call_Finish();
}

#include "GameX/Configuration.sp"
#include "GameX/API.sp"

stock bool IsValidPlugin(Handle hPlugin) {
  Handle hIter = GetPluginIterator();
  bool bResult;

  while (MorePlugins(hIter)) {
    if (ReadPlugin(hIter) == hPlugin) {
      bResult = (GetPluginStatus(hPlugin) == Plugin_Running);
      break;
    }
  }

  CloseHandle(hIter);
  return bResult;
}