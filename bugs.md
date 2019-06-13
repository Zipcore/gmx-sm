# Game related...
## Counter-Strike: Global Offensive
### Max Players count
- **Description**: Core can't get correct max players count.
- **How to fix**: In `core.cfg` enable `RespectMaxVisiblePlayers` option, in game server configuration set up `sv_visiblemaxplayers`. In value you should set your slots count.

### Hibernation
- **Description**: SourceMod doesn't execute plugin code when server is empty. This can cause situations when server displays as _offline_.
- **How to fix**: Disable hibernation. For example, you can enable GOTV, or just set `sv_hibernate_when_empty` to value `0`.