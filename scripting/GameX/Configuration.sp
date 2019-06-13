static SMCParser g_hSMC;

char g_szAuthHeader[1024];

void Configuration_Load() {
  DBGLOG("Configuration_Load()")

  Configuration_InitParser();
  g_hValues.Clear();
  Configuration_Start();
  Configuration_InitHTTP();
}

static void Configuration_InitParser() {
  DBGLOG("Configuration_InitParser(): %x", g_hSMC)
  if (g_hSMC)
    return;

  g_hSMC = new SMCParser();
  g_hSMC.OnEnterSection = Configuration_OnEnterSection;
  g_hSMC.OnLeaveSection = Configuration_OnLeaveSection;
  g_hSMC.OnKeyValue     = Configuration_OnKeyValue;
}

static void Configuration_Start() {
  DBGLOG("Configuration_Start()")
  int iLine, iCol;
  SMCError err = g_hSMC.ParseFile(g_szConfiguration, iLine, iCol);

  DBGLOG("Configuration_Start(): FINISHED. Line %d, Column %d, Error Code %d.", iLine, iCol, err)

  if (err == SMCError_Okay)
    return;

  Configuration_HandleError(err, iLine, iCol);
}

static void Configuration_HandleError(SMCError err, int iLine, int iCol) {
  DBGLOG("Configuration_HandleError()")
  char szError[256];
  if (!SMC_GetErrorString(err, szError, sizeof(szError)))
    strcopy(szError, sizeof(szError), "Custom user error (see error logs for more details)");
  LogError("[GameX] Configuration loading failed: [%d] %s in %s (%d:%d)", err, szError, g_szConfiguration, iLine, iCol);

  Configuration_HandleCriticalError(err);
}

static void Configuration_HandleCriticalError(SMCError err) {
  DBGLOG("Configuration_HandleCriticalError()")
  if (err != SMCError_StreamError && err != SMCError_StreamError)
    return;

  SetFailState("[GameX] Configuration loading failed with fatal error. See error logs for more details. Error code: %d", err);
}

static void Configuration_InitHTTP() {
  DBGLOG("Configuration_InitHTTP(): %x", g_hWebClient)
  if (g_hWebClient)
    CloseHandle(g_hWebClient);

  char szURL[256];
  if (!g_hValues.GetString("SiteAddress", szURL, sizeof(szURL))) {
    SetFailState("[GameX] Can't initialize HTTP client: site address not exists in config.");
    return;
  }

  g_hWebClient = new HTTPClient(szURL);
  g_hWebClient.SetHeader("X-Token", g_szAuthHeader);
  g_hWebClient.SetHeader("User-Agent", "GameX SourceMod Client (v" ... PLUGIN_VERSION ... ")");

  DBGLOG("Configuration_InitHTTP(): Installed token %s", g_szAuthHeader)
}

public SMCResult Configuration_OnEnterSection(SMCParser smc, const char[] szName, bool bOptQuotes) {
  DBGLOG("Configuration_OnEnterSection(): %x (%s)", smc, szName)
  return SMCParse_Continue;
}

public SMCResult Configuration_OnLeaveSection(SMCParser smc) {
  DBGLOG("Configuration_OnEnterSection(): %x", smc)
  return SMCParse_Continue;
}

public SMCResult Configuration_OnKeyValue(SMCParser smc, const char[] szKey, const char[] szValue, bool bKeyQuotes, bool bValueQuotes) {
  DBGLOG("Configuration_OnKeyValue(): %x, '%s', '%s', %d, %d", smc, szKey, szValue, bKeyQuotes, bValueQuotes)
  if (!strcmp(szKey, "Token")) {
    strcopy(g_szAuthHeader, sizeof(g_szAuthHeader), szValue);
    return SMCParse_Continue; // we don't should allow write token to global configuration
  }

  g_hValues.SetString(szKey, szValue, true);
  return SMCParse_Continue;
}