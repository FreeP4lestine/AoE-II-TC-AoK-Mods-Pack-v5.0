SetBatchLines, -1
SetWinDelay, 0

PBS_MARQUEE := 0x00000008
PBS_SMOOTH := 0x00000001
WM_USER := 0x00000400
PBM_SETMARQUEE := WM_USER + 10
Gui, -SysMenu
Gui, Font, s14 Bold, Calibri
Gui, Add, Text, w200 +Center cBlack vStatus, Getting Files Ready...`nPlease wait!
Gui, Add, Progress, w200 h20 hwndMARQ4 -%PBS_SMOOTH% +%PBS_MARQUEE%
DllCall("User32.dll\SendMessage", "Ptr", MARQ4, "Int", PBM_SETMARQUEE, "Ptr", 1, "Ptr", 50)
Gui, Show

FileInstall, 7za.exe, % A_Temp "\7za.exe", 1
FileInstall, Data.7z, % A_Temp "\Data.7z", 1
RunWait, "%A_Temp%\7za.exe" x -aoa "%A_Temp%\Data.7z" -o"%A_Temp%\AoEII_PatchTmpDir",, Hide
If ErrorLevel in 1,2,7,8,255
{
    Msgbox, 16, Unpack Error, Could not get the program files.`nPress OK to exit.
    ExitApp
}
Run, %A_Temp%\AoEII_PatchTmpDir\main.exe
ExitApp
