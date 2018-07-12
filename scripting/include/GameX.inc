#if defined _GameX_included
 #endinput
#endif
#define _GameX_included

// TODO: add natives here with documentation

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
  // TODO: add natives here for MarkNativeAsOptional()
}
#endif