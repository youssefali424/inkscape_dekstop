flutter build macos
cd installers/dmg_creator
rm -rf ./inkscape_shortcut.dmg
appdmg ./config.json ./inkscape_shortcut.dmg