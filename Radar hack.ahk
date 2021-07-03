#NoEnv

Process = csgo.exe
DLLName = client.dll

; you need to update these every csgo update
dwLocalPlayer = 0xD892CC
dwEntityList = 0x4DA215C

; these are ones that you PROBABLY dont need to update
dw_bSpotted = 0x93D
dw_iTeamNum = 0xF4
dw_bDormant = 0xED

Num = 0

Process, Exist, %Process%
ProcessID = %ErrorLevel%

if (!ProcessID)
{
   MsgBox, [!] CS:GO is not running!
   ExitApp
}

ProcessHandle := GetProcessHandle("Counter-Strike: Global Offensive")

if (!ProcessHandle)
{
   MsgBox, [!] Failed to get handle!
   ExitApp
}

Client := GetDllBase(DLLName, ProcessID)

if (!Client)
{
   MsgBox, [!] Failed to get %DLLName% from %Process%!
   ExitApp
}

LocalPlayer := ReadMemory(Client + dwLocalPlayer, ProcessHandle)
LocalTeam := ReadMemory(LocalPlayer + dw_iTeam, ProcessHandle)
Loop
{
   if (Num <= 64)
       Num++
   else
       Num = 1

   BaseEntity := ReadMemory(Client + dwEntityList + ((Num - 1) * 0x10), ProcessHandle)
   if (BaseEntity)
   {
       EntityTeam := ReadMemory(BaseEntity + dw_iTeamNum, ProcessHandle)
       EntityDormant := ReadMemory(BaseEntity + dw_bDormant, ProcessHandle)
       if (EntityTeam != LocalTeam and !EntityDormant)
           WriteMemory(BaseEntity + dw_bSpotted, 1, ProcessHandle)
   }
   Sleep, 10
}

ExitApp

; needed functions - dont touch unless you know what youre doing

GetProcessHandle(name)
{
   winget, pid, PID, %name%
   h := DllCall("OpenProcess", "int", 2035711, "char", 0, "UInt", pid, "UInt")
   return, h
}

WriteMemory(address, newval, processhandle)
{
   return DllCall("WriteProcessMemory", "UInt", processhandle, "UInt", address, "UInt*", newval, "UInt", 4, "UInt *", 0)
}

ReadMemory(address, processhandle)
{
   VarSetCapacity(addr,4,0)
   DllCall("ReadProcessMemory", "UInt", processhandle, "UInt", address, "Str", addr, "UInt", 4, "UInt *", 0)
   Loop 4
   result += *(&addr + A_Index-1) << 8*(A_Index-1)
   return, result
}

GetDllBase(DllName, PID = 0)
{
   TH32CS_SNAPMODULE := 0x00000008
   INVALID_HANDLE_VALUE = -1
   VarSetCapacity(me32, 548, 0)
   NumPut(548, me32)
   snapMod := DllCall("CreateToolhelp32Snapshot", "Uint", TH32CS_SNAPMODULE
                                                , "Uint", PID)
   If (snapMod = INVALID_HANDLE_VALUE) {
       Return 0
   }

   If (DllCall("Module32First", "Uint", snapMod, "Uint", &me32)){
       while(DllCall("Module32Next", "Uint", snapMod, "UInt", &me32)) {
           If !DllCall("lstrcmpi", "Str", DllName, "UInt", &me32 + 32) {
               DllCall("CloseHandle", "UInt", snapMod)
               Return NumGet(&me32 + 20)
           }
       }
   }
   DllCall("CloseHandle", "Uint", snapMod)
   Return 0
}