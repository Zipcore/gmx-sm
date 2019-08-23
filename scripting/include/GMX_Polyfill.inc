/**
 * This file defines a required functions
 * for old SourceMod versions.
 */

// For SourceMod 1.8 and older.
#if SOURCEMOD_V_MINOR < 9
/**
 * Pushes the NULL_STRING onto the current call.
 *
 * @note Cannot be used before a call has been started.
 * @error					Called before a call has been started.
 */
void Call_PushNullString()
{
    Call_PushString(NULL_STRING);
}
#endif