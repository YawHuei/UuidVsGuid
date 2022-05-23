The Program is compiled with AutoIt, x64 is compreesed with Upx, It can Run on Windows PE

The Program x86 Version is uncompreesed, It may be marked as a virus.
See  https://www.autoitscript.com/wiki/AutoIt_and_Malware


Generally:
The UUID is constant for the same drive/partition no matter what system it is attatched to.
But letter for each device plugged in (a, b, c, etc.) 
This means that the  identifier assigned to the device changes if it is attached in a different order.
So, In Batch File, Had better, Use UUID or GUID. 
It can also be used in unassign letter.
 

GUID Format in this DriveGetid  also is 
  "\\?\Volume{398717dc-0000-0000-0000-100000000000}\" or "\\?\Volume{398717dc-0000-0000-0000-100000000000}"
  or "{398717dc-0000-0000-0000-100000000000}\"  or "{398717dc-0000-0000-0000-100000000000}"


Examples:
In diskpart.exe
create vdisk file="\\?\Volume{398717dc-0000-0000-0000-501f00000000}\path\filed.vhdx" parent=""\\?\Volume{398717dc-0000-0000-0000-501f00000000}\path\filem.vhdx"

if exist "\\?\Volume{398717dc-0000-0000-0000-501f00000000}\path\file.ext" echo do some jobs
copy "\\?\Volume{398717dc-0000-0000-0000-501f00000000}\path\file.ext"  .
Can use with {copy, move, ...}, But bcdedit or others will generate error. (OS will redefine Locate).
Can use bcdedit.exe /store %mybcd% /set {%guid%} device vhd=[\Device\HarddiskVolume5]\win8.vhdx  


DrivegetId Command line:
"Drv4SN "E:|GUID" | Drv4FS "E:|GUID" | Drv2Label "E:|GUID" | Label2Drv "Temp" | DRV2DEVICE E: | DRV2GUID E:
GUID2Drv "GUID" | DRV2UUID "E:|GUID" | UUID2DRV UUID | UUID2GUID UUID | DRV2NUM "E:|GUID"| LASTDRV "OXYZ" | GETVOLUMES ";" | GUID2NUM "GUID"
GUID2DEVICE "GUID" | NUM2GUID "1.1|hd0,0|hd0,msdos1" | GETBOOTID "BOOT|SYSTEM" | SEARCHFILE "FilePath(?\test\tmp.txt)">tmp.bat|txt


Usage:

Drv= "C:" "D:" "E:" ... 
GUID= "\\?\Volume{398717dc-0000-0000-0000-501f00000000}\" or "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" ...


Examples are as follows:

1. 
DrivegetId.exe "Drv4SN" "E:" >tmp.txt
or 
DrivegetId.exe Drv4SN "\\?\Volume{398717dc-0000-0000-0000-501f00000000}\" >tmp.txt
set /p var=<tmp.txt
%var% is 3774697552

2.
DrivegetId.exe Drv4FS "E:" >tmp.txt
or
DrivegetId.exe Drv4FS "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" >tmp.txt
set /p var=<tmp.txt
%var% Result -> NTFS

3.
DrivegetId.exe Drv2Label "E:" >tmp.txt
or
DrivegetId.exe Drv2Label "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" >tmp.txt
set /p var=<tmp.txt
%var% Result -> Temp

4.
DrivegetId.exe Label2Drv "Temp" >tmp.txt
set /p var=<tmp.txt
%var% Result -> E: (first Find)

5.
DrivegetId.exe DRV2DEVICE "E:" >tmp.txt
set /p var=<tmp.txt
%var% Result -> \Device\HarddiskVolume8

6.
DrivegetId.exe DRV2GUID E: >tmp.txt
set /p var=<tmp.txt
Result -> \\?\Volume{398717dc-0000-0000-0000-501f00000000}

7.
DrivegetId.exe GUID2Drv "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" >tmp.txt
set /p var=<tmp.txt
%var% Result -> E:

8.
DrivegetId.exe DRV2UUID "E:" >tmp.txt
or
DrivegetId.exe DRV2UUID "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" >tmp.txt
set /p var=<tmp.txt
Result -> A0E0FD73E0FD5050 

9.
DrivegetId.exe UUID2DRV A0E0FD73E0FD5050 >tmp.txt
set /p var=<tmp.txt
Result -> E:  

10.
DrivegetId.exe DRV2NUM "E:" >tmp.bat
or
DrivegetId.exe DRV2NUM "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" >tmp.bat
call tmp.bat
The contents of tmp.bat is  
@set "onmifs=3.1:"
@set "grub4dos=(hd2,0)"
@set "grub2=(hd2,msdos1)"

11.
DrivegetId.exe LASTDRV "OXYZ" >tmp.txt
set /p var=<tmp.txt
Result ->  P:
find unassigned drive, exclude O: X : Y: Z: 

12.
DrivegetId.exe GETVOLUMES ";" >volumes.txt
list all partition information, ";" is split delimiters, shown below "1" is unassigned , "E:" is assigned
The contents of tmp.txt is 
2;"hd1,msdos1";"01D7E669AC32BD80";"UnAssign";"\\?\Volume{f8bca18c-0000-0000-0000-100000000000}\";"BOOT";"\Device\HarddiskVolume4";"NTFS";"Fixed";10238;6195 
3;"hd2,msdos1";"A0E0FD73E0FD5050";"E:";"\\?\Volume{351006ef-0000-0000-0000-100000000000}\";"Temp";"\Device\HarddiskVolume8";"NTFS";"Fixed";102399;89280
10238 is Total Space (MB), 6195 is Free Space (MB)

Can be used in batch file, shown below
set "search=A0E0FD73E0FD5050"
for /f "tokens=1-8* delims=;" %%I in ('find.exe "%search%" volumes.txt') do echo %%~I %%~J %%~K %%~L %%~M %%~O %%~P %%~Q


13.
DrivegetId.exe GUID2NUM "E:" >tmp.txt
or
GDrivegetId.exe UID2NUM "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" >tmp.txt
set /p var=<tmp.txt
%var% Result ->  hd2,msdos1


14.
DrivegetId.exe GUID2DEVICE "\\?\Volume{398717dc-0000-0000-0000-501f00000000}" >tmp.txt
or
DrivegetId.exe GUID2DEVICE "e:" >tmp.txt
set /p var=<tmp.txt
%var% Result -> \Device\HarddiskVolume8


15.
DrivegetId.exe GETBOOTID "BOOT" >tmp.txt
set /p var=<tmp.txt
%var% Result -> \\?\Volume{398717dc-0000-0000-0000-100000000000}\

DrivegetId.exe GETBOOTID "SYSTEM" >tmp.txt
set /p var=<tmp.txt

If is PE	%var% Result -> C:
If is not PE %var% Result -> \Device\HarddiskVolume1


16.
DrivegetId.exe SEARCHFILE "\test\tmp.txt" >tmp.txt
or
DrivegetId.exe SEARCHFILE "c:\test\tmp.txt" >tmp.txt
set /p var=<tmp.txt
If Found then %var% Result -> \\?\Volume{%FindVolumeGUID%}\test\tmp.txt

