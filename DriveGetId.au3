#NoTrayIcon

#include <WinAPIFiles.au3>
#include <File.au3>
#include <WinAPIShPath.au3>


Local $sDrive, $tDrive, $aData
Switch $CmdLine[0]
  Case 2
    $tDrive = StringStripWS($CmdLine[2], 3)
	$sDrive = StringRegExpReplace($tDrive, "(\\+)$", "", 1)
;	$sDrive = (StringRight($tDrive, 1) == "\") ? ($tDrive) : ($tDrive & "\")
  Case Else
    MsgBox(4096, "Parameters Error", 'DrivegetId "Drv4SN "E:|GUID" | Drv4FS "E:|GUID" | Drv2Label "E:|GUID" | Label2Drv "Temp" | DRV2DEVICE E: | DRV2GUID E:' _
	& @CRLF & 'GUID2Drv "GUID" | DRV2UUID "E:|GUID" | UUID2DRV UUID | UUID2GUID UUID | DRV2NUM "E:|GUID"| LASTDRV "OXYZ" | GETVOLUMES ";" | GUID2NUM "GUID" ' _
	& @CRLF & 'GUID2DEVICE "GUID" | NUM2GUID "1.1|hd0,0|hd0,msdos1" | GETBOOTID "BOOT|SYSTEM" | SEARCHFILE "FilePath(?\test\tmp.txt)" >tmp.bat|txt)' )
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
  	_QualifyRootFromPath($sDrive) ; ByRef
	ConsoleWrite(StringUpper(StringLeft($sDrive, 2) ) )

  Case "GUID2DEVICE"
  	_QualifyRootFromPath($sDrive) ; ByRef
	ConsoleWrite(_Drv2Device($sDrive) )

  Case "GUID2NUM"
  	_QualifyRootFromPath($sDrive) ; ByRef
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
		If @error or $ndVolume = 0 Then ExitLoop
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
	ConsoleWrite(FindLastDrv($sDrive))

  Case "SEARCHFILE"
	Local $tsDrive = "", $sDir = "", $sFileName = "", $sExtension = ""
	Local $aPathSplit = _PathSplit($sDrive, $tsDrive, $sDir, $sFileName, $sExtension)
	$tsDrive = SearchFileWithAll($tsDrive, $sDir, $sFileName & $sExtension)
	If Not @error Then ConsoleWrite($tsDrive)

  Case "GETBOOTID"
	ConsoleWrite(SearchBootDrv($sDrive) )

  Case Else
		MsgBox(4096, "Parameters Error", $CmdLine[1] & @TAB & $CmdLine[2] & @TAB, 8)
    Exit(1)
EndSwitch

Exit(0)


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
			chr(34) & DriveGetSerial($ReturnVaules) & chr(34) & $delims & _
			chr(34) & DriveGetFileSystem($ReturnVaules) & chr(34) & $delims & _
 			chr(34) & DriveGetType($ReturnVaules) & chr(34) & $delims & _
			Floor(DriveSpaceTotal($ReturnVaules)) & $delims & Floor(DriveSpaceFree($ReturnVaules)) )
	EndIf

	While 1
		$uuid1 = ""
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If @error or $ndVolume = 0 Then ExitLoop		
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
			chr(34) & DriveGetSerial($ReturnVaules) & chr(34) & $delims & _
			chr(34) & DriveGetFileSystem($ReturnVaules) & chr(34) & $delims & _
 			chr(34) & DriveGetType($ReturnVaules) & chr(34) & $delims & _
			Floor(DriveSpaceTotal($ReturnVaules)) & $delims & Floor(DriveSpaceFree($ReturnVaules)) )
		EndIf
	WEnd
	_FindVolumeClose($Handle)
EndFunc


Func _GetDrvFromUUID($uuid)
	Local $ReturnVaules, $ndVolume = 0
	Local $tVolume = _FindFirstVolume($ReturnVaules)
	Local $Handle = $tVolume[0]
	If Not @error Then
		If $uuid = _GetUUIDfromDrv($ReturnVaules) Then
			_FindVolumeClose($Handle)
			 Return $ReturnVaules
		EndIf
	EndIf

	While 1
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If @error or $ndVolume = 0 Then ExitLoop
		If Not @error Then
			If $uuid = _GetUUIDfromDrv($ReturnVaules) Then ExitLoop
		EndIf
	WEnd
	_FindVolumeClose($Handle)
	 Return SetError(0, 0, $ReturnVaules)
EndFunc ; End =>_GetDrvFromUUID


Func _GetUUIDfromDrv($tDrive)
	Local $hfile, $nfile
	Local $sDrive = StringRegExpReplace($tDrive, "(\\+)$", "", 1)
	If 	StringRegExp($sDrive, "\\\\\?\\Volume\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}") Then
		$nfile = $sDrive
	ElseIf StringRegExp(StringUpper($sDrive), "[C-Z]\:$") Then
		$nfile = "\\.\" & $sDrive
	Else
		Return SetError(1, 0, "")
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
    Return SetError(1, 0, "")
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


Func GetACP() ; equal get chcp copepage
        Local $aResult = DllCall("kernel32.dll", "int", "GetACP")
        If @error Or Not $aResult[0] Then Return SetError(@error + 20, @extended, "")
        Return $aResult[0]
EndFunc   ;==>GetACP


Func FileSearchInEnvPath($Program)
	Local $sEnvVar = EnvGet("path")
	Local $pathDirs = StringSplit($sEnvVar, ";")
	Local $tFilePath = _WinAPI_PathFindFileName($Program)
	For $i = 1 To $pathDirs[0]
		$sFilePath = _WinAPI_PathAddBackslash(_WinAPI_PathSearchAndQualify(_WinAPI_PathUnquoteSpaces($pathDirs[$i]) ) ) & $tFilePath
		If FileExists($sFilePath) Then
;			MsgBox(4096, "",  $sFilePath)
			Return SetError(0, 0, $sFilePath)
		EndIf
	Next
	Return SetError(1, 0)
EndFunc ; FileSearchInEnvPath


Func RunProgram($Program, $Command)
	Local $sFilePath = FileGetLongName($Program)
  	If Not FileExists($sFilePath) Then $sFilePath = _WinAPI_PathFindOnPath($Program)
	If Not FileExists($sFilePath) Then
		ConsoleWrite("File not Found: " & $Program & @CRLF)
		Return SetError(1, 0, "")
	EndIf
	Local $pid = Run($sFilePath & " " & $Command, "", @SW_HIDE, 2)
	ProcessWaitClose($pid)
	Local $sOutput = StdoutRead($pid)
	If @error Then Return SetError(1, 0, "")
	Return SetError(0, 0, $sOutput)
EndFunc


Func SearchFileWithAll(ByRef $initDir, $initPath, $initFile)
	Local $findFile, $tFile
	Local $sPath = _WinAPI_PathSearchAndQualify($initPath)
    If StringIsSpace($initFile) Then Return SetError(1, 0, "")

	Local $tRoot = StringStripWS($initDir, 3)
	If Not StringIsSpace($tRoot) Then
		$tFile = $tRoot & $sPath & $initFile
		If FileExists($tFile) Then Return SetError(0, 0, $tFile)
	EndIf

	Local $ReturnVaules, $ndVolume = 0
	Local $tVolume = _FindFirstVolume($ReturnVaules)
	Local $Handle = $tVolume[0]

	$tFile = $ReturnVaules & $sPath & $initFile
	If FileExists($tFile) Then
		$initDir = $ReturnVaules
		_FindVolumeClose($Handle)
		Return SetError(0, 0, $tFile)
	EndIf

	While 1
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If @error or $ndVolume = 0 Then ExitLoop
		$tFile = $ReturnVaules & $sPath & $initFile
		If FileExists($tFile) Then
			$initDir = $ReturnVaules
			_FindVolumeClose($Handle)
			Return SetError(0, 0, $tFile)
		EndIf
	WEnd
	_FindVolumeClose($Handle)
	Return SetError(1, 3)
EndFunc ; SearchFileWithAll


Func SearchBootDrv($sBootType)
	Local $BootDevice , $tDrive = StringUpper($sBootType)
	If StringInStr($tDrive, "BOOT") Then
		Local $pattern = ""
		$BootDevice = RegRead("HKLM\System\CurrentControlSet\Control", "FirmwareBootDevice")
		If StringInStr($BootDevice, "multi") Then
			$pattern = "multi\([[:digit:]]{1,2}\)disk\(0\)rdisk\(([[:digit:]]{1,2})\)partition\(([[:digit:]])\)"
		Else
			$pattern = "scsi\([[:digit:]]{1,2}\)disk\(([[:digit:]]{1,2})\)rdisk\(0\)partition\(([[:digit:]])\)"
		EndIf

		$aData = StringRegExp($BootDevice, $pattern, 1, 1)
		If Not IsArray($aData) Then Return SetError(1)
		Return SetError(0, 0, getVolumeFromNum($aData[0], $aData[1]) )
	EndIf

	If StringInStr($tDrive, "SYSTEM") Then
		Local $isPE = RegRead("HKLM\SYSTEM\CurrentControlSet\Control", "PEFirmwareType")
		If @error Then ; Not PE
			$BootDevice = RegRead("HKLM\System\Setup", "SystemPartition")
		else	; Is PE
			$BootDevice = RegRead("HKLM\System\CurrentControlSet\Control", "PEBootRamdiskSourceDrive")
		EndIf
		Return SetError(0, 0, $BootDevice)
	EndIf
	Return SetError(1)
EndFunc ; SearchBootDrv


Func getVolumeFromNum($disk, $partition)
	Local $ReturnVaules, $ndVolume = 0
	Local $tVolume = _FindFirstVolume($ReturnVaules)
	Local $Handle = $tVolume[0]
	$aData = _DrvGetDriveNumber($ReturnVaules)
	If IsArray($aData) Then
		If ($disk = $aData[1]) And ($Partition = $aData[2]) Then
			_FindVolumeClose($Handle)
			Return SetError(0, 0, $ReturnVaules)
		EndIf
	EndIf

	While 1
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If @error or $ndVolume = 0 Then ExitLoop
		$aData = _DrvGetDriveNumber($ReturnVaules)
		If Not IsArray($aData) Then ContinueLoop
		If ($disk = $aData[1]) And ($Partition = $aData[2]) Then
			_FindVolumeClose($Handle)
			Return SetError(0, 0, $ReturnVaules)
		EndIf
	WEnd
	_FindVolumeClose($Handle)
	Return SetError(1)
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


Func _GetVolumePathName($lpszFileName)
	Local $lpszVolumePathName = DllStructCreate("wchar[255]")
	Local $ret = DllCall("Kernel32.dll", "int", "GetVolumePathNameW", "wstr", $lpszFileName, "Ptr", DllStructGetPtr($lpszVolumePathName), "dword", 255)
	Return DllStructGetData($lpszVolumePathName, 1)
EndFunc   ;=>_GetVolumePathName


Func _QualifyRootFromPath(ByRef $initPath)
	Local $sPath = _WinAPI_PathUnquoteSpaces( StringStripWS($initPath, 3) )
	Local $Pattern0 = "(\\\\\?\\)?(Volume)?\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}(\\)?"
	If StringRegExp($sPath, "^[[:alpha:]]\:") Then
		Local $tPath = _WinAPI_PathSearchAndQualify($sPath)
		$tPath = _WinAPI_PathCanonicalize($tPath)
		$initPath = $tPath
		Return SetError(0, 0, _WinAPI_GetVolumeNameForVolumeMountPoint(StringLeft($tPath, 2) & "\") )
	ElseIf StringRegExp($sPath, $Pattern0) Then
		Local $Pattern, $Pattern1, $Pattern2, $xpath
;		$Pattern1 = "(\\\\\?\\)+(Volume)+\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\}(\\)+"
		$Pattern = "(?:\\\\\?\\)?(?:Volume)?(\{[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}\})(?:\\)?(.*)"
		Local $try = StringRegExp($sPath, $Pattern, 1)
		Local $tguid = "", $tFile = ""
		If IsArray($try) Then
			$tguid = $try[0]
			If UBound($try) >1 Then	$tFile = $try[1]
		EndIf
		$sPath = "\\?\Volume" & $tguid & "\" & $tFile
		Local $Dosletter = _GetVolumePathNamesForVolumeName($sPath)
		If @error Then
			$initPath = "[Unassign]\" & $tFile
		Else
			$initPath = StringUpper(StringLeft($Dosletter, 2))& "\" & $tFile
		EndIf

		Return SetError(0, 0, $sPath & $tFile)
	EndIf
	Return SetError(1)
EndFunc  ; 	_QualifyRootFromPath


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
	Return SetError(0, 0, $lastL & ":")
EndFunc


Func _Drv2Device($sDrive)
	Local $sPath = $sDrive
	Local $tGuid = _QualifyRootFromPath($sPath) ; ByRef
	If StringRegExp($sPath, "^[[:alpha:]]\:") Then Return _WinAPI_QueryDosDevice($sDrive)
	If StringIsSpace($tGuid) Then Return SetError(1, 0 ,"")
	Local $lastL = "B:"
	If FileExists("B:") Then $lastL = FindLastDrv("CDEFGIXYZ")
	_WinAPI_SetVolumeMountPoint($lastL & "\", $tGuid)
	Local $tDrv = _WinAPI_QueryDosDevice($lastL)
;	Local $aCall = DllCall('kernel32.dll', 'dword', 'QueryDosDeviceW', 'wstr', null, 'struct*', $lastL, 'dword', 32768)
	_WinAPI_DeleteVolumeMountPoint($lastL & "\")
	Return SetError(0, 0, ($tDrv = 1) ? ("UnAssign") : ($tDrv))
EndFunc ; End =>_Drv2Device


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


Func _GetGuidFromDevice($Device)  ; "\Device\HarddiskVolume12"
	Local $pattern0 = "(?i)(^\\Device\\.+?)(?=\\)"
	Local $pattern1 = "\\Device\\HarddiskVolume([[:digit:]]{1,2})"
	Local $pattern2 = "\\Device\\HarddiskVolume[[:digit:]]{1,2}"
	If Not StringRegExp($Device, $pattern2) Then Return SetError(1, 0, "")

	Local $tDrv, $lastL = "B:"
	If FileExists("B:") Then $lastL = FindLastDrv("CDEFGIXYZ")
	Local $ReturnVaules, $ndVolume = 0

	Local $tVolume = _FindFirstVolume($ReturnVaules)
	Local $Handle = $tVolume[0]
	If @error Then Return SetError(1, 0, "")
	_WinAPI_SetVolumeMountPoint($lastL & "\", $ReturnVaules)
	If Not @error Then $tDrv = _WinAPI_QueryDosDevice($lastL)
	_WinAPI_DeleteVolumeMountPoint($lastL & "\")
	If StringInStr($tDrv, $Device) Then
		_FindVolumeClose($Handle)
		 Return $ReturnVaules
	EndIf

	While 1
		$ndVolume = _FindNextVolume($Handle, $ReturnVaules)
		If @error or $ndVolume = 0 Then ExitLoop
		_WinAPI_SetVolumeMountPoint($lastL & "\", $ReturnVaules)
		If Not @error Then $tDrv = _WinAPI_QueryDosDevice($lastL)
		_WinAPI_DeleteVolumeMountPoint($lastL & "\")
		If StringInStr($tDrv, $Device) Then ExitLoop
	WEnd
	_FindVolumeClose($Handle)
	 Return SetError(0, 0, $ReturnVaules)
EndFunc ; End =>_GetDrvFromUUID