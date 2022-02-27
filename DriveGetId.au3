#NoTrayIcon

#include <WinAPIFiles.au3>

Local $sDrive, $tDrive, $aData
Switch $CmdLine[0]
  Case 2
    $tDrive = StringStripWS($CmdLine[2], 3)
	$sDrive = StringRegExpReplace($tDrive, "(\\+)$", "", 1)
;	$sDrive = (StringRight($tDrive, 1) == "\") ? ($tDrive) : ($tDrive & "\")
  Case Else
    MsgBox(4096, "Parameters Error", 'DrivegetId "Drv4SN "E:|GUID" | Drv4FS "E:|GUID" | Drv2Label "E:|GUID" | Label2Drv "Temp" | DRV2DEVICE E: | DRV2GUID E:' _
		& @CRLF & 'GUID2Drv "GUID" | DRV2UUID "E:|GUID" | UUID2DRV UUID | UUID2GUID UUID | DRV2NUM "E:|GUID"| LASTDRV "OXYZ" | GETVOLUMES ";" | GUID2NUM "GUID" ' _
		& @CRLF & 'GUID2DEVICE "GUID" | NUM2GUID "1.1|hd0,0|hd0,msdos1" | GETBOOTID "BOOT|WIM|SYSTEM" >tmp.bat|txt)' )
    Exit(1)
EndSwitch

Switch StringUpper($CmdLine[1])
  Case "DRV4SN"
	ConsoleWrite(DriveGetSerial($sDrive & "\"))

  Case "DRV4FS"
	ConsoleWrite(DriveGetFileSystem($sDrive & "\"))

  Case "DRV2LABEL"
	ConsoleWrite(StringUpper(DriveGetLabel($sDrive & "\")))

  Case "DRV2GUID"
  	ConsoleWrite(StringUpper(_WinAPI_GetVolumeNameForVolumeMountPoint($sDrive & "\")))
;	ConsoleWrite(RunProgram("grub-probe.exe", "--target=device " & $sDrive))

  Case "NUM2GUID"
		Local $nums, $Disk, $Partition, $tDrive = StringUpper($sDrive)
		If StringInStr($sDrive, ".") Then
			$nums = StringSplit($sDrive, ".")
			$Disk = $nums[1] - 1
			$Partition = $nums[2]
		ElseIf StringInStr($tDrive, "MSDOS") or StringInStr($tDrive, "GPT") Then
			$nums = StringRegExp($tDrive, "HD([[:digit:]]{1,2}),(?:|MSDOS|GPT)([[:digit:]]{1,2})", 1, 1)
			$Disk = $nums[0]
			$Partition = $nums[1]
		Else
			$nums = StringRegExp($tDrive, "HD([[:digit:]]{1,2}),([[:digit:]]{1,2})", 1, 1)
			$Disk = $nums[0]
			$Partition = $nums[1] + 1
		EndIf
	If @error Then Exit(1)
  	ConsoleWrite(getVolumeFromNum($Disk, $Partition))

  Case "DRV2UUID"
	ConsoleWrite(_GetUUIDfromDrv($sDrive))

  Case "DRV2DEVICE"
	ConsoleWrite(_WinAPI_QueryDosDevice($sDrive))

  Case "DRV2NUM"
	Local $aData = _DrvGetDriveNumber($sDrive)
	If Not IsArray($aData) Then Exit(1)
	Local $out = StringFormat('@set "onmifs=%s.%s:"', $aData[1] +1, $aData[2]) & @CRLF
	$out &= StringFormat('@set "grub4dos=(hd%s,%s)"', $aData[1], $aData[2] -1) & @CRLF
	$out &= StringFormat('@set "grub2=(hd%s,msdos%s)"', $aData[1], $aData[2])
	ConsoleWrite($out)

  Case "LABEL2DRV"
    Local $var = DriveGetDrive("all")
    If Not @error Then
        For $i = 1 To $var[0]
            If DriveGetLabel($var[$i] & "\") = $sDrive Then
                ConsoleWrite($var[$i])
		ExitLoop
            EndIf
        Next
    EndIf

  Case "GUID2DRV"
  	Local $tDrive = StringRegExpReplace($sDrive, "(\\+)$", "", 1) & "\"
	ConsoleWrite(StringUpper(StringLeft(_GetVolumePathNamesForVolumeName($tDrive), 2)))

  Case "GUID2DEVICE"
	ConsoleWrite(_Drv2Device($sDrive) )

  Case "GUID2NUM"
	Local $Style = _GetDrivePartitionStyle($sDrive)
	Local $aData = _DrvGetDriveNumber($sDrive)
	Local $disk = $aData[1]
	Local $Partition = $aData[2]
	ConsoleWrite((StringInStr($Style,"MBR")) ? ("hd" & $disk & ",msdos" & $Partition) : ("hd" & $disk & ",gpt" & $Partition) )

  Case "UUID2DRV"
    Local $var = DriveGetDrive("all")
    If Not @error Then
        For $i = 1 To $var[0]
            If _GetUUIDfromDrv($var[$i]) = $sDrive Then
                ConsoleWrite(StringUpper($var[$i]))
				ExitLoop
            EndIf
        Next
    EndIf

  Case "UUID2GUID"
	Local $ReturnVaules, $ndVolume = 0
	Local $tVolume = _FindFirstVolume($ReturnVaules)
	Local $Handle = $tVolume[0]
	If _GetUUIDfromDrv($ReturnVaules) = $tDrive Then
		_FindVolumeClose($Handle)
		ConsoleWrite($ReturnVaules)
	EndIf

	While 1
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If $ndVolume = 0 Then ExitLoop
		If _GetUUIDfromDrv($ReturnVaules) = $tDrive Then ExitLoop
	WEnd

	_FindVolumeClose($Handle)
	ConsoleWrite($ReturnVaules)

  Case "UUID2NUM"
		Local $uuid = StringStripWS($sDrive, 3)
		Local $VolumeId = _GetDrvFromUUID($uuid)
		Local $Style = _GetDrivePartitionStyle($VolumeId)
		Local $aData = _DrvGetDriveNumber($VolumeId)
		Local $disk = $aData[1]
		Local $Partition = $aData[2]
		ConsoleWrite((StringInStr($Style,"MBR")) ? ("hd" & $disk & ",msdos" & $Partition) : ("hd" & $disk & ",gpt" & $Partition) )

  Case "GETVOLUMES"
	getAllVolumes($sDrive)

  Case "LASTDRV"
	ConsoleWrite(FindLastDrv($sDrive) & ":")

  Case "GETBOOTID"
	Local $BootDevice , $tDrive = StringUpper($sDrive)
	If StringInStr($tDrive, "SYSTEM") Then
		$BootDevice = RegRead("HKLM\System\Setup", "SystemPartition")
		ConsoleWrite($BootDevice)
		Exit(0)
	EndIf

	If StringInStr($tDrive, "BOOT") Then
		Local $pattern = ""
		$BootDevice = RegRead("HKLM\System\CurrentControlSet\Control", "FirmwareBootDevice")
		If StringInStr($BootDevice, "multi") Then
			$pattern = "multi\([[:digit:]]{1,2}\)disk\(0\)rdisk\(([[:digit:]]{1,2})\)partition\(([[:digit:]])\)"
		Else
			$pattern = "scsi\([[:digit:]]{1,2}\)disk\(([[:digit:]]{1,2})\)rdisk\(0\)partition\(([[:digit:]])\)"
		EndIf

		$aData = StringRegExp($BootDevice, $pattern, 1, 1)
		If Not IsArray($aData) Then Exit(1)
		ConsoleWrite(getVolumeFromNum($aData[0], $aData[1]))
	EndIf

	If StringInStr($tDrive, "WIM") Then
		$BootDevice = RegRead("HKLM\System\CurrentControlSet\Control", "PEBootRamdiskSourceDrive")
		ConsoleWrite($BootDevice)
	EndIf

  Case Else
		MsgBox(4096, "Parameters Error", $CmdLine[1] & @TAB & $CmdLine[2] & @TAB, 8)
    Exit(1)
EndSwitch

Exit(0)


Func _Drv2Device($sDrive)
	Local $tDrive = StringRegExpReplace($sDrive, "(\\+)$", "", 1) & "\"
	If Not StringInStr($tDrive, "\\?\Volume") Then Return _WinAPI_QueryDosDevice($sDrive)
	Local $lastL = "B:", $detect = false
	Local $aDrive = _GetVolumePathNamesForVolumeName($tDrive)
	If @error Then
		$detect = true
		If FileExists("B:") Then $lastL = FindLastDrv("CDEFGIXYZ") & ":"
		_WinAPI_SetVolumeMountPoint($lastL & "\", $tDrive)
	Else
		$lastL = StringLeft($aDrive, 2)
	Endif
	Local $lastDrv = _WinAPI_QueryDosDevice($lastL)
;	Local $aCall = DllCall('kernel32.dll', 'dword', 'QueryDosDeviceW', 'wstr', null, 'struct*', $tData, 'dword', 32768)
	If ($detect) Then _WinAPI_DeleteVolumeMountPoint($lastL & "\")
	Return $lastDrv
EndFunc ; End =>_Drv2Device


Func RunProgram($Program, $Command)
	Local $sFilePath = StringRegExpReplace(@ScriptDir, "[\\/]+\z", "") & "\" & $Program
  	If Not FileExists($sFilePath) Then
		MsgBox(4096, "Error", "File not Found: " & $sFilePath)
		Exit(1)
	EndIf
	Local $pid = Run($sFilePath & " " & $Command, "", @SW_HIDE, 2)
	ProcessWaitClose($pid)
	Local $sOutput = StdoutRead($pid)
	If @error Then Return ""
	Return $sOutput
EndFunc


Func FindLastDrv($Extra)
	Local $lastL= ""
	Local $BitMask = _WinAPI_GetLogicalDrives()
	Local $iExtra = StringToASCIIArray($Extra)
	For $Bits In $iExtra
		$BitMask = BitOR($BitMask,2^($Bits - 65) )
	Next

	For $i = 2 To 25
		If Not BitAND(2^$i, $BitMask) Then
			$lastL = Chr($i + 65)
			ExitLoop
		EndIf
	Next
	Return $lastL
EndFunc


Func _GetVolumePathNamesForVolumeName($sVolumeName)
	Local $tData, $pBuffer, $pSize, $Drive = ""
	$tData = DllStructCreate("dword size;wchar buffer[256]")
	$pBuffer = DllStructGetPtr($tData, "buffer")
	$pSize = DllStructGetPtr($tData, "size")
	$aCall = DllCall("kernel32.dll", "int", "GetVolumePathNamesForVolumeNameW", "wstr", $sVolumeName, "ptr", $pBuffer, "dword", 256, "ptr", $pSize)
	$Drive = DllStructGetData($tData, "buffer")
	If @error Then Return SetError(1)
	If StringIsSpace(StringStripWS($Drive, 3)) Then Return SetError(1)
	Return $Drive
EndFunc


Func getVolumeFromNum($disk, $partition)
	Local $ReturnVaules, $ndVolume = 0
	Local $tVolume = _FindFirstVolume($ReturnVaules)
	Local $Handle = $tVolume[0]
	$aData = _DrvGetDriveNumber($ReturnVaules)
	If IsArray($aData) Then
		If ($disk = $aData[1]) And ($Partition = $aData[2]) Then
			_FindVolumeClose($Handle)
			Return $ReturnVaules
		EndIf
	EndIf

	While 1
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If $ndVolume = 0 Then ExitLoop
		$aData = _DrvGetDriveNumber($ReturnVaules)
		If IsArray($aData) Then
			If ($disk = $aData[1]) And ($Partition = $aData[2]) Then ExitLoop
		EndIf
	WEnd
	_FindVolumeClose($Handle)
	Return $ReturnVaules
EndFunc


Func getAllVolumes($delims = ";")
	Local $ReturnVaules, $ndVolume = 0, $vIndex = 1, $out = "", $disk, $Partition
	Local $tVolume = _FindFirstVolume($ReturnVaules)
	Local $Handle = $tVolume[0]

	$aData = _DrvGetDriveNumber($ReturnVaules)
	If IsArray($aData) Then
		Local $Style = _GetDrivePartitionStyle($ReturnVaules)
		$disk = $aData[1]
		$Partition = $aData[2]
		$out = (StringInStr($Style,"MBR")) ? ("hd" & $disk & ",msdos" & $Partition) : ("hd" & $disk & ",gpt" & $Partition)
	EndIf

	If Not @error Then
		ConsoleWrite($vIndex & $delims & chr(34) & $out & chr(34) & $delims & _
			chr(34) & _GetUUIDfromDrv($ReturnVaules) & chr(34) & $delims & _
			chr(34) & StringLeft(_GetVolumePathNamesForVolumeName($ReturnVaules), 2) & chr(34) & $delims & _
			chr(34) & $ReturnVaules & chr(34) & $delims & _
			chr(34) & DriveGetLabel($ReturnVaules) & chr(34) & $delims & _
			chr(34) & _Drv2Device($ReturnVaules) & chr(34) & $delims & _
			chr(34) & DriveGetFileSystem($ReturnVaules) & chr(34) & $delims & _
 			chr(34) & DriveGetType($ReturnVaules) & chr(34) & $delims & _
			Floor(DriveSpaceTotal($ReturnVaules)) & $delims & Floor(DriveSpaceFree($ReturnVaules)) )
	EndIf

	While 1
		$uuid1 = ""
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If $ndVolume = 0 Then ExitLoop
		$aData = _DrvGetDriveNumber($ReturnVaules)
		If IsArray($aData) Then
			Local $Style = _GetDrivePartitionStyle($ReturnVaules)
			$disk = $aData[1]
			$Partition = $aData[2]
			$out = (StringInStr($Style,"MBR")) ? ("hd" & $disk & ",msdos" & $Partition) : ("hd" & $disk & ",gpt" & $Partition)
		EndIf

		If Not @error Then
			$vIndex += 1
			ConsoleWrite(@CRLF & $vIndex & $delims & chr(34) & $out & chr(34) & $delims & _
			chr(34) & _GetUUIDfromDrv($ReturnVaules) & chr(34) & $delims & _
			chr(34) & StringLeft(_GetVolumePathNamesForVolumeName($ReturnVaules), 2) & chr(34) & $delims & _
			chr(34) & $ReturnVaules & chr(34) & $delims & _
			chr(34) & DriveGetLabel($ReturnVaules) & chr(34) & $delims & _
			chr(34) & _Drv2Device($ReturnVaules) & chr(34) & $delims & _
			chr(34) & DriveGetFileSystem($ReturnVaules) & chr(34) & $delims & _
 			chr(34) & DriveGetType($ReturnVaules) & chr(34) & $delims & _
			Floor(DriveSpaceTotal($ReturnVaules)) & $delims & Floor(DriveSpaceFree($ReturnVaules)) )
		EndIf
	WEnd
	_FindVolumeClose($Handle)
EndFunc


Func _GetVolumePathName($lpszFileName)
	Local $lpszVolumePathName = DllStructCreate("wchar[255]")
	Local $ret = DllCall("Kernel32.dll", "int", "GetVolumePathNameW", "wstr", $lpszFileName, "Ptr", DllStructGetPtr($lpszVolumePathName), "dword", 255)
	Return DllStructGetData($lpszVolumePathName, 1)
EndFunc   ;=>_GetVolumePathName


Func _DrvGetDriveNumber($sDrive)
	Local $Volumeid = StringStripWS($sDrive, 3)
	If Not StringInStr($sDrive, "\\?\Volume") Then $Volumeid = "\\.\" & $sDrive
	If StringRight($Volumeid, 1) == "\" Then $Volumeid = StringTrimRight($Volumeid ,1)

	Local $hFile = _WinAPI_CreateFileEx($Volumeid, $OPEN_EXISTING, 0, $FILE_SHARE_READWRITE)
	If @error Then Return SetError(@error + 20, @extended, 0)

	Local $tSDN = DllStructCreate('dword;ulong;ulong')
	Local $aCall = DllCall('kernel32.dll', 'bool', 'DeviceIoControl', 'handle', $hFile, 'dword', 0x002D1080, 'ptr', 0, _
			'dword', 0, 'struct*', $tSDN, 'dword', DllStructGetSize($tSDN), 'dword*', 0, 'ptr', 0)
	If __CheckErrorCloseHandle($aCall, $hFile) Then Return SetError(@error, @extended, 0)

	Local $aRet[3]
	For $i = 0 To 2
		$aRet[$i] = DllStructGetData($tSDN, $i + 1)
	Next
	Return $aRet
EndFunc   ;=>_WinAPI_GetDriveNumber


Func _GetDrivePartitionStyle($sDrive)
	Local $Volumeid = StringStripWS($sDrive, 3)
	If Not StringInStr($sDrive, "\\?\Volume") Then $Volumeid = "\\.\" & $sDrive
	If StringRight($Volumeid, 1) == "\" Then $Volumeid = StringTrimRight($Volumeid ,1)
	Local $tDriveLayout = DllStructCreate('dword PartitionStyle;' & 'dword PartitionCount;' & 'byte union[40];' & 'byte PartitionEntry[8192]')
	Local $hDrive = DllCall("kernel32.dll", "handle", "CreateFileW", _
            "wstr", $Volumeid, "dword", 0, "dword", 0, "ptr", 0, "dword", 3, "dword", 0, "ptr", 0)
	If @error Or $hDrive[0] = Ptr(-1) Then Return SetError(@error, @extended, 0) ; INVALID_HANDLE_VALUE
	DllCall("kernel32.dll", "int", "DeviceIoControl", "hwnd", $hDrive[0], "dword", 0x00070050, "ptr", 0, "dword", 0, "ptr", DllStructGetPtr($tDriveLayout), _
		"dword", DllStructGetSize($tDriveLayout), "dword*", 0, "ptr", 0)
	DllCall("kernel32.dll", "bool", "CloseHandle", "handle", $hDrive[0])
	Switch DllStructGetData($tDriveLayout, "PartitionStyle")
        Case 0
            Return "MBR"
        Case 1
            Return "GPT"
        Case 2
            Return "RAW"
        Case Else
            Return "UNKNOWN"
	EndSwitch
EndFunc   ;=>_GetDrivePartitionStyle


Func _WinAPI_GetFirmwareEnvironmentVariable()
    DllCall("kernel32.dll", "dword", _
            "GetFirmwareEnvironmentVariableW", "wstr", "", "wstr", "{00000000-0000-0000-0000-000000000000}", "wstr", "", "dword", 4096)
    Local $iError = DllCall("kernel32.dll", "dword", "GetLastError")
    Switch $iError[0]
        Case 1
            Return "LEGACY"
        Case 998
            Return "UEFI"
        Case Else
            Return "UNKNOWN"
    EndSwitch
EndFunc   ;=>_WinAPI_GetFirmwareEnvironmentVariable


Func _GetDrvFromUUID($uuid)
	Local $ReturnVaules, $ndVolume = 0
	Local $tVolume = _FindFirstVolume($ReturnVaules)
	If Not @error Then
		If $uuid = _GetUUIDfromDrv($ReturnVaules) Then
			_FindVolumeClose($tVolume[0])
			 Return $ReturnVaules
		EndIf
	EndIf

	Local $Handle = $tVolume[0]
	While 1
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If $ndVolume = 0 Then ExitLoop
		If Not @error Then
			If $uuid = _GetUUIDfromDrv($ReturnVaules) Then ExitLoop
		EndIf
	WEnd
	_FindVolumeClose($Handle)
	 Return $ReturnVaules
EndFunc ; End =>_GetDrvFromUUID


Func _GetUUIDfromDrv($tDrive)
	Local $hfile, $nfile
	Local $sDrive = StringRegExpReplace($tDrive, "(\\+)$", "", 1)
	If 	StringRegExp($sDrive, "\\\\\?\\Volume\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}") Then
		$nfile = $sDrive
	ElseIf StringRegExp(StringUpper($sDrive), "[C-Z]\:$") Then
		$nfile = "\\.\" & $sDrive
	Else
		Return SetError(1)
	EndIf
	If StringInStr(DriveGetFileSystem($nfile & "\"), "FAT") Then Return Hex(DriveGetSerial($nfile & "\") & @CRLF)
	$hfile = FileOpen($nfile, 16)
	Local $filescont = FileRead($hfile, 84); 84 bytes is enough
;	 ConsoleWrite(_HexEncode($filescont) & @CRLF)
	FileClose($hfile)

	Local $tRaw = DllStructCreate("byte [" & BinaryLen($filescont) & "]")
	DllStructSetData($tRaw, 1, $filescont)
	Local $tBootSectorSections = DllStructCreate("align 1;byte Jump[3];char SystemName[8];ushort;ubyte;ushort;ubyte[3];ushort;ubyte;ushort;ushort;ushort;" & _
		"dword;dword;dword;int64;int64;int64;dword;dword;int64 NTFSerialNumber;dword Checksum", DllStructGetPtr($tRaw))
	If Number(DllStructGetData($tBootSectorSections, "Checksum") ) = 0 Then
		Return Hex(DllStructGetData($tBootSectorSections, "NTFSerialNumber") & @CRLF)
	EndIf
    Return SetError(1)
EndFunc  ;=>_GetUUIDfromDrv


Func _HexEncode($bInput)
    Local $tInput = DllStructCreate("byte[" & BinaryLen($bInput) & "]")
    DllStructSetData($tInput, 1, $bInput)
    Local $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), "dword", DllStructGetSize($tInput), "dword", 11, "ptr", 0, "dword*", 0)
    If @error Or Not $a_iCall[0] Then Return SetError(1, 0, "")
    Local $iSize = $a_iCall[5]
    Local $tOut = DllStructCreate("char[" & $iSize & "]")

    $a_iCall = DllCall("crypt32.dll", "int", "CryptBinaryToString", _
            "ptr", DllStructGetPtr($tInput), "dword", DllStructGetSize($tInput), "dword", 11, "ptr", DllStructGetPtr($tOut), "dword*", $iSize)
    If @error Or Not $a_iCall[0] Then Return SetError(2, 0, "")
    Return SetError(0, 0, DllStructGetData($tOut, 1))
EndFunc  ;=>_HexEncode
