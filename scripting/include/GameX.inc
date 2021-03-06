#if defined _GameX_included
 #endinput
#endif
#define _GameX_included

/* Decide whether REST in Pawn should be required */
#if !defined REQUIRE_PLUGIN
 #if defined REQUIRE_EXTENSIONS
  #define TEMP_REQUIRE_EXTENSIONS
  #undef REQUIRE_EXTENSIONS
 #endif
#endif

#include <ripext>
#include <GMX_Polyfill>

/* Restore old REQUIRE_EXTENSIONS value if necessary */
#if defined TEMP_REQUIRE_EXTENSIONS
 #define REQUIRE_EXTENSIONS
 #undef TEMP_REQUIRE_EXTENSIONS
#endif

/**
 * @section Constants
 */
#define GAMEX_HOMEPAGE  "https://gm-x.info/"
stock const char  GMX_CHATPREFIX[]  = "GameX.Common.ChatPrefix";

// Load core.
#include <GameX/Debug>
#include <GameX/Core>

// If required, load Player Manager.
#if defined _GAMEX_PLAYERMANAGER
  #include <GameX/PlayerManager>
#endif

// If required, add macro-functions for creating API.
// Used only by core plugins.
#if defined _GAMEX_MACRO_API
  #define GMX_AddNative(%0)       CreateNative("GameX_" ... #%0, API_Native_%0)
  #define GMX_NativeCall(%0)      public int API_Native_%0(Handle hPlugin, int iParams)
  #define GMX_RedirectCall(%0)    API_Native_%0(hPlugin, iParams)
  #define GMX_InterruptCall(%0)   ThrowNativeError(SP_ERROR_NATIVE, %0)
#endif