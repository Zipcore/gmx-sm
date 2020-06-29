#if defined _GameX_PlayerManager_included
  #endinput
#endif
#define _GameX_PlayerManager_included

// With any changes in GameX API, this value will be increased.
#define GAMEXPLAYERMANAGER_APIVERSION  0000015

/**
 * @section Forwards
 */

/**
 * Called when player loaded.
 *
 * @param iClient       Unique client identifier.
 * @param hBody         JSON body with data.
 */
forward void GameX_OnPlayerLoaded(int iClient, JSONObject hBody);

/**
 * @section Natives
 */

/**
 * Retrieves the client session id.
 *
 * @param iClient       Unique client identifier.
 * @return              The current session id. -1 if not authorized.
 * @error               Player is not in game.
 */
native int GameX_GetClientSessionId(int iClient);

/**
 * @section Shared Plugin
 */
public SharedPlugin __pl_GameX_PlayerManager = {
  name      = "GameX::PlayerManager",
  file      = "GameX/PlayerManager.smx",
#if defined REQUIRE_PLUGIN
  required  = 1,
#else
  required  = 0,
#endif
};