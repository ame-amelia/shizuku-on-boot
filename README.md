# shizuku-on-boot

This script starts Shizuku after the system boots with Termux:Boot.

Requires packages: nmap openssl android-tools termux-api
Also install Termux:Boot and Termux:API from F-Droid.

Firstly, pair the ADB server with device:
1. Turn on Wireless debugging in settings
2. Press "Pair device with pairing code"
3. Open Termux in floating window/split-screen and enter the following command:
`adb pair localhost:[PORT] [CODE]`

Then simply place this script in the ~/.termux/boot/ directory.

I did not write this script, it was modified from a longer script by OP-san: https://github.com/RikkaApps/Shizuku/discussions/462
