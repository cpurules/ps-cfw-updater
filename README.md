# ps-cfw-updater
PowerShell script to update Hekate and Atmosphere installations on CFW Switch SD cards.  You will need to have your SD card connected to your computer, either via an SD card reader or mounted via the USB cable (using UMS or memloader).

Usage (Windows): `powershell.exe -file Update-Cfw.ps1` and follow the prompts

**Please note** - if you are upgrading from a pre-1.0.0 version of Atmosphere, you may need to either clean your sysmodules (unmark option `[m]` on the second menu), or you will need to manually update some of them e.g. [ldn_mitm](https://github.com/spacemeowx2/ldn_mitm).
