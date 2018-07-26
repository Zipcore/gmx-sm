#define AddNative(%0)       CreateNative("GameX_" ... #%0, API_Native_%0)
#define NativeCall(%0)      public int API_Native_%0(Handle hPlugin, int iParams)
#define RedirectCall(%0)    API_Native_%0(hPlugin, iParams)
#define InterruptCall(%0)   ThrowNativeError(SP_ERROR_NATIVE, %0)

void API_Initialize() {
  AddNative(GetConfigValue);
  AddNative(DoRequest);
  AddNative(IsReady);
  RegPluginLibrary("GameX");
}

NativeCall(GetConfigValue) {
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

NativeCall(DoRequest) {
  if (!RedirectCall(IsReady))
    InterruptCall("Web Client is not ready!");

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

NativeCall(IsReady) {
  return !!g_hWebClient;
}