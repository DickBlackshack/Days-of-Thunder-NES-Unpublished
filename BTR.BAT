echo off
del *.obj
del *.tsk
del *.map
make btr
if errorlevel=1 goto failed
BTR_NES < BTR_NES.TXT
if errorlevel=1 goto failed
echo BTR.NES written successfully.

:failed
