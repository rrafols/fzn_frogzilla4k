rem Build the original Win32 intro.
rem fuxnasm rewrites the #1.0# float literals, then nasm assembles.
rem The data tables come from ..\..\..\common\data, shared with the other ports.

if not exist ..\build mkdir ..\build

fuxnasm <base.asm             >..\build\intro.asm
fuxnasm <animateFreddy.inc    >..\build\animateFreddy.inc
fuxnasm <drawFanal.asm        >..\build\drawFanal.asm
fuxnasm <drawQuad.inc         >..\build\drawQuad.inc
fuxnasm <drawBlock.asm        >..\build\drawBlock.asm
fuxnasm <drawMultiBlock.asm   >..\build\drawMultiBlock.asm
fuxnasm <drawMultiVehicle.asm >..\build\drawMultiVehicle.asm
fuxnasm <drawVehicle.asm      >..\build\drawVehicle.asm
fuxnasm <timeCalc.asm         >..\build\timeCalc.asm

nasmw ..\build\intro.asm -i..\..\..\common\data\ -E ..\build\error.log -O3 -o ..\build\intro.exe -l ..\build\frogzilla.lst
type ..\build\error.log
