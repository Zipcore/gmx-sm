# GameX-SM
SourceMod plugin for working with GameX

# Requirements
- **[SourceMod](https://sm.alliedmods.net/) v1.9** or higher
- **[REST in Pawn](https://github.com/CrazyHackGUT/sm-ripext) v1.0.5** or higher
- Installed GameX web panel

# Installing
- Compile plugin with **spcomp**
- Upload compiled plugin (_GameX.smx_) on your server.
- Upload configuration file with edited settings (_configs/GameX/Core.cfg_) on your server.
- Execute _sm plugins load GameX_ or restart server.

# Configuration
All core configuration placed in _configs/GameX/Core.cfg_. All config described. But we need pay attention to a couple of things:

- **For two different servers, GameX requires different tokens**. If you fill the same token on both servers, you can see all punishments from one server and no one from another.
- **URL to API endpoint should be without a backslash (/) on end**.