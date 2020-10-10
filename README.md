# Display Profile Switcher

## About
Applet for KDE Plasma 5 to switch between display configurations.

Written by Maciej Gierej - http://makg.eu

## Installation
```
plasmapkg2 -i package
```

~~Use additional `-g` flag to install plasmoid globally, for all users.~~

Global install will not work for now, as path to the Python wrapper is hardcoded.

## Requirements
- Python3

## How to use?
1. Open plasmoid's configuration.
2. Click "Create profile from current setup", edit its name
3. Go to KDE's display configuration in system settings and change monitor setup
4. Return to the plasmoid's configuration and add another profile
5. Now you can switch between profiles by clicking on their names

## How it works?
It's using D-Bus to get current configuration and to change it:
```
$ qdbus org.kde.KScreen /backend
method QVariantMap org.kde.kscreen.Backend.getConfig()
method QVariantMap org.kde.kscreen.Backend.setConfig(QVariantMap)
```

Unfortunetly `qdbus` does not support passing QVariantMap as an argument, so a wrapper is needed, it's written in Python and is located in `package/display-profile-switcher.py`.

The plasmoid calls the wrapper to save base64-encoded current display config and to restore it.

## Screenshots
![Display Profile Switcher (Menu)](https://raw.githubusercontent.com/MakG10/plasma-applet-display-profile-switcher/master/display-profile-switcher-menu.png)

![Display Profile Switcher (Configuration)](https://raw.githubusercontent.com/MakG10/plasma-applet-display-profile-switcher/master/display-profile-switcher-settings.png)

## License

Released under the GPLv3 license.

## Changelog

### 1.0
Initial release
