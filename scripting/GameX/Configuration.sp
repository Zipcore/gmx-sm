static SMCParser g_hSMC;

void Configuration_Load() {
  Configuration_InitParser();
  g_hValues.Clear();
  Configuration_Start();
}

static void Configuration_InitParser() {
  if (g_hSMC)
    return;

  g_hSMC = new SMCParser();
  g_hSMC.OnEnterSection = Configuration_OnEnterSection;
  g_hSMC.OnLeaveSection = Configuration_OnLeaveSection;
  g_hSMC.OnKeyValue     = Configuration_OnKeyValue;
}

static void Configuration_Start() {
  int iLine, iCol;
  SMCError err = g_hSMC.ParseFile(g_szConfiguration, iLine, iCol);
  if (err == SMCError_Okay)
    return;

  Configuration_HandleError(err, iLine, iCol);
}

static void Configuration_HandleError(SMCError err, int iLine, int iCol) {
  char szError[256];
  if (!SMC_GetErrorString(err, szError, sizeof(szError)))
    strcopy("Custom user error (see error logs for more details)", szError, sizeof(szError));
  LogError("[GameX] Configuration loading failed: [%d] %s in %s (%d:%d)", err, szError, g_szConfiguration, iLine, iCol);

  Configuration_HandleCriticalError(err);
}

static void Configuration_HandleCriticalError(SMCError err) {
  if (err != SMCError_StreamError && err != SMCError_StreamError)
    return;

  SetFailState("[GameX] Configuration loading failed with fatal error. See error logs for more details. Error code: %d", err);
}

public SMCResult Configuration_OnEnterSection(SMCResult smc, const char[] szName, bool bOptQuotes) {
  return SMCParse_Continue;
}

public SMCResult Configuration_OnLeaveSection(SMCResult smc) {
  return SMCParse_Continue;
}

public SMCResult Configuration_OnKeyValue(SMCParser smc, const char[] szKey, const char[] szValue, bool bKeyQuotes, bool bValueQuotes) {
  if (!strcmp(szKey, "Token")) {
    if (!g_hWebClient) {
      LogError("[GameX] Can't set up token: client not initialized.");
      return SMCParse_HaltFail;
    }

    char szAuthHeader[1024];
    FormatEx(szAuthHeader, sizeof(szAuthHeader), "Basic %s", szValue);
    g_hWebClient.SetHeader("Authorization", szAuthHeader);
    return SMCParse_Continue;
  } else if (!strcmp(szKey, "SiteAddress")) {
    if (g_hWebClient)
      CloseHandle(g_hWebClient);

    g_hWebClient = new HTTPClient(szValue);
  }

  g_hValues.SetString(szKey, szValue, true);
  return SMCParse_Continue;
}