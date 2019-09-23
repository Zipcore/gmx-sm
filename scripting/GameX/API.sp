Handle g_hFwdReload;

void API_Initialize() {
  GMX_AddNative(GetConfigValue);
  GMX_AddNative(DoRequest);
  GMX_AddNative(IsReady);

  g_hFwdReload = CreateGlobalForward("GameX_OnReload", ET_Ignore);

  RegPluginLibrary("GameX");
}

void API_OnReload()
{
  _GMX_DBGLOG("API_OnReload")

  Call_StartForward(g_hFwdReload);
  Call_Finish();
}

GMX_NativeCall(GetConfigValue) {
  char szBuffer[1024];
  char szKey[64];
  GetNativeString(1, szKey, sizeof(szKey));

  DBGLOG("GetConfigValue(): %s", szKey)

  bool bResult = g_hValues.GetString(szKey, szBuffer, sizeof(szBuffer)); 
  if (!bResult)
    if (iParams > 3)
      GetNativeString(4, szBuffer, sizeof(szBuffer));

  SetNativeString(2, szBuffer, GetNativeCell(3), true);
  return bResult;
}

GMX_NativeCall(DoRequest) {
  if (!GMX_RedirectCall(IsReady))
    GMX_InterruptCall("Web Client is not ready!");

  char szEndPoint[64];
  int iPos = strcopy(szEndPoint, sizeof(szEndPoint), "api/");
  GetNativeString(1, szEndPoint[iPos], sizeof(szEndPoint)-iPos);

  DBGLOG("DoRequest(): %s", szEndPoint)

  DataPack hPack = new DataPack();
  hPack.WriteCell(hPlugin);
  hPack.WriteFunction(GetNativeFunction(3));
  hPack.WriteCell(GetNativeCell(4));

  g_hWebClient.Post(szEndPoint, GetNativeCell(2), OnAPICallFinished, hPack);
}

GMX_NativeCall(IsReady) {
  return !!g_hWebClient;
}