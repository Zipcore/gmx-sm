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

// Load core.
#include <GameX/Core>

// If required, load Player Manager.
#if defined _GAMEX_PLAYERMANAGER
  #include <GameX/PlayerManager>
#endif