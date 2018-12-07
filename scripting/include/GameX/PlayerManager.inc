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