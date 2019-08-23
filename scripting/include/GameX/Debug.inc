/**
 * GameX debug include.
 */

// #define _GMX_DEBUG
// TODO: rename all DBG*() functions to _GMX_DBG*()

#if defined _GMX_DEBUG
    char g_szDebugLog[PLATFORM_MAX_PATH];

    #define _GMX_STDDBGINIT()   _GMX_DBGINIT("GameX_Debug")
    #define _GMX_DBGINIT(%0)    DBGINIT(%0)
    #define _GMX_DBGLOG(%0)     DBGLOG(%0)

    #define DBGINIT(%0) BuildPath(Path_SM, g_szDebugLog, sizeof(g_szDebugLog), "logs/" ... %0 ... ".log");
    #define DBGLOG(%0)  LogToFile(g_szDebugLog, %0);
#else
    #define _GMX_STDDBGINIT()
    #define _GMX_DBGINIT(%0)
    #define _GMX_DBGLOG(%0)

    #define DBGINIT(%0) 
    #define DBGLOG(%0)
#endif