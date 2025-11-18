@echo off
cd /d %~dp0

rem 自コンピュータのプロセスをチェックする場合
rem cscript ProcessMonitor.vbs [processname] [memory threshold(MB)] [memory rearm(MB)]
rem 外部のコンピュータのプロセスをチェックする場合
rem cscript ProcessMonitor.vbs [hostname or IP] [username] [password] [processname] [memory threshold(MB)] [memory rearm(MB)]

cscript ProcessMonitor.vbs "C:\Program Files (x86)\AudioCodes USA\HPXMedia\Server\Bin\HMPService.exe" 700 500
cscript ProcessMonitor.vbs "C:\Program Files (x86)\Animo\VoiceTracking\FileTransfer\VtFileTransfer.exe" 700 500
cscript ProcessMonitor.vbs "C:\Program Files (x86)\Ai-Logix\SmartWORKS\SmrtwrksSrvc.exe" 700 500
cscript ProcessMonitor.vbs "C:\StationMonitor\StationMonitor.exe" 700 500
cscript ProcessMonitor.vbs "C:\VTRecServer\VTRecServer.exe" 700 500
cscript ProcessMonitor.vbs "C:\VTRecServer2\VTRecServer.exe" 700 500
rem cscript ProcessMonitor.vbs "C:\VTRecServer3\VTRecServer.exe" 700 500
rem cscript ProcessMonitor.vbs "C:\VTRecServer4\VTRecServer.exe" 700 500

rem pause
