/**
 * GameX - Admin Loader
 * Admin Loader for GameX
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

#define _GAMEX_ADMINLOADER
#include <GameX>

#pragma newdecls  required
#pragma semicolon 1

bool    g_bIsLoading;
bool    g_bMarkAsPost[MAXPLAYERS+1];
char    g_szCacheFile[PLATFORM_MAX_PATH];

#define JSONObject(%0)  (view_as<JSONObject>(%0))
#define JSONArray(%0)   (view_as<JSONArray>(%0))

public Plugin myinfo = {
    description = "Admin Loader for GameX",
    version     = "0.0.0.1 alpha",
    author      = "CrazyHackGUT aka Kruzya",
    name        = "[GameX] Admin Loader",
    url         = GAMEX_HOMEPAGE
};

public void OnPluginStart()
{
    _GMX_STDDBGINIT()
    _GMX_DBGLOG("OnPluginStart()")

    BuildPath(Path_SM, g_szCacheFile, sizeof(g_szCacheFile), "data/gmx/cache/privileges.json");
}

public void OnRebuildAdminCache(AdminCachePart ePart)
{
    _GMX_DBGLOG("OnRebuildAdminCache(): %d %d", ePart, g_bIsLoading)
    if (ePart != AdminCache_Admins || g_bIsLoading)
    {
        return;
    }

    g_bIsLoading = true;
    GameX_DoRequest("server/privileges", null, OnPrivilegesReceived);
}

public Action OnClientPreAdminCheck(int iClient)
{
    _GMX_DBGLOG("OnClientPreAdminCheck(): %L %d", iClient, g_bIsLoading)
    if (g_bIsLoading)
    {
        g_bMarkAsPost[iClient] = true;
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public void OnPrivilegesReceived(HTTPStatus iStatusCode, JSON hResponse, const char[] szError)
{
    _GMX_DBGLOG("OnPrivilegesReceived(): %d %x '%s'", iStatusCode, hResponse, szError)
    g_bIsLoading = false;
    bool bUsedCacheVersion = false;

    if (iStatusCode != HTTPStatus_OK)
    {
        // Check error buffer, if exists.
        if (szError[0])
        {
            LogError("REST in Pawn internal error: %s", szError);
        }

        // Use cached version, if exists.
        if (GameX_GetBoolConfigValue("CachePrivilegesOnDisk", true))
        {
            _GMX_DBGLOG("OnPrivilegesReceived(): Trying to switch cached version...")
            if (!FileExists(g_szCacheFile))
            {
                LogError("Can't use cached privileges version: file not exists.");
            }
            else
            {
                // We can do not close handle from REST in Pawn. He close him manually after finishing function executing.
                hResponse = view_as<JSON>(JSONObject.FromFile(g_szCacheFile));
                LogError("Using cached version allowed, so we're comebacking to cache.");
                bUsedCacheVersion = true;

                _GMX_DBGLOG("OnPrivilegesReceived(): '%s' -> %x", g_szCacheFile, hResponse)
            }
        }
    }

    if (hResponse)
    {
        StringMap hGroupAssociations = new StringMap();
        JSONObject hRoot = JSONObject(hResponse);

        ReadGroups(JSONArray(hRoot.Get("groups")), hGroupAssociations);
        ReadPrivileges(JSONArray(hRoot.Get("privileges")), hGroupAssociations);

        hGroupAssociations.Close();

        if (!bUsedCacheVersion)
        {
            _GMX_DBGLOG("OnPrivilegesReceived(): Writing to cache...")
            hRoot.ToFile(g_szCacheFile, JSON_COMPACT | JSON_ENCODE_ANY);
        }
    }

    for (int iClient = MaxClients; iClient != 0; iClient--)
    {
        if (IsClientInGame(iClient) && g_bMarkAsPost[iClient])
        {
            _GMX_DBGLOG("OnPrivilegesReceived(): Running PostCache checks for %L", iClient)
            g_bMarkAsPost[iClient] = false;

            RunAdminCacheChecks(iClient);
            NotifyPostAdminCheck(iClient);
        }
    }
}

/**
 * Readers.
 */
void ReadGroups(JSONArray hResponse, StringMap hGroupAssociations)
{
    if (!hResponse)
    {
        return;
    }

    char szTitle[256];

    int iGroupCount = hResponse.Length;
    JSONObject hGroup;
    GroupId eGroup;
    for (int iGroupId = 0; iGroupId < iGroupCount; ++iGroupId)
    {
        hGroup = JSONObject(hResponse.Get(iGroupId));
        hGroup.GetString("title", szTitle, sizeof(szTitle));

        eGroup = UTIL_SafeGroupCreate(szTitle);
        UTIL_SetAmxxFlags(eGroup, hGroup.GetInt("flags"));
        eGroup.ImmunityLevel = hGroup.GetInt("priority");
        hGroup.Close();

        hGroupAssociations.SetValue(szTitle, eGroup, true);
    }

    hResponse.Close();
}

void ReadPrivileges(JSONArray hResponse, StringMap hGroupAssociations)
{
    if (!hResponse)
    {
        return;
    }

    int iPrivilegesCount = hResponse.Length;
    for (int iPrivilegeId = 0; iPrivilegeId < iPrivilegesCount; ++iPrivilegeId)
    {
        // TODO: parse privileges.
    }

    hResponse.Close();
}

/**
 * UTILs
 */
void UTIL_SetAmxxFlags(GroupId eGroup, int iFlags)
{
    // Вручную составленное сопоставление флагов SM <-> AMXX, см. лист "AMXX <-> SM флаги"
    // https://docs.google.com/spreadsheets/d/1m8naDqVD0Z1zHBjbZQwg6lDW2kqQhf28tI_n6rLecfM/edit?usp=sharing

    if (iFlags == 0)
    {
        eGroup.SetFlag(Admin_Root, true);
        return; // Нет смысла продолжать.
    }

    // Сначала флаги, которые можно проставить циклом.
    UTIL_AmxxFlagsRange(eGroup, iFlags, 12, 15, 17);    // Кастомки.
    UTIL_AmxxFlagsRange(eGroup, iFlags, 4, 5, 11);      // С слея по ркон.

    // Абсолютно идентичные флаги.
    UTIL_AmxxSetIdenticalFlag(eGroup, iFlags, (1 << 2));    // Бан.
    UTIL_AmxxSetIdenticalFlag(eGroup, iFlags, (1 << 3));    // Кик.

    // И различающиеся, недостижимые циклом.
    UTIL_AmxxSetFlag(eGroup, iFlags, (1 << 24), (1 << 1));  // Базовая админка.
    UTIL_AmxxSetFlag(eGroup, iFlags, (1 << 1),  (1 << 0));  // Резервный слот.
}

void UTIL_AmxxFlagsRange(GroupId eGroup, int iFlags, int iBaseAmxxFlag, int iBaseSmFlag, int iMaxAmxxFlag)
{
    for (int i = iBaseAmxxFlag, iBaseOffset = iBaseSmFlag; i <= iMaxAmxxFlag; ++i, ++iBaseOffset)
    {
        UTIL_AmxxSetFlag(eGroup, iFlags, (1 << i), (1 << iBaseSmFlag));
    }
}

void UTIL_AmxxSetIdenticalFlag(GroupId eGroup, int iFlags, int iFlag, bool bState = true)
{
    UTIL_AmxxSetFlag(eGroup, iFlags, iFlag, iFlag, bState);
}

void UTIL_AmxxSetFlag(GroupId eGroup, int iFlags, int iAmxxFlag, int iSmFlag, bool bState = true)
{
    if (iFlags && iAmxxFlag)
    {
        AdminFlag eFlag;
        BitToFlag(iSmFlag, eFlag);

        eGroup.SetFlag(eFlag, bState);
    }
}

GroupId UTIL_SafeGroupCreate(const char[] szTitle)
{
    char szBuffer[256];
    UTIL_SafeName(szBuffer, sizeof(szBuffer), szTitle);

    GroupId eGroup = FindAdmGroup(szBuffer);
    if (eGroup == INVALID_GROUP_ID)
    {
        eGroup = CreateAdmGroup(szBuffer);
    }

    return eGroup;
}

void UTIL_SafeName(char[] szBuffer, int iBufferLength, const char[] szName)
{
    GameX_GetConfigValue("AdminCacheEntriesPrefix", szBuffer, iBufferLength);

    int iPos = strlen(szBuffer);
    strcopy(szBuffer[iPos], iBufferLength-iPos, szName);
}