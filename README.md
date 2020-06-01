# Days of Thunder NES (Unpublished)
This is source code for an unpublished Days of Thunder game for the NES, not to be confused with the published game released by the same publisher this game was developed for, Mindscape, in 1990. This source code was unearthed from the personal archives of Chris Oberth.

In its original state, this source code depends on a ROMulator package and specialized hardware in order to build. I've created a custom build process and thrown together a custom tool in QBASIC ("BTR_NES.EXE") to assemble everything under an INES header while keeping the whole build process under MS-DOS. The source code itself is otherwise completely untouched, with the single exception of a controller fix in NINSYSC.ASM. This fix is under an equ named "nijoygetfix" so that you can still see the original source that was in its place. An explanation of the fix is also provided in the source.

If you'd like to learn more, there's an article all about the process of recovering this source code on the [Video Game History Foundation blog](https://gamehistory.org/days-of-thunder-nes-unreleased/). For questions/feedback/etc. pertaining to the code itself, [my Twitter account](https://twitter.com/DickWhitehouse) is probably your best bet for getting a prompt response out of me, and while you're there, be sure to follow the [official VGHF Twitter account](https://twitter.com/GameHistoryOrg) too!

## Building
You'll need to build the source under an MS-DOS environment, 6.x or [DosBox](http://www.dosbox.com) will work fine. Just run BTR.BAT at the prompt and, assuming everything goes as planned, you'll end up with a BTR.NES file. This is the ROM with an INES header which can be used with most emulators, flash carts, etc. The batch file is set up to do a clean build every time, but if you want to do incremental builds, just remove the del steps at the top of the batch and you should be all set.

## File Summary
New files (with the exception of BTR_CHAR.BIN, it was recovered as-is, but from media without timestamp information):
```
03/07/2020  09:07 PM               181 BTR.BAT
02/15/2020  12:15 PM           131,072 BTR_CHAR.BIN
03/07/2020  08:01 PM            39,506 BTR_NES.EXE
03/07/2020  07:57 PM               232 BTR_NES.TXT
03/07/2020  06:42 PM                16 INES_HDR.BIN
05/16/2020  04:39 PM             1,364 README.md
```

Makefile which was modified to remove additional ROMX dependencies:
```
03/07/2020  09:11 PM             1,415 BTR
Originally dated: 02/28/1990  04:35 PM
```

Source modified to apply the input fix:
```
05/16/2020  03:18 PM            46,098 NINSYSC.ASM
Originally dated: 03/26/1990  03:00 PM
```

Untouched files:
```
03/15/1990  08:34 AM             3,943 2A.ASM
03/15/1990  09:52 AM             1,940 2A_ENDS.ASM
03/15/1990  02:06 PM             3,920 4B.ASM
11/21/1989  03:58 PM             3,162 CRASHL2.SND
02/01/1988  02:00 PM            38,613 MAKE.EXE
03/15/1990  04:59 PM             4,551 MAPSTUFF.ASM
02/09/1990  03:13 PM             5,663 NINDEF.ASM
02/12/1990  12:13 PM             4,790 NINREF.ASM
03/28/1990  04:18 PM           111,579 PB.ASM
02/27/1990  11:06 AM               306 PBLINK0.LNK
02/27/1990  11:07 AM               306 PBLINK1.LNK
02/27/1990  11:07 AM               306 PBLINK2.LNK
02/27/1990  11:07 AM               306 PBLINK3.LNK
02/27/1990  11:19 AM               306 PBLINK4.LNK
02/27/1990  11:07 AM               300 PBLINK7.LNK
02/08/1990  11:37 AM            20,317 PBSOUND.ASM
03/27/1990  03:24 PM            63,449 PERSON.ASM
03/21/1990  10:18 AM             6,096 RAMUSE.ASM
01/19/1990  12:15 PM            67,673 ROADMAPS.ASM
03/20/1990  10:14 AM            23,305 ROUTINES.ASM
11/28/1989  09:57 AM               880 SKIDF.SND
02/28/1990  03:21 PM             3,986 T_1.ASM
02/28/1990  05:04 PM             3,878 T_2.ASM
02/27/1990  03:18 PM             3,871 T_I1.ASM
02/27/1990  03:18 PM             3,873 T_I2.ASM
02/27/1990  03:18 PM             3,873 T_I3.ASM
02/27/1990  04:59 PM               360 T_L.ASM
02/28/1990  08:36 AM             1,351 T_N.ASM
02/28/1990  09:41 AM             1,393 T_O.ASM
02/28/1990  11:14 AM             2,447 T_P.ASM
03/08/1990  09:36 AM            31,377 TITLE.ASM
03/20/1990  04:51 PM            34,203 TOPVIEW.ASM
03/23/1990  02:40 PM            39,505 TRACK0.ASM
03/15/1990  03:19 PM            22,195 TRACK1.ASM
03/19/1990  10:41 AM            63,294 TRIALLAP.ASM
05/22/1989  12:33 PM           146,058 X6502.EXE
05/31/1989  03:14 PM           119,504 XLINK.EXE
```
