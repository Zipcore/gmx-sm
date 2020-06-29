#if defined _GameX_Core_included
  #endinput
#endif
#define _GameX_Core_included

// With any changes in GameX API, this value will be increased.
#define GAMEXCORE_APIVERSION  0000017

/**
 * @section Typedefs
 */

typeset GameXCall
{
  // Called when request finished.
  //
  // @param iStatusCode             HTTP Status Code.
  // @param hResponse               JSON Response body.
  //                                Use RiP natives for working with this.
  // @param szError                 Error message (from cURL, if happened).
  // @param data                    Any passed user data.
  function void(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, any data);

  // Called when request finished.
  //
  // @param iStatusCode             HTTP Status Code.
  // @param hResponse               JSON Response body.
  //                                Use RiP natives for working with this.
  // @param szError                 Error message (from cURL, if happened).
  function void(HTTPStatus iStatusCode, JSON hResponse, const char[] szError);
}

/**
 * @section Forwards
 */

/**
 * Called when GameX perform a reloading by console command.
 * This can be useful, if you cache any configuration settings.
 */
forward void GameX_OnReload();

/**
 * @section Natives
 */

/**
 * Retrieves config value if exists.
 *
 * @param   szKey       Parameter name (key).
 * @param   szBuffer    Buffer for writing value.
 * @param   iMaxLength  Buffer size.
 * @param   szDefault   Value for writing, if setting can't be found.
 * @return              True, if setting exists and written.
 * @note                Before writing setting value to plugin buffer,
 *                      Core creates a temporary variable for storage
 *                      value. This temporary variable have size 1024.
 *                      You can't retrieve setting value with size
 *                      higher 1024.
 */
native bool GameX_GetConfigValue(const char[] szKey, char[] szBuffer, int iMaxLength, const char[] szDefault = "");

/**
 * Processes the request to GameX, if possible.
 *
 * @param   szCallName  Call name (like "player", "privileges" or "punish")
 * @param   hRequest    JSON object with request values.
 * @param   pFunction   Pointer to function-callback.
 * @param   data        Any data. Data will be passed to callback.
 * @throws              Throws error if web client is not ready.
 *                      You can check ability for creating request manually
 *                      with native GameX_IsReady()
 */
native void GameX_DoRequest(const char[] szCallName, JSONObject hRequest, GameXCall pFunction = INVALID_FUNCTION, any data = 0);

/**
 * Checks GameX ability to processing HTTP API requests.
 *
 * @return              True, if GameX can process requests. False, if not.
 */
native bool GameX_IsReady();

/**
 * Retrieves config value in boolean representation.
 *
 * @param   szKey       Parameter name (key).
 * @param   bDefault    Default value.
 *
 * @return              Parameter value.
 */
stock bool GameX_GetBoolConfigValue(const char[] szKey, bool bDefault = false)
{
  char szValue[4];
  if (!GameX_GetConfigValue(szKey, szValue, sizeof(szValue)))
    return bDefault;

  return (szValue[0] != '0');
}

/**
 * Retrieves config value in integer representation.
 *
 * @param   szKey       Parameter name (key).
 * @param   iDefault    Default value.
 *
 * @return              Parameter value.
 */
stock int GameX_GetIntegerConfigValue(const char[] szKey, int iDefault = 0)
{
  char szValue[16];
  if (!GameX_GetConfigValue(szKey, szValue, sizeof(szValue)))
    return iDefault;

  return StringToInt(szValue);
}

/**
 * Retrieves config value in float representation.
 *
 * @param   szKey       Parameter name (key).
 * @param   iDefault    Default value.
 *
 * @return              Parameter value.
 */
stock float GameX_GetFloatConfigValue(const char[] szKey, float flDefault = 0.0)
{
  char szValue[32];
  if (!GameX_GetConfigValue(szKey, szValue, sizeof(szValue)))
    return flDefault;

  return StringToFloat(szValue);
}

/**
 * @section Shared Plugin
 */
public SharedPlugin __pl_GameX = {
  name      = "GameX",
  file      = "GameX/Core.smx",
#if defined REQUIRE_PLUGIN
  required  = 1,
#else
  required  = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_GameX_SetNTVOptional() {
  // v0.0.0.2
  MarkNativeAsOptional("GameX_GetConfigValue");
  MarkNativeAsOptional("GameX_DoRequest");
  MarkNativeAsOptional("GameX_IsReady");

  // v0.0.1.0
  // forward void GameX_OnReload()
}
#endif