/**
 * @section Typedefs
 */
typedef GameXCall = function void(HTTPStatus iStatusCode, JSON hResponse, const char[] szError, any data);

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
}
#endif