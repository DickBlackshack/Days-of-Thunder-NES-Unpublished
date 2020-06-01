; PB.ASM:  Nintendo Paperboy

	LINKLIST


	include nindef.asm
	include ninref.asm

anim	.macro arg1,arg2
	db arg1
	dw arg2
	.macend

animend	.macro arg1
	db 0
	dw arg1
	.macend

;===========================================================================
; CONSTANTS

debug		equ 0			;set to 0 for production
dbgnocoll	equ 0			;no collision if set
dbgobst		equ 0			;debug obstacle course
dbgperfect	equ 0			;force perfect delivery
dbgcursor	equ 0			;enable debugging cursor
dbgfire		equ 0			;fire papers continuous

;0-9 273   A-Z 290
digit0		equ 48			;character # for 0

;===========================================================================
; START OF CODE

BANK0	SECTION

	extern splitbh,splitbm,splitpalflag,splitbchrbnk,splitbsprbnk
	extern write_bigcarj
	extern sv_niscrollh
	extern sv_niscrollm
	extern buffer_slice
	extern make_track
	extern map_hskp
	extern	sliceout

	extern taskclock
	extern taskclockhi
	extern taskclockmo

	extern racetimel
	extern racetimeh
	extern racetimem

	extern practice,averagespeed

	extern dashboard

	extern vrambuf

	extern PICvramOut
	extern PICvramflag
	extern PICadrLo
	extern PICadrHi
	extern PICatime

	extern write_topview
	extern track

	extern lane1y,lane2y,lane3y,lane4y
	extern screen1

	extern	niscrolll
	extern	niscrollm
;	extern	gear
	extern	tach
	extern	plstpos
	extern	laptimeh
	extern	laptimel
	extern	oldxl
	extern	oldxh
	extern	oldxm
	extern	oldyl
	extern	oldyh
	extern	oldlap
	extern	turn
	extern	onebytexspeed
	extern	place
	extern	tires
	extern	body
	extern	dollarl
	extern	dollarh
	extern	damchange	;old x pos of damage gauge character
	extern	digmotocnt
	extern	endofraceflag
;	extern	gameoverflag
	extern	race
	extern	droneskill
	extern	gas
	extern	mytask
	extern	speedometertask
	extern	motosndtiretask
;	extern	bodytask

	extern	Lbuf

	extern	tsknums

	extern	numoutn
	extern	saved_nibnkchr
	extern	saved_nibnkspr
	extern	sndplayj
	extern	sndinitj
	extern	palgame,palgamem,meloflag,PICstringXY

	extern	finish,earnl,earnh,car,cardamage
	extern	tdollarl,tdollarh

	extern	firstpersonj,reset,space

	extern	rasterspritechr,waitxlines

	extern	newdash,starttask,write_victory

	extern	trackwrap,trackwrap1,trackwrap2,trackwrap3

	extern	trackadr
	extern	track00,track01,track02,track03,track04,track05,track06
	extern	track07,track08,track09,track10,track11,track12,track13

;===========================================================================
setupscreen
	jsr nividoff
	lda trackwrap3		;start 2 screens before checkered line
	sta niscrollm

setupscreenp
	jsr newdash
	lda #$ff
	sta niscrolll
	sta niscrollh

	jsr screen1
	dec niscrollm
	jsr screen1

	public	dashwords
dashwords
	lda space
	pha
	lda #1
	sta space

	jsr PICstring
	db 0,19
	blkb 32,$1
	db 0
	jsr PICvramOut

	jsr PICstring
	db 0,19+32
	blkb 32,$1
	db 0
	jsr PICvramOut

	jsr PICstring
	db 0,18
	blkb 32,$1
	db 0
	jsr PICvramOut

	jsr PICstring
	db 0,18+32
	blkb 32,$1
	db 0
	jsr PICvramOut

	pla
	sta space
	rts

;===========================================================================
; GAME CONTROL TASKS
;===========================================================================

; MAIN GAME TASK
	public START			;scheduled by NINSYS upon RESET


accel		equ 8		;players acceleration rate
decel		equ 10		;players deceleration rate
friction	equ 2		;off gas slowdown
maxspeed	equ 7		;maximum player speed
turnslow	equ 5
turnmed		equ 10
turnfast	equ 15
gasuse		equ $b0		;speed of gas use, smaller=faster , was $f0
tenthgal	equ gasuse/10	;tenth of a gallon

roadtop		equ 88		;was 72
roadwidth	equ 36		;was 64
lanewidth	equ roadwidth/3
lane1top	equ roadtop
lane2top	equ lane1top+lanewidth
lane3top	equ lane2top+lanewidth
;tracklength	equ 52
;trackwrap	equ 255-tracklength
damdoll		equ 12	;was 6 was 9	;number of dollars per fix




START				;entered with int off (ninmi=0)?
	lda #0
	sta ninmi

	jsr palgame
	jsr PICvramOut

	lda #1
	sta endofraceflag	;disable start button as pause button



nextrace			;beginning of main race loop

	lda race
	sta track

;setup drone skill table and track length

	jsr getraceinfoadr
	ldy #drone_iq
?move	lda (tmp),y
	sta droneskill,y
	dey
	bpl ?move

	ldy #tracklength
	lda #255
	sec
	sbc (tmp),y
	tay
	sty trackwrap
	iny
	sty trackwrap1
	iny
	sty trackwrap2
	iny
	sty trackwrap3

	ldy #tracktable
	lda (tmp),y
	sta trackadr
	iny
	lda (tmp),y
	sta trackadr+1

;=============================================================================
;RACE SCHEDULE/STANDINGS

	jsr niscrclr

	extern checkerboard
	jsr checkerboard

	lda #1
	sta nibnkchrSH

	lda #128+32
	sta space

	jsr PICstring
	db 5,4, "RACE SCHEDULE/STANDINGS",0
	jsr PICvramOut

	jsr PICstring
	db 4,6, "TRACKNAME      FINISH MONEY",0
	jsr PICvramOut

	jsr PICstring
	db 1,08," 1 DAYTONA           0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,09," 2 RICHMOND          0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,10," 3 NORTH CAROLINA    0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,11," 4 ATLANTA           0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,12," 5 DARLINGTON        0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,13," 6 BRISTOL           0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,14," 7 NORTH WILKESBORO  0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,15," 8 MARTINSVILLE      0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,16," 9 TALLADEGA         0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,17,"10 CHARLOTTE         0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,18,"11 DOVER             0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,19,"12 POCONO            0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,20,"13 MICHIGAN          0       0",0
	jsr PICvramOut
	jsr PICstring
	db 1,21,"14 PHOENIX           0       0",0
	jsr PICvramOut

	jsr PICstring
	db 19,23,"TOTAL      0",0
	jsr PICvramOut
	jsr PICstring
	db 2,25,"PRESS ANY BUTTON TO CONTINUE",0
	jsr PICvramOut



	ldx TSKcurrent
	lda #8
	sta TSKyl,x	;starting y
	lda #0
	sta TSKxl,x	;line count
?finlp
	ldx TSKcurrent
	lda #21		;x
	sta tmp
	ldy TSKyl,x	;y
	sty tmp+1

	ldy TSKxl,x
	cpy #14
	beq ?findone
	lda finish,y
	bne ?dispfin
	cpy race
	bcs ?dispfin

	ldx #21
	ldy tmp+1
	jsr PICstringXY
	db "DNF",0
	jsr PICvramOut
	jmp ?nodispfin

?dispfin
	jsr numout2	;display finishing stats
	jsr PICvramOut
?nodispfin
	ldx TSKcurrent
	inc TSKyl,x
	inc TSKxl,x
	jmp ?finlp
?findone

	lda #8
	sta TSKyl,x	;starting y
	lda #0
	sta TSKxl,x
	sta TSKxspeedl,x	;total earnings
	sta TSKxspeedh,x	;total earnings
?earnllp
	ldx TSKcurrent
	lda #28		;x
	sta tmp
	ldy TSKyl,x	;y
	sty tmp+1

	ldy TSKxl,x
	cpy #14
	beq ?earldone
	lda earnl,y
	clc
	adc TSKxspeedl,x
	sta TSKxspeedl,x
	cmp #100
	bcc ?nocarl
	inc TSKxspeedh,x
	sec
	sbc #100
	sta TSKxspeedl,x
?nocarl	lda earnl,y
	jsr numout2		;diplay race winnings low
	jsr PICvramOut
	ldx TSKcurrent
	inc TSKyl,x
	inc TSKxl,x
	jmp ?earnllp
?earldone

	lda #8
	sta TSKyl,x	;starting y
	lda #0
	sta TSKxl,x

?earnhlp
	ldx TSKcurrent
	lda #25		;x
	sta tmp
	ldy TSKyl,x	;y
	sty tmp+1

	ldy TSKxl,x
	cpy #14
	beq ?earhdone
	lda earnh,y
	clc
	adc TSKxspeedh,x
	sta TSKxspeedh,x
	lda earnh,y
	jsr numout		;diplay race winnings high
	jsr PICvramOut
	ldx TSKcurrent
	inc TSKyl,x
	inc TSKxl,x
	jmp ?earnhlp
?earhdone

;display total earnings
	lda #28
	sta tmp		;x
	lda #23
	sta tmp+1	;y
	lda TSKxspeedl,x
	jsr numout2
	jsr PICvramOut
	ldx TSKcurrent

	lda #25
	sta tmp		;x
	lda #23
	sta tmp+1	;y
	lda TSKxspeedh,x
	jsr numout
	jsr PICvramOut


;fragment
; suppress leading zeroes in finish, earnings and total earnings
	extern	zsuppress0		;suppress on screen 0
	txa				;save current X
	pha

	lda	#5			;length of field
	ldx	#25			;column of earnings
	ldy	#8			;first row of earnings
?10	jsr	zsuppress0
	iny
	cpy	#22
	bne	?10

	lda	#5			;length of field to zero suppress
	ldx	#25			;total race earnings field column
	ldy	#23			;row
	jsr	zsuppress0

	lda	#1			;length of field
	ldx	#21			;column of finishing position
	ldy	#8			;first row finishing positions
?20	jsr	zsuppress0
	iny
	cpy	#22
	bne	?20

	pla				;restore current x
	tax				;
	

	jsr nividon

	lda #nibgblk+niobjblk+niobjlblk+nibglblk	;turn off left column blanking
	sta	nicr1SH
	lda #" "
	sta space

	dec ninmi	;turn on int


?waitfornobut3
	lda #1
	jsr TSKwait

	lda nijoy
	bne ?waitfornobut3

	lda #1
	jsr sndinitj

?waitforbut3
	lda #1
	jsr TSKwait
	jsr nirandom	;randomize the random routine

	jsr sndplayj

	lda nijoy
	beq ?waitforbut3
	jmp ?continue




	lda #nibutA
	bit nijoy
	beq ?testB
	jmp ?continue
?testB
	lda #nibutB
	bit nijoy
	beq ?waitforbut3

;practice mode select track

	lda #1
	sta practice

	lda #0			;car pointer
	sta PICxhi,x
	sta PICyhi,x
	lda #20
	sta PICxlo,x
	lda #70
	sta PICylo,x

	jsr PICaput
	dw  acar3

	lda #niup
	bit nijoy
	beq ?notup

?notup











?continue
	lda #0
	sta practice

;test for game over condition (finished race #14)
	ldy race
	cpy #14
	beq gameover

;test for game over condition (not enough money to repair any car)
	ldy cardamage+0
	jsr afford
	bcs ?notoverj
	ldy cardamage+1
	jsr afford
	bcs ?notoverj
	ldy cardamage+2
	jsr afford
	bcc gameover
?notoverj	jmp notover

ycoord	db 5,6,7,8,9,10,11,12
hnamel	db $60,$71,$82,$93,$a4,$b5,$c6,$d7
hscore	db 15,32,49,66,83,100,117,134	;offset of high score byte from $760

gameover
	inc ninmi	;turn off int
	jsr nividoff
	jsr write_victory
	ldx TSKcurrent

	lda #0
	sta mytask	;mytask will be used to hold index
?insertlp
	ldx mytask
	ldy hscore,x
	lda $760,y
	ldx TSKcurrent
	cmp TSKxspeedh,x
	bcc ?insert
	bne ?next
;testlow
	lda $761,y
	cmp TSKxspeedl,x
	bcc ?insert
	beq ?insert
?next	inc mytask
	lda mytask
	cmp #8
	bne ?insertlp
	jmp ?noinsert

?insert
	lda mytask
	cmp #7
	beq ?insertinfo	;no need to move if last entry

	lda #6		;start by moving entry 7 to 8
	sta tmp
?movenext
	ldx tmp
	ldy hnamel,x
	ldx #17
?movlp	lda $700,y
	sta $700+$11,y
	iny
	dex
	bne ?movlp

	lda tmp
	cmp mytask
	beq ?insertinfo
	dec tmp
	jmp ?movenext
?insertinfo
	ldx tmp
	ldy hnamel,x
	ldx #0
?putlp	lda name,x
	sta $700,y
	iny
	inx
	cpx #15
	bne ?putlp
	ldx TSKcurrent
	lda TSKxspeedh,x
	sta $700,y
	lda TSKxspeedl,x
	sta $701,y

?noinsert

;output high scores & names

	lda #" "
	sta space
	lda #0
	sta mytask	;mytask will be used to hold index
?hnamelp
	ldx mytask
	lda #6		;x coord of name
	ldy ycoord,x	;y coord of name
	jsr PICcurSet	;set the cursor
	ldx mytask
	lda hnamel,x
	ldy #7
	jsr PICstring2
	jsr PICvramOut
	lda #22		;x
	sta tmp
	ldx mytask
	lda ycoord,x	;y coord
	sta tmp+1
	ldy hscore,x
	lda $760,y
	jsr numout
	jsr PICvramOut
	lda #25		;x
	sta tmp
	ldx mytask
	lda ycoord,x	;y coord
	sta tmp+1
	ldy hscore,x
	iny
	lda $760,y
	jsr numout2
	jsr PICvramOut
	inc mytask
	lda mytask
	cmp #8
	bne ?hnamelp


; suppress leading zeroes in finish, earnings and total earnings

	lda	#5			;length of field
	ldx	#22			;column of earnings
	ldy	#5			;first row of earnings
?10	jsr	zsuppress0
	iny
	cpy	#13
	bne	?10


	jsr nividon

	lda #nibgblk+niobjblk+niobjlblk+nibglblk	;turn off left column blanking
	sta nicr1SH

	dec ninmi	;turn on int
?nobut
	lda #1
	jsr TSKwait

	lda #nistart
	bit joy0
	bne ?nobut
?hold
	lda #1
	jsr TSKwait

	lda #nistart
	bit joy0
	beq ?hold
	jmp reset


notover


;=============================================================================
;OVERHEAD
	inc ninmi	;turn off int
	jsr nividoff

	lda nibnksprSH
	sta saved_nibnkspr
	lda nibnkchrSH
	sta saved_nibnkchr
	lda #4
	sta nibnksprSH
	lda #5
	sta nibnkchrSH

	jsr write_topview

	lda #0
	sta dashboard
	lda #$f0
	sta rasterspritey
	lda #0
	sta splitbsprbnk
	lda #1
	sta splitbchrbnk

	jsr nividon

	dec ninmi	;turn on int

?waitfornobut2
	lda #1
	jsr TSKwait

	lda nijoy
	bne ?waitfornobut2

	lda #2
	jsr sndinitj

?waitforbut2
	lda #1
	jsr TSKwait
	jsr nirandom	;randomize the random routine

	jsr sndplayj

	lda nijoy
	beq ?waitforbut2

;=============================================================================
;GARAGE
	inc ninmi	;turn off int
	jsr niscrclr
	jsr palgame
	jsr PICvramOut

	extern	write_garage		;in ROUTINES.ASM Should be is a separate
	jsr	write_garage		;bank to give more room for main game

	lda #128+32
	sta space

	lda #7
	sta tmp
	lda #27
	sta tmp+1
	lda tdollarl
	jsr numout2		;display tdollarl
	jsr PICvramOut
	lda #4
	sta tmp
	lda #27
	sta tmp+1
	lda tdollarh
	jsr numout		;display tdollarh
	jsr PICvramOut


	jsr PICstring
	db 9,27,"0",0		;add a zero to all money
	jsr PICvramOut

	jsr PICstring
	db 9,25,"0",0		;add a zero to all money
	jsr PICvramOut



;are any cars supposed to look damaged?

;paint damaged background car/s

	lda car
	pha
	lda #0
	sta space
	sta car

?damlp	ldx car
	lda cardamage,x
	beq ?good0
	jsr damcarout
?good0	inc car
	lda car
	cmp #3
	bne ?damlp

	pla
	sta car

	jsr nividon

	lda #nibgblk+niobjblk+niobjlblk+nibglblk	;turn off left column blanking
	sta nicr1SH

	dec ninmi	;turn on int


?waitfornobut4
	lda #1
	jsr TSKwait
	lda nijoy
	bne ?waitfornobut4

;prepare for hoisting
	jsr TSKschedule
	dw donothing

	sta mytask	;save dummy tasks index
	tax		;use another tasks sprite (car is to big)

	lda #0
	sta PICxhi,x
	sta PICyhi,x

	ldx TSKcurrent

	lda #8
	sta nibnksprSH
	sta nibnkchrSH

	lda #0
	sta rasterspritechr

	lda #0
	sta PICxhi,x
	sta PICyhi,x

hoistcar

	ldx car
	lda gcary,x	;car x
	pha
	lda gcarx,x	;car y
	ldx TSKcurrent
	sta PICxlo,x
	ldy mytask
	sta PICxlo,y
	pla
	sta PICylo,x
	clc
	adc #8
	sta PICylo,y

	ldy car
	lda cardamage,y
	bne ?damcarsp

	jsr PICaput
	dw  gcara
	ldx mytask
	jsr PICaput
	dw  gcarb
	jmp ?spritedone

?damcarsp
	jsr PICaput
	dw  gcarad
	ldx mytask
	jsr PICaput
	dw  gcarbd
?spritedone
	lda #1		;allow sprite car to cover background car
	jsr TSKwait

	lda #0
	sta space

;erase background car

	ldx car
	lda bcarx,x
	ldy bcary,x
	tax
	jsr PICstringXY
	db $a,$a,$a,0
	dex
	dex
	iny
	jsr PICstringXY
	db $a,$a,$a,$a,$a,$a,0
	dex
	iny

	lda car
	beq ?car0
	jsr PICstringXY
	db $d9,$a,$a,$dd,$a,$a,$a,0
	dex
	iny
	jsr PICstringXY
	db $db,$a,$a,$a,$dd,$a,$a,$a,0
	iny
	jmp ?cont1
?car0
	jsr PICstringXY
	db $a,$a,$a,$dd,$a,$a,$a,0
	dex
	iny
	jsr PICstringXY
	db $a,$a,$a,$a,$dd,$a,$a,$a,0
	iny
?cont1
	lda car
	cmp #2
	beq ?car2
	jsr PICstringXY
	db $a,$a,$a,$a,$dd,$a,$a,$da,0
	iny
	jsr PICstringXY
	db $a,$a,$a,$a,$de,$a,$dc,0
	jmp ?cont2
?car2
	jsr PICstringXY
	db $a,$a,$a,$a,$dd,$a,$a,$a,0
	iny
	jsr PICstringXY
	db $a,$a,$a,$a,$de,$a,$a,0
?cont2

	lda #1		;enough strings to output
	jsr TSKwait

	ldx car
	lda bcary,x
	clc
	adc #6
	tay
	lda bcarx,x
	tax
	dex
	dex
	dex
	dex
	jsr PICstringXY
	db $a,$a,$a,$a,$a,$a,0
	iny
	jsr PICstringXY
	db $a,$a,$a,$a,0

	ldx TSKcurrent
	lda #32		;distance to move car up
	sta TSKlap,x

?up
	lda #1
	jsr TSKwait

	lda #$35	;up sound
	sta $400c
	lda TSKlap,x
	lsr a
	sta $400e
	lda #$ff
	sta $400f

	jsr PICydec
	ldx mytask
	jsr PICydec
	ldx #60
	jsr waitxlines
	ldx TSKcurrent
	dec TSKlap,x
	bne ?up

	lda #0		;turn off sound
	sta niwrst
	lda #$0f
	sta niwrst

;end of hoist up

;diplay car stats
	lda #" "+128
	sta space

	ldy car
	lda cardamage,y
	tay
	jsr damage2dollar
	lda #7
	sta tmp
	lda #25
	sta tmp+1
	lda TSKxl,x
	jsr numout2		;display dollar damage
	lda #4
	sta tmp
	lda #25
	sta tmp+1
	ldx TSKcurrent
	lda TSKxh,x
	jsr numout		;display dollar damage

	lda car
	bne ?cars2
?cars1
	jsr PICstring
	db 19,23,"1",0
	jsr PICstring
	db 26,25,"350",0
	jsr PICstring
	db 24,26,"  1-1",0
	jsr PICstring
	db 24,27,"LOOSE",0
	jmp ?cdone

?cars2	cmp #1
	bne ?cars3
	jsr PICstring
	db 19,23,"2",0
	jsr PICstring
	db 26,25,"327",0
	jsr PICstring
	db 24,26,"  1-1",0
	jsr PICstring
	db 24,27,"TIGHT",0
	jmp ?cdone

?cars3
	jsr PICstring
	db 19,23,"3",0
	jsr PICstring
	db 26,25,"327",0
	jsr PICstring
	db 24,26,"1-.75",0
	jsr PICstring
	db 24,27,"LOOSE",0

?cdone	lda #0
	sta space

?waitforselect
	lda #1
	jsr TSKwait
	jsr nirandom	;randomize the random routine

	lda #niselect
	bit nijoy
	bne ?hodo
	jmp ?nosel
?hodo
;hoist down
	lda #0
	sta TSKlap,x
?down
	lda #1
	jsr TSKwait

	lda #$35	;down sound
	sta $400c
	lda TSKlap,x
	lsr a
	sta $400e
	lda #$ff
	sta $400f

	jsr PICyinc
	ldx mytask
	jsr PICyinc
	ldx #60
	jsr waitxlines
	ldx TSKcurrent
	inc TSKlap,x
	lda TSKlap,x
	cmp #32		;distance to move car down
	bne ?down

	lda #0		;turn off sound
	sta niwrst
	lda #$0f
	sta niwrst

;paint background car

	ldx car
	lda cardamage,x
	beq ?goodcar
	jmp ?damagedcar
?goodcar
	lda bcarx,x
	ldy bcary,x
	tax
	jsr PICstringXY
	db $6b,$6c,$6d,0
	dex
	dex
	iny
	jsr PICstringXY
	db $75,$76,$77,$78,$79,$7a,0
	dex
	iny

	lda car
	beq ?car0b
	jsr PICstringXY
	db $9b,$81,$82,$83,$84,$85,$86,0
	dex
	iny
	jsr PICstringXY
	db $a4,$8b,$8c,$8d,$8e,$8f,$90,$91,0
	iny
	jmp ?cont1b
?car0b
	jsr PICstringXY
	db $da,$81,$82,$83,$84,$85,$86,0
	dex
	iny
	jsr PICstringXY
	db $dc,$8b,$8c,$8d,$8e,$8f,$90,$91,0
	iny
?cont1b
	lda car
	cmp #2
	beq ?car2b
	jsr PICstringXY
	db $94,$95,$96,$97,$98,$99,$9a,$b7,0
	iny
	jsr PICstringXY
	db $9e,$9f,$a0,$a1,$a2,$a3,$be,0
	jmp ?cont2b
?car2b
	jsr PICstringXY
	db $94,$95,$96,$97,$98,$99,$9a,$b7,0
	iny
	jsr PICstringXY
	db $9e,$9f,$a0,$a1,$a2,$a3,$be,0
?cont2b

	lda #1		;enough strings to output
	jsr TSKwait

	ldx car
	lda bcary,x
	clc
	adc #6
	tay
	lda bcarx,x
	tax
	dex
	dex
	dex
	dex
	jsr PICstringXY
	db $a6,$a7,$a8,$a9,$aa,$ab,0
	iny
	jsr PICstringXY
	db $af,$b0,$b1,$b2,0
	jmp ?paintcardone


?damagedcar
	lda bcarx,x
	ldy bcary,x
	tax
	jsr PICstringXY
	db $6b,$6c,$6d,0
	dex
	dex
	iny
	jsr PICstringXY
	db $75,$e1,$e2,$78,$e3,$e4,0
	dex
	iny

	lda car
	beq ?car0bd
	jsr PICstringXY
	db $9b,$81,$82,$e5,$e6,$e7,$e8,0
	dex
	iny
	jsr PICstringXY
	db $a4,$e9,$ea,$eb,$ec,$ed,$90,$ee,0
	iny
	jmp ?cont1bd
?car0bd
	jsr PICstringXY
	db $da,$81,$82,$e5,$e6,$e7,$e8,0
	dex
	iny
	jsr PICstringXY
	db $dc,$e9,$ea,$eb,$ec,$ed,$90,$ee,0
	iny
?cont1bd
	lda car
	cmp #2
	beq ?car2bd
	jsr PICstringXY
	db $ef,$f0,$f1,$f2,$f3,$f4,$9a,$9b,0
	iny
	jsr PICstringXY
	db $f5,$f6,$f7,$f8,$f9,$a3,$a4,0
	jmp ?cont2bd
?car2bd
	jsr PICstringXY
	db $ef,$f0,$f1,$f2,$f3,$f4,$9a,$b7,0
	iny
	jsr PICstringXY
	db $f5,$f6,$f7,$f8,$f9,$a3,$be,0
?cont2bd

	lda #1		;enough strings to output
	jsr TSKwait

	ldx car
	lda bcary,x
	clc
	adc #6
	tay
	lda bcarx,x
	tax
	dex
	dex
	dex
	dex
	jsr PICstringXY
	db $a6,$fa,$fb,$fc,$aa,$ab,0
	iny
	jsr PICstringXY
	db $af,$fd,$fe,$b2,0


?paintcardone
	inc car
	lda car
	cmp #3
	bne ?nowrap0
	lda #0
	sta car
?nowrap0
	jmp hoistcar



?nosel

	lda #nibutA
	bit nijoy
	bne ?usethiscar
	lda #nibutB
	bit nijoy
	bne ?usethiscar
	lda #nistart
	bit joy0
	bne ?usethiscar
	jmp ?waitforselect

?usethiscar
	ldy car
	lda cardamage,y
	bne ?canhepay
	jmp downout

?canhepay
	tay
	jsr afford
	bcs repair
?poor
	lda #0
	sta PICvramflag
	lda #" "+128
	sta space
	jsr PICstring
	db 8,23, "NOT ENOUGH MONEY",0
	lda #1
	sta PICvramflag
	lda #0
	sta space

	lda #%11010110
	sta $4000
	lda #%11000100
	sta $4001
	lda #%00000000
	sta $4002
	lda #$fc
	sta $4003

?waitforselpoor
	lda #1
	jsr TSKwait
	lda #niselect
	bit nijoy
	beq ?waitforselpoor

	lda #" "+128
	sta space
	jsr PICstring
	db 8,23, "      CAR #     ",0
	lda #0
	sta space
	jmp ?hodo



;repair selected car
repair
	lda #128+32
	sta space
	ldy #damdoll		;number of dollars per fix
?decdollar
	dec tdollarl
	bpl ?nocary
	lda #99
	sta tdollarl
	dec tdollarh
	bpl ?nocary
	lda #0			;should never get here
	sta tdollarh
	sta tdollarl
	jmp ?fixed
?nocary
	dey
	bne ?decdollar

	lda #7
	sta tmp
	lda #27
	sta tmp+1
	lda tdollarl
	jsr numout2		;display dollarl
	lda #4
	sta tmp
	lda #27
	sta tmp+1
	lda tdollarh
	jsr numout		;display dollarh


	lda #4
	jsr TSKwait

	lda #$14
	sta nidutyD
	lda #$85
	sta nifreqD
	lda #$18
	sta nilengthD

	ldx car
	dec cardamage,x
	bne repair

?fixed
	ldx TSKcurrent

	jsr PICaput
	dw  gcara
	ldx mytask
	jsr PICaput
	dw  gcarb

	lda #60		;show car as fixed for a while
	jsr TSKwait

downout
	ldx TSKcurrent

	lda #0
	sta space

	lda #0
	sta TSKlap,x
?down
	lda #1
	jsr TSKwait

	lda #$35	;down sound
	sta $400c
	lda TSKlap,x
	lsr a
	sta $400e
	lda #$ff
	sta $400f

	jsr PICyinc
	ldx mytask
	jsr PICyinc
	ldx #60
	jsr waitxlines
	ldx TSKcurrent
	inc TSKlap,x
	lda TSKlap,x
	cmp #32		;distance to move car down
	bne ?down

	lda #0		;turn off sound
	sta niwrst
	lda #$0f
	sta niwrst

;earse hoist shaft
	ldx car
	lda bcarx,x
	ldy bcary,x
	tax
	iny
	jsr PICstringXY
	db 10,0
	iny
	jsr PICstringXY
	db 10,0
	iny
	jsr PICstringXY
	db 10,0
	iny
	jsr PICstringXY
	db 10,0
	iny
	jsr PICstringXY
	db 10,0

	lda #20		;wait at bottom
	jsr TSKwait

	jsr skidsound

	lda #110	;distance to move car out
	sta TSKlap,x
?out
	lda #1
	jsr TSKwait

	lda #$21	;set sprite priority behind background
	sta PICattr,x
	ldy mytask
	sta PICattr,y

	jsr PICyinc
	jsr PICyinc
	jsr PICxdec
	jsr PICxdec
	ldx mytask
	jsr PICyinc
	jsr PICyinc
	jsr PICxdec
	jsr PICxdec
;exit angle
	ldx TSKcurrent
	lda TSKlap,x
	and #1
	bne ?noangle
	jsr PICxdec
	ldx mytask
	jsr PICxdec

?noangle
	ldx #60
	jsr waitxlines
	ldx TSKcurrent
	dec TSKlap,x
	bne ?out

;	lda #10		;wait after exit
;	jsr TSKwait

	lda #0		;turn off sprites
	sta PICadrLo,x
	sta PICadrHi,x

	ldx mytask
	jsr TSKcancel		;cancel the second sprite task from garage car
	ldx TSKcurrent

	lda #" "
	sta space

	jmp qualify



donothing
	jsr TSKsuspend
	rts

gcarx	db 48,96,144
gcary	db 95,111,127

bcarx	db 10,16,22
bcary	db  5,7,9

gcara
	anim	2,gcar1
	animend	gcara
gcarb
	anim	2,gcar2
	animend	gcarb


gcar1	db 8, 7,$1 ; width, height, color code
	DB	$0A,$0A,$0A,$0A,$6B,$6C,$6D,$0A
	DB	$0A,$0A,$75,$76,$77,$78,$79,$7A
	DB	$0A,$DA,$81,$82,$83,$84,$85,$86
	DB	$DC,$8B,$8C,$8D,$8E,$8F,$90,$91
	DB	$94,$95,$96,$97,$98,$99,$9A,$B7
	DB	$9E,$9F,$A0,$A1,$A2,$A3,$BE,$0A
	DB	$A6,$A7,$A8,$A9,$AA,$AB,$0A,$0A

gcar2	db 4, 1,$1 ; width, height, color code
	DB	$AF,$B0,$B1,$B2


gcarad				;damaged car stuff
	anim	2,gcar1d
	animend	gcarad
gcarbd
	anim	2,gcar2d
	animend	gcarbd


gcar1d	db 8, 7,$1 ; width, height, color code
	DB	$0A,$0A,$0A,$0A,$6B,$6C,$6D,$0A
	DB	$0A,$0A,$75,$e1,$e2,$78,$e3,$e4
	DB	$0A,$DA,$81,$82,$e5,$e6,$e7,$e8
	DB	$DC,$e9,$ea,$eb,$ec,$ed,$90,$ee
	DB	$ef,$f0,$f1,$f2,$f3,$f4,$9A,$B7
	DB	$f5,$f6,$f7,$f8,$f9,$A3,$BE,$0A
	DB	$A6,$fa,$fb,$fc,$AA,$AB,$0A,$0A

gcar2d	db 4, 1,$1 ; width, height, color code
	DB	$AF,$fd,$fe,$B2




damage2dollar
	ldx TSKcurrent
	lda #0
	sta TSKxh,x
	cpy #0
	beq ?rdone
?mrep
	clc
	adc #damdoll		;number of dollars per fix
	cmp #100
	bcc ?not100
	sec
	sbc #100
	inc TSKxh,x
?not100	dey
	bne ?mrep
?rdone	sta TSKxl,x
	rts


afford				;clear carry if not enough money to repair
	jsr damage2dollar	;enter with damage in y
	lda tdollarh
	cmp TSKxh,x
	bcc ?poor
	bne ?ok
	lda tdollarl
	cmp TSKxl,x
	bcs ?ok
?poor
	clc
	rts
?ok
	sec
	rts


damcarout
	lda bcarx,x
	ldy bcary,x
	tax
	jsr PICstringXY
	db $6b,$6c,$6d,0
	dex
	dex
	iny
	jsr PICstringXY
	db $75,$e1,$e2,$78,$e3,$e4,0
	dex
	iny

	lda car
	beq ?car0bd
	jsr PICstringXY
	db $9b,$81,$82,$e5,$e6,$e7,$e8,0
	dex
	iny
	jsr PICstringXY
	db $a4,$e9,$ea,$eb,$ec,$ed,$90,$ee,0
	iny
	jmp ?cont1bd
?car0bd
	jsr PICstringXY
	db $da,$81,$82,$e5,$e6,$e7,$e8,0
	dex
	iny
	jsr PICstringXY
	db $dc,$e9,$ea,$eb,$ec,$ed,$90,$ee,0
	iny
?cont1bd
	lda car
	cmp #2
	beq ?car2bd
	jsr PICstringXY
	db $ef,$f0,$f1,$f2,$f3,$f4,$9a,$9b,0
	iny
	jsr PICstringXY
	db $f5,$f6,$f7,$f8,$f9,$a3,$a4,0
	jmp ?cont2bd
?car2bd
	jsr PICstringXY
	db $ef,$f0,$f1,$f2,$f3,$f4,$9a,$b7,0
	iny
	jsr PICstringXY
	db $f5,$f6,$f7,$f8,$f9,$a3,$be,0
?cont2bd
	tya
	pha
	jsr PICvramOut		;enough strings to output
	pla
	tay

	ldx car
	lda bcary,x
	clc
	adc #6
	tay
	lda bcarx,x
	tax
	dex
	dex
	dex
	dex
	jsr PICstringXY
	db $a6,$fa,$fb,$fc,$aa,$ab,0
	iny
	jsr PICstringXY
	db $af,$fd,$fe,$b2,0
	jsr PICvramOut		;enough strings to output
	rts

;=============================================================================
qualify

	lda #$fd
	sta rasterspritechr

	jsr firstpersonj


 if 0
	inc ninmi	;turn off int
	jsr palgame

	lda saved_nibnkchr
	sta nibnkchrSH
	lda saved_nibnkspr
	sta nibnksprSH

	jsr setupscreen

	jsr TSKvblank
	dw sliceout		;place new map slices in blanked screen column


; qualifying lap

	lda #0
	sta plstpos

	jsr TSKschedule
	dw PLAYER

	jsr TSKschedule
	dw speedometer

	jsr TSKschedule
	dw motosndtire

	jsr nividon
	lda #1
	sta PICvramflag
	sta dashboard
	lda #dashy
	sta rasterspritey

	lda #0
	sta taskclock
	sta taskclockhi
	dec ninmi	;turn on int

?qlapping
	lda #1
	jsr TSKwait

	lda #13
	sta tmp
	lda #22
	sta tmp+1
	lda taskclockhi
	jsr numout

	lda #16
	sta tmp
	lda #22
	sta tmp+1
	lda taskclock
	jsr numout

	jsr PICstring
	db 16,22,"[",0

	ldy mytask
	lda TSKlap,y
	cmp #1		;1=no qualify lap  2= 1 qualifying lap
	bne ?qlapping


	lda taskclockhi		;get lap time
	sta laptimeh
	lda taskclock
	sta laptimel

 endif



	inc ninmi	;turn off int

	jsr niscrclr

	lda #1
	sta nibnkchrSH
	lda #0
	sta nibnksprSH
	sta vrambp
	sta vrambuf

	jsr palgame
	jsr PICvramOut

	jsr checkerboard
	lda #128+32
	sta space

;TURN OFF EVERYTHING
;	ldx mytask
;	jsr TSKcancel
;	ldx speedometertask
;	jsr TSKcancel
;	ldx motosndtiretask
;	jsr TSKcancel

	jsr TSKvblank
	dw  0		;no vblank routine

	lda #$f0
	sta rasterspritey
	lda #0
	sta dashboard

	sta PICvramflag
	sta vrambp
	sta vrambuf

	sta niscrollv
	sta sv_niscrollh
	sta sv_niscrollm
	sta niscrollh
	sta niscrollm


	jsr PICstring
	db 1,3, " TIME  POSITION DRIVER",0
	jsr PICvramOut

;my best time has been 39:43
;my best time has been 40:11

	jsr PICstring
	db 1,5, " 40:00     1    ROWDY BURNS",0
	jsr PICvramOut
	jsr PICstring
	db 1,7, " 40:30     2    RUSS WHEELER",0
	jsr PICvramOut
	jsr PICstring
	db 1,9, " 41:00     3    SKID MAGURSKI",0
	jsr PICvramOut
	jsr PICstring
	db 1,11," 41:30     4    OTTO MOTO",0
	jsr PICvramOut
	jsr PICstring
	db 1,13," 42:00     5    EARL CHANGE",0
	jsr PICvramOut
	jsr PICstring
	db 1,15," 42:30     6    M.T. TANK",0
	jsr PICvramOut
	jsr PICstring
	db 1,17," 43:00     7    SMOKEY EXHAUST",0
	jsr PICvramOut
	jsr PICstring
	db 1,19," 43:30     8    A.C. PLUGGS",0
	jsr PICvramOut
	jsr PICstring
	db 1,21," 44:00     9    MANNY FOLDS",0
	jsr PICvramOut
	jsr PICstring
	db 1,23," 44:30    10    FIREBALL KELLY",0
	jsr PICvramOut

; calc position

	ldy #$ff
?slower	lda laptimeh
	iny
	cpy #9
	beq ?good
	cmp qtimeh,y
	beq ?chklow
	bcc ?good
	jmp ?slower

?chklow	lda laptimel
	cmp qtimel,y
	beq ?good
	bcc ?good
	jmp ?slower
?good	tya
	sta plstpos
	asl a
	clc
	adc #5		;y pos of list
	sta tmp+1
	pha		;save y coord for the rest of the prints
	lda #2
	sta tmp
	lda laptimeh
	jsr numout2

	pla
	pha
	sta tmp+1
	lda #5
	sta tmp
	lda laptimel
	jsr numout2

	jsr PICvramOut


;	pla
;	pha
;	tay		;the y coordinate
;	lda #1
;	jsr PICcurSet			;set the cursor
;
;	lda #" "
;	sta numoutn
;	lda #0
;	sta numoutn+1
;
;	lda #<numoutn
;	ldy #>numoutn
;	jsr PICstring2

	pla
	pha
	tay		;the y coordinate
	ldx #4
	jsr PICstringXY			;set the cursor
	db ":",0




;test name
;	ldy #11
;tname	lda myname,y
;	sta name,y
;	dey
;	bpl tname




;output players name
	pla
	tay
	lda #17		;x coord of name
	jsr PICcurSet			;set the cursor

	lda #<name
	ldy #>name
	jsr PICstring2
	jsr PICvramOut


	jsr nividon
	lda #nibgblk+niobjblk+niobjlblk+nibglblk	;turn off left column blanking
	sta nicr1SH
	lda #" "
	sta space

	dec ninmi	;turn on int


?waitfornobut
	lda #1
	jsr TSKwait

	lda nijoy
	bne ?waitfornobut


	lda #3
	jsr sndinitj

?waitforbut
	lda #1
	jsr TSKwait
	jsr nirandom	;randomize the random routine

	jsr sndplayj

	lda nijoy
	beq ?waitforbut

	lda #0		;turn off music
	sta niwrst
	lda #$0f
	sta niwrst

	inc ninmi	;turn off int

	lda meloflag
	bne ?melo
	jsr palgame
	jmp ?nomelo
?melo	jsr palgamem
?nomelo

	jsr setupscreen

	jsr TSKvblank
	dw sliceout		;place new map slices in blanked screen column
	dec ninmi	;turn on int

	jsr nividon

	lda #1
	sta dashboard
	sta splitpalflag
	lda #dashy
	sta rasterspritey

	lda #10
	sta splitbsprbnk
	sta splitbchrbnk

	lda #11
	sta nibnkchrSH

; start race

	jsr TSKschedule
	dw PLAYER

	jsr TSKschedule
	dw HDRONE
	sta tsknums
	tax
	lda #0
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+1
	tax
	lda #1
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+2
	tax
	lda #2
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+3
	tax
	lda #3
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+4
	tax
	lda #4
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+5
	tax
	lda #5
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+6
	tax
	lda #6
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+7
	tax
	lda #7
	sta TSKcarnum,x

	jsr TSKschedule
	dw HDRONE
	sta tsknums+8
	tax
	lda #8
	sta TSKcarnum,x


	jsr TSKschedule
	dw speedometer

	jsr TSKschedule
	dw motosndtire

;	jsr TSKschedule
;	dw bodycondition

	lda #1
	sta PICvramflag

	lda #0			;start race clock
	sta taskclock
	sta taskclockhi
	sta taskclockmo
	sta endofraceflag	;also enables start button as pause

	ldx TSKcurrent
	stx starttask
	lda #0			;flag position
	sta PICxhi,x
	sta PICyhi,x
	lda #207
	sta PICxlo,x
	lda #51
	sta PICylo,x

	jsr TSKsuspend

;next rts loops to here
;MAIN START TASK LOOP=========================================================


;	lda #0
;	sta body	;INVINCIBLE

	lda body
	cmp #87			;length of gauge. (was 104 for old dash)
	bcs ?endrace

	lda gas
	bmi ?endrace

	jsr getraceinfoadr
	ldy mytask
	lda TSKlap,y
	sec
	sbc #1
	ldy #racelaps
	cmp (tmp),y		;length of race
	beq ?finishline
	clc
	adc #1
	cmp (tmp),y		;length of race
	beq ?lastlaptest
	rts			;comes back to last TSKsuspend after raster

;-----------------------------------------------------------------------------

?lastlaptest
	lda PICadrLo,x
	ora PICadrHi,x
	beq ?lastlap		;branch if no flag is out
	rts			;comes back to last TSKsuspend after raster

;-----------------------------------------------------------------------------

?lastlap
	jsr PICaput
	dw  whiteflag
	rts			;comes back to last TSKsuspend after raster

;=============================================================================

?finishline
	jsr PICaput
	dw  checkflag

	ldx mytask
	dec TSKlap,x
	jsr displaylap		;correct lap display
	ldx TSKcurrent

	ldy race
	lda place
	sta finish,y
	jmp ?noblackflag
?endrace
	ldy race
	lda #0
	sta finish,y
	jsr PICaput
	dw  blackflag
?noblackflag
	lda #1
	sta endofraceflag
	ldx mytask
	jsr endskid

	lda body
	ldy car
	sta cardamage,y

	lda taskclock		;save total race time
	sta racetimel
	lda taskclockhi
	sta racetimeh
	lda taskclockmo
	sta racetimem


	ldx TSKcurrent
	lda #150
	jsr TSKwait

;damage repair used to be here

	lda #100
	jsr TSKwait

	lda #0		;turn off flag sprites
	sta PICadrLo,x
	sta PICadrHi,x

	inc ninmi	;turn off int

;123 place bonus
	ldy race
	lda finish,y
	cmp #1
	beq ?bonus1
	cmp #2
	beq ?bonus2
	cmp #3
	beq ?bonus3
	jmp ?nobonus
?bonus1
	inc dollarh	;$3000 dollars for first place
?bonus2
	inc dollarh	;$2000 dollars for first place
?bonus3
	inc dollarh	;$1000 dollars for first place
?nobonus


;save earnings for this race
	ldy race
	lda dollarl
	sta earnl,y
;add them to your total dollars
	clc
	adc tdollarl
	cmp #100
	bcc ?nodcar
	inc tdollarh
	sec
	sbc #100
?nodcar	sta tdollarl
	lda dollarh
	sta earnh,y
	clc
	adc tdollarh
	sta tdollarh

	lda #0
	sta dollarl
	sta dollarh


	ldx mytask
	jsr TSKcancel
	ldx speedometertask
	jsr TSKcancel
	ldx motosndtiretask
	jsr TSKcancel
;	ldx bodytask
;	jsr TSKcancel

	ldy #8
	lda #0
?canceldrones
	ldx tsknums,y
	sta TSKxm,x	;so player won't collide with them during next qualify
	sta TSKyh,x	;so player won't collide with them during next qualify
	sta TSKflags,x	;cancels task
	dey
	bpl ?canceldrones

	jsr TSKvblank
	dw  0		;no vblank routine

	lda #$f0
	sta rasterspritey
	lda #0
	sta dashboard
	sta splitpalflag

	sta PICvramflag
	sta vrambp
	sta vrambuf

	sta niscrollv
	sta sv_niscrollh
	sta sv_niscrollm
	sta niscrollh
	sta niscrollm

	jsr niscrclr

	ldy race
	lda finish,y
	beq ?endj
	cmp #4
	bcc winscreen
?endj	jmp endstats

;=============================================================================
;1ST 2ND AND 3RD PLACE WIN SCREEN
winscreen
	extern write_wincruz
	jsr write_wincruz

	jsr nividon
	lda #nibgblk+niobjblk+niobjlblk+nibglblk	;turn off left column blanking
	sta nicr1SH

	jsr TSKschedule
	dw donothing

	sta mytask	;save dummy tasks index
	tax		;use another tasks sprite for place text

	ldy race
	lda finish,y
	cmp #1
	bne ?second
	jsr PICaput
	dw  firstplace
	lda #109+8
	sta PICxlo,x
	jmp ?placeset
?second
	cmp #2
	bne ?third
	jsr PICaput
	dw  secondplace
	lda #109+8
	sta PICxlo,x
	jmp ?placeset
?third
	jsr PICaput
	dw  thirdplace
	lda #109+8
	sta PICxlo,x
?placeset

	lda #0
	sta PICxhi,x
	sta PICyhi,x
	lda #190
	sta PICylo,x

	jsr TSKschedule
	dw donothing

	sta speedometertask	;save dummy tasks index
	tax		;use another tasks sprite for place text

	jsr PICaput
	dw  placeword

	lda #0
	sta PICxhi,x
	sta PICyhi,x
	lda #109
	sta PICxlo,x
	lda #199
	sta PICylo,x


	ldx TSKcurrent

	lda #1
	sta nibnksprSH

	lda #0
	sta PICxhi,x
	sta PICyhi,x

	dec ninmi	;turn on int

?waitfornobutw
	lda #1
	jsr TSKwait

	lda nijoy
	bne ?waitfornobutw

	lda #4
	jsr sndinitj
	ldx TSKcurrent

	jsr nirandom
	and #%01111111
	clc
	adc #2
	sta TSKlap,x

?waitforbutw
	lda #1
	jsr TSKwait

	dec TSKlap,x
	bne ?noflash

	jsr nirandom
	and #%01111111
	clc
	adc #2
	sta TSKlap,x
	and #3
	tay
	lda camx,y
	sta PICxlo,x
	lda camy,y
	sta PICylo,x
	jsr PICaput
	dw  photoflash

	lda #10		;0=repeat 7=sampling speed
	sta niwre0	;digital photoflash sound
	lda #$c2	;uses crash data
	sta nideltaddr
	lda #$10	;length
	sta nideltcntr
	lda #00
	sta nideltdata
	lda #$0f	;trigger
	sta niwrst
	lda #$1f
	sta niwrst

?noflash
	jsr sndplayj	;uses x,y reg

	lda nijoy
	beq ?waitforbutw
	lda niwrst
	and #16
	bne ?waitforbutw	;digital sound start button errors


	lda #0		;turn off music
	sta niwrst
	ldx TSKcurrent
	sta PICadrLo,x	;turn off sprite
	sta PICadrHi,x
	lda #$0f
	sta niwrst

	ldx mytask
	jsr TSKcancel		;cancel the second sprite task
	ldx speedometertask	;cancel the third sprite task
	jsr TSKcancel

	inc ninmi	;turn off int

;=============================================================================
endstats

	jsr nividoff

	lda nibnksprSH
	sta saved_nibnkspr
	lda nibnkchrSH
	sta saved_nibnkchr
	lda #4
	sta nibnksprSH
	lda #5
	sta nibnkchrSH

	jsr write_topview

	lda #1
	sta dashboard
	lda #153+8
	sta rasterspritey

	lda #0
	sta space
	jsr PICstring
	db 1,20,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff,0	;sprite collision char
	jsr PICvramOut
	lda #" "
	sta space

	lda #0
	sta splitbsprbnk
	lda #1
	sta splitbchrbnk

	jsr PICstring
	db 5,21,"END OF RACE STATISTICS",0
	jsr PICvramOut
	jsr PICstring
	db 5,23,"PLACE",0
	jsr PICvramOut
	jsr PICstring
	db 5,24,"123 PLACE BONUS",0
	jsr PICvramOut
	jsr PICstring
	db 5,25,"TOTAL TIME      :  :",0
	jsr PICvramOut

	lda #25
	sta tmp
	lda #23
	sta tmp+1
	ldy race
	lda finish,y
	bne ?finished
	jsr PICstring
	db 24,23,"DNF",0
	jsr PICvramOut
	jmp ?placebonus
?finished
	jsr numout2	;display finishing stats
	jsr PICvramOut

?placebonus
	ldy race
	lda finish,y
	cmp #1
	beq ?bonus1
	cmp #2
	beq ?bonus2
	cmp #3
	beq ?bonus3
	jsr PICstring
	db 23,24,"   0",0
	jsr PICvramOut
	jmp ?highspeed
?bonus1
	jsr PICstring
	db 22,24,"$3000",0
	jsr PICvramOut
	jmp ?highspeed
?bonus2
	jsr PICstring
	db 22,24,"$2000",0
	jsr PICvramOut
	jmp ?highspeed
?bonus3
	jsr PICstring
	db 22,24,"$1000",0
	jsr PICvramOut


?highspeed

;	ldy highestspeed
;	lda #24
;	sta tmp
;	lda #24
;	sta tmp+1
;	lda mphtbl,y
;	jsr numout		;display mph
;	jsr PICvramOut




;	ldy averagespeed
;	lda #24
;	sta tmp
;	lda #23
;	sta tmp+1
;	lda mphtbl,y
;	jsr numout
;	jsr PICvramOut

	lda #19
	sta tmp
	lda #25
	sta tmp+1
	lda racetimem
	jsr numout2
	jsr PICvramOut

	lda #22
	sta tmp
	lda #25
	sta tmp+1
	lda racetimeh
	jsr numout2
	jsr PICvramOut

	lda #25
	sta tmp
	lda #25
	sta tmp+1
	lda racetimel
	jsr numout2
	jsr PICvramOut



;	jsr PICstring
;	db 5,15,"BEST LAP:",0
;	jsr PICvramOut
;	jsr PICstring
;	db 5,15,"AVERAGE SPEED:",0
;	jsr PICvramOut
;	jsr PICstring
;	db 5,15,"TIME:",0
;	jsr PICvramOut


	jsr nividon

	dec ninmi	;turn on int

?waitfornobut2
	lda #1
	jsr TSKwait

	lda nijoy
	bne ?waitfornobut2

	lda #2
	jsr sndinitj

?waitforbut2
	lda #1
	jsr TSKwait
	jsr nirandom	;randomize the random routine

	jsr sndplayj

	lda nijoy
	beq ?waitforbut2

	inc ninmi	;turn off int

	lda #0
	sta dashboard
	lda #$f0
	sta rasterspritey

	jsr nividoff
	jsr map_hskp

	inc race	;next race
	jmp nextrace


checkflag
	anim	5,cflag1
	anim	4,cflag2
	anim	1,cflag1
	anim	3,cflag3
	anim	1,cflag1
	anim	2,cflag4
	animend	checkflag

cflag1	db 5,4,3 ; width, height, color code
	DB	$9C,$9D,$9D,$9E,$9F
	DB	$A0,$A1,$A2,$A3,$A4
	DB	$A5,$A6,$A7,$A7,$A8
	DB	$9F,$A9,$9F,$9F,$9F

cflag2	db 5,4,3 ; width, height, color code
	DB	$AA,$AB,$9D,$9E,$9F
	DB	$A0,$AC,$AD,$A3,$A4
	DB	$A5,$AE,$AF,$A7,$A8
	DB	$9F,$A9,$9F,$9F,$9F

cflag3	db 5,4,3 ; width, height, color code
	DB	$9C,$B0,$AB,$9E,$9F
	DB	$A0,$A1,$B1,$B2,$A4
	DB	$A5,$A6,$B3,$AF,$A8
	DB	$9F,$A9,$9F,$9F,$9F

cflag4	db 5,4,3 ; width, height, color code
	DB	$9C,$9D,$B0,$B4,$9F
	DB	$A0,$A1,$A2,$B5,$B6
	DB	$A5,$A6,$A7,$B3,$B7
	DB	$9F,$A9,$9F,$9F,$9F


whiteflag
	anim	5,wflag1
	anim	4,wflag2
	anim	1,wflag1
	anim	3,wflag3
	anim	1,wflag1
	anim	2,wflag4
	animend	whiteflag

wflag1	db 5,4,3 ; width, height, color code
	DB	$B8,$B9,$B9,$BA,$9F
	DB	$A0,$BB,$BC,$BD,$BE
	DB	$A5,$BF,$C0,$C0,$C1
	DB	$9F,$A9,$9F,$9F,$9F

wflag2	db 5,4,3 ; width, height, color code
	DB	$C2,$C3,$B9,$BA,$9F
	DB	$A0,$C4,$BC,$BD,$BE
	DB	$A5,$C5,$C6,$C0,$C1
	DB	$9F,$A9,$9F,$9F,$9F

wflag3	db 5,4,3 ; width, height, color code
	DB	$B8,$C7,$C3,$BA,$9F
	DB	$A0,$BB,$C8,$BD,$BE
	DB	$A5,$BF,$C9,$C6,$C1
	DB	$9F,$A9,$9F,$9F,$9F

wflag4	db 5,4,3 ; width, height, color code
	DB	$B8,$B9,$CA,$CB,$9F
	DB	$A0,$BB,$BC,$CC,$CD
	DB	$A5,$BF,$C0,$C9,$CE
	DB	$9F,$A9,$9F,$9F,$9F



blackflag
	anim	5,bflag1
	anim	4,bflag2
	anim	1,bflag1
	anim	3,bflag3
	anim	1,bflag1
	anim	2,bflag4
	animend	blackflag

bflag1	db 5,4,3 ; width, height, color code
	DB	$CF,$D0,$D0,$D1,$9F
	DB	$D2,$D3,$D4,$D5,$D6
	DB	$A5,$D7,$D8,$D8,$A8
	DB	$9F,$A9,$9F,$9F,$9F

bflag2	db 5,4,3 ; width, height, color code
	DB	$D9,$DA,$D0,$D1,$9F
	DB	$D2,$DB,$D4,$D5,$D6
	DB	$A5,$DC,$DD,$D8,$A8
	DB	$9F,$A9,$9F,$9F,$9F

bflag3	db 5,4,3 ; width, height, color code
	DB	$CF,$DE,$DA,$D1,$9F
	DB	$D2,$D3,$DF,$D5,$D6
	DB	$A5,$D7,$E0,$DD,$A8
	DB	$9F,$A9,$9F,$9F,$9F

bflag4	db 5,4,3 ; width, height, color code
	DB	$CF,$D0,$E1,$E2,$9F
	DB	$D2,$D3,$D4,$E3,$E4
	DB	$A5,$D7,$D8,$E0,$E5
	DB	$9F,$A9,$9F,$9F,$9F



camx	db 64,120,216,64
camy	db 200,208,200,200

photoflash
	anim	3,flash1
	anim	4,flash2
	anim	2,flash1
phend	anim	2,blank
	animend	phend


flash1	db 3,3,0 ; width, height, color code
	DB	00,00,00
	DB	76,77,78
	DB	82,00,83

flash2	db 3,3,0 ; width, height, color code
	DB	73,74,75
	DB	79,80,81
	DB	84,00,85

blank	db 3,3,0 ; width, height, color code
	DB	" "-" "," "-" "," "-" "
	DB	" "-" "," "-" "," "-" "
	DB	" "-" "," "-" "," "-" "


firstplace
	anim	200,place1
	animend	firstplace
secondplace
	anim	200,place2
	animend	secondplace
thirdplace
	anim	200,place3
	animend	thirdplace

placeword
	anim	200,placew
	animend	placeword


placew	db 5,1,2 ; width, height, color code
	DB	"P"-" ","L"-" ","A"-" ","C"-" ","E"-" "

place1	db 3,1,2 ; width, height, color code
	DB	"1"-" ","S"-" ","T"-" "
place2	db 3,1,2 ; width, height, color code
	DB	"2"-" ","N"-" ","D"-" "
place3	db 3,1,2 ; width, height, color code
	DB	"3"-" ","R"-" ","D"-" "





qtimeh	db 40,40,41,41,42,42,43,43,44,44
qtimel	db 00,30,00,30,00,30,00,30,00,30


getraceinfoadr
	ldy race
	lda dskilladrl,y
	sta tmp
	lda dskilladrh,y
	sta tmp+1
	rts

;drone skill table. indexed by RACE
; 0=player's screen.
; 1=1 screen behind player
;-1=1 screen ahead of player

dskilladrl	db <dsk0,<dsk1,<dsk2,<dsk3,<dsk4,<dsk5
		db <dsk6,<dsk7,<dsk8,<dsk9,<dsk10,<dsk11,<dsk12,<dsk13

dskilladrh	db >dsk0,>dsk1,>dsk2,>dsk3,>dsk4,>dsk5
		db >dsk6,>dsk7,>dsk8,>dsk9,>dsk10,>dsk11,>dsk12,>dsk13

;indexes for dsk table below
drone_iq	equ 8
pitexitscreen	equ 9
racelaps	equ 10
tracklength	equ 11
tracktable	equ 12	;2 bytes

;           ---screen to track to---- pit exit screen

dsk0	db  1, 1, 2, 2, 2, 2, 2, 2, 2,  255, 3,52 ;laps was 3
	dw track00
dsk1	db  1, 1, 1, 2, 2, 2, 2, 2, 2,  255,10,16
	dw track01
dsk2	db  1, 1, 1, 1, 2, 2, 2, 2, 2,  255,11,20
	dw track02
dsk3	db  0, 0, 1, 1, 1, 1, 2, 2, 2,  255, 8,31
	dw track03
dsk4	db  0, 0, 0, 0, 1, 1, 1, 1, 2,  255, 9,28
	dw track04
dsk5	db  0, 0, 0, 0, 0, 1, 1, 1, 2,  255,22,12
	dw track05
dsk6	db -1, 0, 0, 0, 0, 0, 0, 0, 1,  255,19,14
	dw track06
dsk7	db -1,-1, 0, 0, 0, 0, 0, 0, 0,  255,28,10
	dw track07
dsk8	db -1,-1,-1, 0, 0, 0, 0, 0, 0,  255, 5,55
	dw track08
dsk9	db -1,-1,-1,-1, 0, 0, 0, 0, 0,  255, 9,31
	dw track09
dsk10	db -1,-1,-1,-1,-1, 0, 0, 0, 0,  255,14,20
	dw track10
dsk11	db -1,-1,-1,-1,-1, 0, 0, 0, 0,  255, 6,52
	dw track11
dsk12	db -1,-1,-1,-1,-1, 0, 0, 0, 0,  255, 7,41
	dw track12
dsk13	db -1,-1,-1,-1,-1, 0, 0, 0, 0,  255,16,20
	dw track13

;=============================================================================

PLAYER
	stx mytask

	lda #9			;I am car color 9
	sta TSKcarnum,x

	lda #4			;starting speed
	sta TSKxspeedh,x

	jsr PICaput
	dw  acar3

;	lda #3
;	sta gear		;start in 4th gear

	lda #0
	sta PICyhi,x
	sta TSKaccel,x
	sta TSKskidding,x
	sta TSKlap,x
	sta TSKxspeedl,x
	sta TSKyspeedl,x
	sta TSKyspeedh,x
	sta TSKyl,x
	sta TSKxl,x
	sta tires		;brand new tires
	sta body		;brand new car

	lda #120
	sta TSKxh,x

	lda trackwrap2		;start 2 screens before checkered line
	sta TSKxm,x

	jsr displaylap
	jsr displaytlap

;	lda #120
;	ldy #roadtop+lanewidth+(lanewidth/2)
;	jsr PICxyset

	ldy plstpos
	lda lanetoptbl,y
	clc
	adc #lanewidth/2
	sta TSKyh,x

	lda mod3,y		;spread out the pack vertically a little
	cmp #1
	beq ?spreaddone
	cmp #2
	beq ?up
	inc TSKyh,x
	inc TSKyh,x
	jmp ?spreaddone
?up
	dec TSKyh,x
	dec TSKyh,x
?spreaddone


	lda #19			;left edge of gauge
	sta damchange		;init

playerloop

	lda TSKxl,x	;save in temp area for possible reset by collision
	sta oldxl
	lda TSKxh,x
	sta oldxh
	lda TSKxm,x
	sta oldxm
	lda TSKlap,x
	sta oldlap
	lda TSKyl,x
	sta oldyl
	lda TSKyh,x
	sta oldyh


moveplayer
;Y stuff

	jsr steer

;	lda taskclock
;	and #1
;	beq ?notskid

;simulate turn
	lda #0
	sta turn+1
	sec
	lda #88		;was 72	;top y of straight - full turn = 48 (increase this by about 4 to increase centrifugal force (in another place to?))
	sbc lane1y+16		;0 - 24
	asl a
	rol turn+1
	asl a
	rol turn+1
	asl a
	rol turn+1
	asl a
	rol turn+1
	asl a
	rol turn+1
	sta turn

	sec
	lda TSKyl,x
	sbc turn
	sta TSKyl,x
	lda TSKyh,x
	sbc turn+1
	sta TSKyh,x

?notskid

	clc			;add yspeed to y
	lda TSKyl,x
	adc TSKyspeedl,x
	sta TSKyl,x
	lda TSKyh,x
	adc TSKyspeedh,x
	sta TSKyh,x

;guardrail test
	cmp lane1y+16
	beq ?notoprail
	bcs ?notoprail
	lda lane1y+16
	sta TSKyh,x
	jsr crash
	jmp ?nobotrail
?notoprail
	cmp lane4y+16
	beq ?nobotrail
	bcc ?nobotrail
	lda lane4y+16
	sta TSKyh,x
	lda TSKxm,x
	cmp #$ff		;pit entrance screen
	bne ?nopit
	lda TSKxh,x
	cmp #162		;increase this to make entrance smaller
	bcc ?nopit		;only first half of pit entrance screen
	jmp pit
?nopit	jsr crash
?nobotrail

pitreturn

;detect y collision with drones

;	lda #8
;	sta tmp+2
;?morecol
;	ldy tmp+2
;	lda tsknums,y
;	tay
;	jsr lcollision
;	bcs ?ycollide
;	dec tmp+2
;	bpl ?morecol
;	jmp ?noycollide

;?ycollide
;	lda oldyl		;undo the y movement
;	sta TSKyl,x
;	lda oldyh
;	sta TSKyh,x
;	jsr nudgesnd
;	jsr damagebody1
;	jsr negplyspeed
;?noycollide





;X stuff
	lda TSKxspeedh,x
	beq ?noslower		;minimum speed?

	ldy #friction	;always friction
	lda #nibutB
	bit nijoy
	beq ?nobrake
	ldy #decel+friction
?nobrake
	sty tmp

	sec
	lda TSKxspeedl,x
	sbc tmp
	sta TSKxspeedl,x
	lda TSKxspeedh,x
	sbc #0
	sta TSKxspeedh,x
	bpl ?noslower
	lda #0			;limit to speed of zero
	sta TSKxspeedl,x
	sta TSKxspeedh,x
?noslower
				;calc tach value
;	lda TSKxspeedh,x
;	sta tmp+1
;	lda TSKxspeedl,x
;	sta tmp
;
;	ldy gear
;
;	lsr tmp+1
;	ror tmp
;	dey
;	bmi ?gdone
;
;	lsr tmp+1
;	ror tmp
;	dey
;	bmi ?gdone
;
;	lsr tmp+1
;	ror tmp
;	dey
;	bmi ?gdone
;
;	lsr tmp+1
;	ror tmp
;?gdone
;	lda tmp
;	sta tach



	lda #nibutA
	bit nijoy
	beq ?noleft

	lda TSKskidding,x
	bne ?noleft		;no accel while skidding

	lda TSKxspeedh,x
	cmp #maxspeed
	beq ?noleft
	lda taskclock
	and #2			;frequency of speed inc
	bne ?noleft

	lda car
	asl a
	tay
	lda geartbls,y
	sta tmp
	lda geartbls+1,y
	sta tmp+1

	lda TSKxspeedl,x
	sta tmp+2
	lda TSKxspeedh,x
	ror a
	ror tmp+2
	ror a
	ror tmp+2
	ror a
	ror tmp+2
	ldy tmp+2


	lda #0
	sta tmp+3
	lda (tmp),y
	bpl ?notminus
	dec tmp+3
?notminus

	clc
	lda TSKxspeedl,x
	adc (tmp),y
	sta TSKxspeedl,x
	lda TSKxspeedh,x
	adc tmp+3
	sta TSKxspeedh,x

?noleft


;test
;	lda lane1y+16
;	sta PICylo,x
;test

	lda TSKskidding,x
	bne ?notilt		;do not change skidding car pattern
	jsr tiltcar
?notilt

	jsr plxmove

	lda oldlap
	cmp TSKlap,x
	beq ?nonewlap
	jsr displaylap
?nonewlap

;detect collision with drones

	lda #8
	sta tmp+2
?morecol
	ldy tmp+2
	lda tsknums,y
	tay
;	jsr lcollision

;lcollision		;copy of real lcollision. (here for speed)

	lda TSKxh,x
	sec
	sbc TSKxh,y
	sta tmp
	lda TSKxm,x
	sbc TSKxm,y
	bpl ?pico1		;positive

	cmp #$ff
	bne ?nocollide		;distance > 256, no overlap
	lda tmp
	cmp #-13
	bcc ?nocollide		;distance > 14, no overlap
	bcs ?ycoll		;always
?pico1
	bne ?nocollide		;distance > 256, no overlap
	lda tmp
	cmp #14
	bcs ?nocollide		;distance > 14, no overlap
?ycoll
	lda TSKyh,x		;now do Y
	sec
	sbc TSKyh,y
	bpl ?pico2
	cmp #-7
	bcc ?nocollide		;distance > 8, no overlap
	bcs ?collide		;always
?pico2
	cmp #8
	bcs ?nocollide		;distance > 8, no overlap
;	bcc ?collide		;always

;end of lcollision

?collide
	lda TSKyl,x		;save new y
	sta tmp+1
	lda TSKyh,x
	sta tmp+2

	lda oldyl		;undo the y movement to see if it was caused
	sta TSKyl,x		;by y movement
	lda oldyh
	sta TSKyh,x
	jsr lcollision
	bcc ?ycollide		;yes it was caused by y movement

?xcollide			;no it was caused by x movement
	lda tmp+1		;put back new y
	sta TSKyl,x
	lda tmp+2
	sta TSKyh,x

	jsr nudgesnd
	jsr damagebody1
	jsr handlexhit
	lda tmp+2		;severity of collision
	beq ?collidedone
	jsr severehit		;make player skid
	jmp ?collidedone

?ycollide
	jsr nudgesnd
	jsr damagebody1
	jsr negplyspeed
	jmp ?collidedone

?nocollide
	dec tmp+2
	bpl ?morecol

?collidedone

	jsr scroll
;	jsr changegear

?endrace
	jsr setscreenpos

	lda #1
	jsr TSKwait

	lda endofraceflag
	bne ?endrace

	jmp playerloop

;-----------------------------------------------------------------------------
displaylap
	lda #114
	sta space
	lda #14
	sta tmp
	lda #27
	sta tmp+1
	lda TSKlap,x
	jsr numout2		;2 digit lap display
	rts

displaytlap
	lda #114
	sta space
	jsr getraceinfoadr
	ldy #racelaps
	lda (tmp),y
	ldy #16
	sty tmp
	ldy #27
	sty tmp+1
	jsr numout2		;total laps for race
	rts

;-----------------------------------------------------------------------------
crash
	lda #dashy+6
	sta rasterspritey	;jerk dashboard

	lda TSKxh,y
	and #1
	beq ?counterclockwise
	jsr PICaput
	dw  plspincar
	jmp ?patdone

?counterclockwise
	jsr PICaput
	dw  plspincar2
?patdone

	lda #45
	jsr niranrange
	adc #20		;20-65
	sta TSKskidding,x	;crash duration

;crash sound
	lda #$08	;4=repeat a=sampling speed
	sta niwre0
	lda #$c0	;data at $f000
	sta nideltaddr
	lda #196
	sta nideltcntr
	lda #00
	sta nideltdata
	lda #$0f		;trigger
	sta niwrst
	lda #$1f
	sta niwrst

	jsr damagebody3		;guardrails do more damage

negplyspeed			;negate players yspeed and cut it in half
	lda TSKyspeedl,x
	sec
	sbc turn
	sta TSKyspeedl,x
	lda TSKyspeedh,x
	sbc turn+1
	sta TSKyspeedh,x	;get true yspeed

	asl a			;preserve sign
	ror TSKyspeedh,x	;cut in half
	ror TSKyspeedl,x

	jsr negyspeed		;bounce off guardrail

	lda TSKyspeedl,x
	clc
	adc turn
	sta TSKyspeedl,x
	lda TSKyspeedh,x
	adc turn+1
	sta TSKyspeedh,x	;make true yspeed
	rts


;-----------------------------------------------------------------------------
severehit			;used by player to make player
				;skid after a severe hit
	lda taskclock
	and #%00001111
	adc #15			;make player skid a little
	sta TSKskidding,x	;skid duration
	jsr skidsoundr
	jsr damagebody2
	lda TSKyspeedh,x
	bpl ?skidleft
?skidright
	jsr PICaput
	dw  acar7
	rts
?skidleft
	jsr PICaput
	dw  acar13
	rts

;-----------------------------------------------------------------------------
handlexhit
	lda oldxl		;restore old x position
	sta TSKxl,x
	lda oldxh
	sta TSKxh,x
	lda oldxm
	sta TSKxm,x
	lda oldlap
	sta TSKlap,x
	lda #0
	sta tmp+2		;for severity of collision
	sta TSKaccel,x

;compare speeds
	lda TSKxspeedh,y
	cmp TSKxspeedh,x
	beq ?cmplow
	bcs ?noxcollide		;dont take his speed if he is going faster
	jmp ?xchgspeed
?cmplow
	lda TSKxspeedl,y
	cmp TSKxspeedl,x
	bcs ?noxcollide
?xchgspeed
	lda TSKxspeedl,x
	sec
	sbc TSKxspeedl,y
	sta tmp
	lda TSKxspeedh,x
	sbc TSKxspeedh,y
	sta tmp+2		;for severity of collision
	lsr a
	sta tmp+1
	ror tmp			;divide difference in speeds by 2

	lda TSKxspeedl,y	;add it to his
	clc
	adc tmp
	sta TSKxspeedl,y
	lda TSKxspeedh,y
	adc tmp+1
	sta TSKxspeedh,y

	lda TSKxspeedl,x	;subtract it from mine
	sec
	sbc tmp
	sta TSKxspeedl,x
	lda TSKxspeedh,x
	sbc tmp+1
	sta TSKxspeedh,x

?noxcollide
	rts

;-----------------------------------------------------------------------------

limity
	lda lane1y+16
	cmp TSKyh,x
	beq ?notoprail
	bcc ?notoprail
	sta PICylo,x
	sta TSKyh,x
?notoprail
	lda lane4y+16
	cmp TSKyh,x
	beq ?nobotrail
	bcs ?nobotrail
	sta PICylo,x
	sta TSKyh,x
?nobotrail
	rts

;-----------------------------------------------------------------------------

;scroll right
scroll
	sec
	lda TSKxh,x
	sbc #120		;PLAYERS HORIZONTAL SCREEN POSITION
	sta niscrollh
	lda TSKxm,x
	sbc #0
	sta niscrollm
	cmp trackwrap		;wrap track
	bne ?nowrap
	lda #$ff
?nowrap	sta niscrollm
	rts

;-----------------------------------------------------------------------------
;changegear
;	lda #nileft
;	bit nijoy
;	beq ?nogearup
;	lda gear
;	cmp #3
;	beq ?nogearup
;	inc gear
;?nogearup
;	lda #niright
;	bit nijoy
;	beq ?nogeardn
;	lda gear
;	beq ?nogeardn
;	dec gear
;?nogeardn
;
;	lda #15
;	sta tmp
;	lda #20
;	sta tmp+1
;	lda gear
;	clc
;	adc #1
;	jsr numout
;	rts
;-----------------------------------------------------------------------------
tiltcar
;tilt car image
	lda #88		;was 72		;top lane y of straight
	sec
	sbc lane1y+16
	sta tmp

	lda TSKyh,x
	sec
	sbc tmp		;tilt more in the turn
	lsr a
	lsr a
	lsr a
	tay
	lda tilttbll,y
	sta PICanimlo,x
	sta tmp
	lda tilttblh,y
	sta PICanimhi,x
	sta tmp+1

	jsr picset
	rts

tilttbll
	db <acar6,<acar6,<acar6,<acar6,<acar6,<acar6,<acar6,<acar6
	db <acar5,<acar5,<acar5
	db <acar4,<acar4
	db <acar3
	db <acar2
	db <acar1,<acar1,<acar1

tilttblh
	db >acar6,>acar6,>acar6,>acar6,>acar6,>acar6,>acar6,>acar6
	db >acar5,>acar5,>acar5
	db >acar4,>acar4
	db >acar3
	db >acar2
	db >acar1,>acar1,>acar1
;-----------------------------------------------------------------------------
tiltcarm
;tilt car image
	lda #88		;was 72		;top lane y of straight
	sec
	sbc lane1y+16
	sta tmp

	lda TSKyh,x
	sec
	sbc tmp		;tilt more in the turn
	lsr a
	lsr a
	lsr a
	tay
	lda tilttbllm,y
	sta PICanimlo,x
	sta tmp
	lda tilttblhm,y
	sta PICanimhi,x
	sta tmp+1

	jsr picset
	rts

tilttbllm
	db <acar6m,<acar6m,<acar6m,<acar6m,<acar6m,<acar6m,<acar6m,<acar6m
	db <acar5m,<acar5m,<acar5m
	db <acar4m,<acar4m
	db <acar3m
	db <acar2m
	db <acar1m,<acar1m,<acar1m

tilttblhm
	db >acar6m,>acar6m,>acar6m,>acar6m,>acar6m,>acar6m,>acar6m,>acar6m
	db >acar5m,>acar5m,>acar5m
	db >acar4m,>acar4m
	db >acar3m
	db >acar2m
	db >acar1m,>acar1m,>acar1m

;-----------------------------------------------------------------------------
tiltcard
;tilt car image
	lda #88		;was 72		;top lane y of straight
	sec
	sbc lane1y+16
	sta tmp

	lda TSKyh,x
	sec
	sbc tmp		;tilt more in the turn
	lsr a
	lsr a
	lsr a
	tay
	lda tilttblld,y
	sta PICanimlo,x
	sta tmp
	lda tilttblhd,y
	sta PICanimhi,x
	sta tmp+1

	jsr picset
	rts

tilttblld
	db <acar6d,<acar6d,<acar6d,<acar6d,<acar6d,<acar6d,<acar6d,<acar6d
	db <acar5d,<acar5d,<acar5d
	db <acar4d,<acar4d
	db <acar3d
	db <acar2d
	db <acar1d,<acar1d,<acar1d

tilttblhd
	db >acar6d,>acar6d,>acar6d,>acar6d,>acar6d,>acar6d,>acar6d,>acar6d
	db >acar5d,>acar5d,>acar5d
	db >acar4d,>acar4d
	db >acar3d
	db >acar2d
	db >acar1d,>acar1d,>acar1d


;-----------------------------------------------------------------------------
nudgesnd
;	lda #$0f		;nudge sound
;	sta nidutyD
;
;	lda taskclock
;	and #%00000011
;	adc #$8b		;bit 7=noise type,  noise b-e
;	sta nifreqD
;	lda #$80
;	sta nilengthD

;digital

	lda taskclock
	and #%00000011
	clc
	adc #$07		;sampling speed 7-10
	sta niwre0
	lda taskclock
	and #%00011111
	clc
	adc #$c0		;data at $f000
	sta nideltaddr
	jsr nirandom
	and #%00001111
	clc
	adc #16
	sta nideltcntr		;total length=196
	lda #00
	sta nideltdata
	lda #$0f		;trigger
	sta niwrst
	lda #$1f
	sta niwrst

	rts

;-----------------------------------------------------------------------------

steer
	ldy #0
	lda TSKskidding,x
	bne ?noster
	ldy nijoy
?noster tya
	and #$0f		;mask off buttons
	tay
	clc
	lda TSKyspeedl,x
	adc steeringl,y
	sta TSKyspeedl,x
	sta tmp
	lda TSKyspeedh,x
	adc steeringh,y
	sta TSKyspeedh,x
	sta tmp+1

;test for skid
	bpl ?notneg

;;negate tmp
	lda tmp
	eor #$FF
	clc
	adc #1
	sta tmp
	lda tmp+1
	eor #$FF
	adc #0
	sta tmp+1
?notneg
	ror a
	ror tmp
	ror a
	ror tmp
	ror a
	ror tmp			;7 bit yspeed

	lda TSKxspeedl,x
	sta tmp+1
	lda TSKxspeedh,x
	ror a
	ror tmp+1
	ror a
	ror tmp+1
	ror a
	ror tmp+1
	lda tmp+1
	sta onebytexspeed	;for speedometer and motor sound

	lda tires		;skid sensitivity knob
	clc
	adc tmp
	adc tmp+1
	bcs ?skid

	cmp #$f0		;close to skidding threshold
	bcc ?notclose
	lda TSKskidding,x
	bne ?notclose		;no close to skidding sound if already skidding

;close to skidding sound
	lda #$12
	sta nidutyD
	lda taskclock
	lsr a
	and #%00000011
	sta nifreqD
	lda #$20
	sta nilengthD

?notclose
	lda TSKskidding,x
	beq ?rts		;already not skidding
?decskid
	dec TSKskidding,x
	bne ?rts
	lda #$0f
	sta niwrst
?rts	rts

?skid
	lda TSKskidding,x
	bne ?decskid		;already skidding

	jsr skidsoundr

	lda #27			;skid duration
	sta TSKskidding,x
	lda tires
	cmp #86			;maximum tire damage on gauge
	bcs ?tiresgone
	inc tires		;tire wear
	lda car
	cmp #1
	beq ?bettertires	;tires are better on car 1
	inc tires		;more tire wear for cars 0 & 2
?bettertires

;update tire gauge
	lda tires
	lsr a
	tay
	lsr a
	lsr a
	clc
	adc #2			;left edge of gauge
	sta tmp			;x pos
	tya
	and #%00000011
	tay
	lda #26			;y pos
	sta tmp+1
	lda #0
	sta space
	lda bargauge,y
	jsr charout

?tiresgone
;centrifugal force
	sec
	lda #88		;was 72			;top y of straight - full turn = 48
	sbc lane1y+16		;0 - 24
	asl a
	asl a
	asl a
	sta tmp
	sec
	lda TSKyspeedl,x
	sbc tmp
	sta TSKyspeedl,x
	lda TSKyspeedh,x
	sbc #0
	sta TSKyspeedh,x

	jsr PICaput
	dw  acar13
	lda TSKyspeedh,x
	bpl ?skidleft

	jsr PICaput
	dw  acar7
?skidleft
	rts

bargauge	db 220,221,222,223	;bar gauge characters

endskid
	jsr PICaput
	dw  acar3

	lda #0
	sta TSKskidding,x

	lda #$0f
	sta niwrst
	rts

skidsoundr		;with repeat
	lda #$4a	;4=repeat a=sampling speed
skidnorept
	sta niwre0
	lda #$f2	;data at $fc80
	sta nideltaddr
	lda #$34		;length
	sta nideltcntr
	lda #00
	sta nideltdata
	lda #$0f		;trigger
	sta niwrst
	lda #$1f
	sta niwrst
	rts

skidsound		;no repeat
	lda #$07	;4=repeat 6=sampling speed
	jmp skidnorept


; joystick directions
;
;  10  8  9
;    \ | /
;  2 -   - 1
;    / | \
;   6  4  5

steeringl
	PUBLIC	steeringl
	db 0,0,0,0,<turnmed,<turnfast,<turnslow,0
	db <-turnmed,<-turnfast,<-turnslow,0,0,0,0,0

steeringh
	PUBLIC	steeringh
	db 0,0,0,0,>turnmed,>turnfast,>turnslow,0
	db >-turnmed,>-turnfast,>-turnslow,0,0,0,0,0

;-----------------------------------------------------------------------------
geartbls
	PUBLIC	geartbls
	dw hotgear	;gear for car 0, faster acceleration
	dw unigear	;gear for car 1, has better tires
	dw topgear	;gear for car 2, higher top end

hotgear		;fast accel gear
	db	3+6,3+6,3+6,3+6,3+6,3+6,3+6,3+6
	db	3+6,4+6,4+6,4+6,4+6,4+6,4+6,4+6
	db	4+6,4+6,5+6,5+6,5+6,5+6,5+6,5+6
	db	6+6,6+6,6+6,6+6,6+6,6+6,7+6,7+6
	db	7+6,7+6,7+6,8+6,8+6,8+6,8+6,9+6
	db	9+6,9+6,9+6,10+6,10+6,10+6,11+6,11+6
	db	11+6,12+6,12+6,12+6,13+6,13+6,15+6,14+6
	db	14+6,14+6,14+6,14+6,13+6,13+6,13+6,13+6
	db	12+6,12+6,12+6,12+6,12+6,12+6,11+6,11+6
	db	11+6,11+6,11+6,11+6,11+6,10+6,10+6,10+6
	db	10+6,10+6,10+6,10+6,10+6,9+6,9+6,9+6
	db	9+6,9+6,9+6,9+6,9+6,9+6,9+6,8+6
	db	8+6,8+6,8+6,8+6,8+6,8+6,8+6,8+6
	db	8+6,8+6,8+6,8+6,7+6,7+6,7+6,7+6
	db	7+6,7+6,7+6,7+6,7+6,7+6,7+6,7+6
	db	10,10,10,10,9,9,9,9
	db	9,9,9,9,9,9,9,9
	db	9,9,9,9,9,9,9,8
	db	8,8,8,8,8,8,8,8
	db	8,8,8,8,8,8,8,8
	db	8,8,8,8,8,8,8,8
	db	8,7,7,7,7,7,7,7
	db	7,7,7,7,7,7,7,7
	db	7,7,7,7,7,7,7,7
	db	7,7,-5,-5,-5,-5,-5,-5
	db	-5,-5,-5,-6,-6,-6,-6,-6
	db	-6,-6,-6,-6,-6,-6,-7,-7
	db	-7,-7,-7,-7,-7,-7,-7,-7
	db	-7,-8,-8,-8,-8,-8,-8,-8
	db	-8,-8,-8,-9,-9,-9,-9,-9
	db	-9,-9,-9,-9,-10,-10,-10,-10
	db	-10,-10,-10,-10,-11,-11

unigear		;universal gear
	db	3+4,3+4,3+4,3+4,3+4,3+4,3+4,3+4
	db	3+4,4+4,4+4,4+4,4+4,4+4,4+4,4+4
	db	4+4,4+4,5+4,5+4,5+4,5+4,5+4,5+4
	db	6+4,6+4,6+4,6+4,6+4,6+4,7+4,7+4
	db	7+4,7+4,7+4,8+4,8+4,8+4,8+4,9+4
	db	9+4,9+4,9+4,10+4,10+4,10+4,11+4,11+4
	db	11+4,12+4,12+4,12+4,13+4,13+4,15+4,14+4
	db	14+4,14+4,14+4,14+4,13+4,13+4,13+4,13+4
	db	12+4,12+4,12+4,12+4,12+4,12+4,11+4,11+4
	db	11+4,11+4,11+4,11+4,11+4,10+4,10+4,10+4
	db	10+4,10+4,10+4,10+4,10+4,9+4,9+4,9+4
	db	9+4,9+4,9+4,9+4,9+4,9+4,9+4,8+4
	db	8+4,8+4,8+4,8+4,8+4,8+4,8+4,8+4
	db	8+4,8+4,8+4,8+4,7+4,7+4,7+4,7+4
	db	7+4,7+4,7+4,7+4,7+4,7+4,7+4,7+4
	db	8,8,8,8,7,7,7,7
	db	7,7,7,7,7,7,7,7
	db	7,7,7,7,7,7,7,6
	db	6,6,6,6,6,6,6,6
	db	6,6,6,6,6,6,6,6
	db	6,6,6,6,6,6,6,6
	db	6,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,5
	db	5,5,-5,-5,-5,-5,-5,-5
	db	-5,-5,-5,-6,-6,-6,-6,-6
	db	-6,-6,-6,-6,-6,-6,-7,-7
	db	-7,-7,-7,-7,-7,-7,-7,-7
	db	-7,-8,-8,-8,-8,-8,-8,-8
	db	-8,-8,-8,-9,-9,-9,-9,-9
	db	-9,-9,-9,-9,-10,-10,-10,-10
	db	-10,-10,-10,-10,-11,-11

topgear		;higher top end
	db	3+4,3+4,3+4,3+4,3+4,3+4,3+4,3+4
	db	3+4,4+4,4+4,4+4,4+4,4+4,4+4,4+4
	db	4+4,4+4,5+4,5+4,5+4,5+4,5+4,5+4
	db	6+4,6+4,6+4,6+4,6+4,6+4,7+4,7+4
	db	7+4,7+4,7+4,8+4,8+4,8+4,8+4,9+4
	db	9+4,9+4,9+4,10+4,10+4,10+4,11+4,11+4
	db	11+4,12+4,12+4,12+4,13+4,13+4,15+4,14+4
	db	14+4,14+4,14+4,14+4,13+4,13+4,13+4,13+4
	db	12+4,12+4,12+4,12+4,12+4,12+4,11+4,11+4
	db	11+4,11+4,11+4,11+4,11+4,10+4,10+4,10+4
	db	10+4,10+4,10+4,10+4,10+4,9+4,9+4,9+4
	db	9+4,9+4,9+4,9+4,9+4,9+4,9+4,8+4
	db	8+4,8+4,8+4,8+4,8+4,8+4,8+4,8+4
	db	8+4,8+4,8+4,8+4,7+4,7+4,7+4,7+4
	db	7+4,7+4,7+4,7+4,7+4,7+4,7+4,7+4
	db	8,8,8,8,7,7,7,7
	db	7,7,7,7,7,7,7,7
	db	7,7,7,7,7,7,7,6
	db	6,6,6,6,6,6,6,6
	db	6,6,6,6,6,6,6,6
	db	6,6,6,6,6,6,6,6
	db	6,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,5
	db	5,5,5,5,5,5,5,-5	;this line is different from unigear
	db	-5,-5,-5,-6,-6,-6,-6,-6
	db	-6,-6,-6,-6,-6,-6,-7,-7
	db	-7,-7,-7,-7,-7,-7,-7,-7
	db	-7,-8,-8,-8,-8,-8,-8,-8
	db	-8,-8,-8,-9,-9,-9,-9,-9
	db	-9,-9,-9,-9,-10,-10,-10,-10
	db	-10,-10,-10,-10,-11,-11


;-----------------------------------------------------------------------------


plspincar
	anim	4,car7
	anim	4,car8
	anim	4,car9
	anim	4,car10
	anim	4,car11
	anim	4,car12
	anim	4,car13
	anim	4,car3
	animend plspincar

plspincar2			;counter clockwise
	anim	4,car13
	anim	4,car12
	anim	4,car11
	anim	4,car10
	anim	4,car9
	anim	4,car8
	anim	4,car7
	anim	4,car3
	animend plspincar2



acar1
	anim	20,car1
	animend	acar1
acar2
	anim	20,car2
	animend	acar2
acar3
	anim	20,car3
	animend	acar3
acar4
	anim	20,car4
	animend	acar4
acar5
	anim	20,car5
	animend	acar5
acar6
	anim	20,car6
	animend	acar6


acar13				;left skid
	anim	20,car13
	animend	acar13
acar7				;right skid
	anim	20,car7
	animend	acar7



car1	db 2, 2, 0 ; width, height, color code
	db  $00,$01
	db  $02,$03
car2	db 2, 2, 0 ; width, height, color code
	db  $04,$05
	db  $06,$07
car3	db 2, 2, 0 ; width, height, color code
	db  $08,$09
	db  $0a,$0b
car4	db 2, 2, 0 ; width, height, color code
	db  $0c,$0d
	db  $0e,$0f
car5	db 2, 2, 0 ; width, height, color code
	db  $10,$11
	db  $12,$13
car6	db 2, 2, 0 ; width, height, color code
	db  $14,$15
	db  $16,$17
car7	db 2, 2, 0 ; width, height, color code
	db  $18,$19
	db  $1a,$1b
car8	db 2, 2, 0 ; width, height, color code
	db  $1c,$1d
	db  $1e,$1f
car9	db 2, 2, 0 ; width, height, color code
	db  $20,$21
	db  $22,$23
car10	db 2, 2, 0 ; width, height, color code
	db  $24,$25
	db  $26,$27
car11	db 2, 2, 0 ; width, height, color code
	db  $28,$29
	db  $2a,$2b
car12	db 2, 2, 0 ; width, height, color code
	db  $2c,$2d
	db  $2e,$2f
car13	db 2, 2, 0 ; width, height, color code
	db  $30,$31
	db  $32,$33

;-----------------------------------------------------------------------------


plspincarm
	anim	4,car7m
	anim	4,car8m
	anim	4,car9m
	anim	4,car10m
	anim	4,car11m
	anim	4,car12m
	anim	4,car13m
	anim	4,car3m
	animend plspincarm

plspincar2m			;counter clockwise
	anim	4,car13m
	anim	4,car12m
	anim	4,car11m
	anim	4,car10m
	anim	4,car9m
	anim	4,car8m
	anim	4,car7m
	anim	4,car3m
	animend plspincar2m



acar1m
	anim	20,car1m
	animend	acar1m
acar2m
	anim	20,car2m
	animend	acar2m
acar3m
	anim	20,car3m
	animend	acar3m
acar4m
	anim	20,car4m
	animend	acar4m
acar5m
	anim	20,car5m
	animend	acar5m
acar6m
	anim	20,car6m
	animend	acar6m


acar13m				;left skid
	anim	20,car13m
	animend	acar13m
acar7m				;right skid
	anim	20,car7m
	animend	acar7m



car1m	db 2, 2, 0 ; width, height, color code
	db  $00+52,$01+52
	db  $02+52,$03+52
car2m	db 2, 2, 0 ; width, height, color code
	db  $04+52,$05+52
	db  $06+52,$07+52
car3m	db 2, 2, 0 ; width, height, color code
	db  $08+52,$09+52
	db  $0a+52,$0b+52
car4m	db 2, 2, 0 ; width, height, color code
	db  $0c+52,$0d+52
	db  $0e+52,$0f+52
car5m	db 2, 2, 0 ; width, height, color code
	db  $10+52,$11+52
	db  $12+52,$13+52
car6m	db 2, 2, 0 ; width, height, color code
	db  $14+52,$15+52
	db  $16+52,$17+52
car7m	db 2, 2, 0 ; width, height, color code
	db  $18+52,$19+52
	db  $1a+52,$1b+52
car8m	db 2, 2, 0 ; width, height, color code
	db  $1c+52,$1d+52
	db  $1e+52,$1f+52
car9m	db 2, 2, 0 ; width, height, color code
	db  $20+52,$21+52
	db  $22+52,$23+52
car10m	db 2, 2, 0 ; width, height, color code
	db  $24+52,$25+52
	db  $26+52,$27+52
car11m	db 2, 2, 0 ; width, height, color code
	db  $28+52,$29+52
	db  $2a+52,$2b+52
car12m	db 2, 2, 0 ; width, height, color code
	db  $2c+52,$2d+52
	db  $2e+52,$2f+52
car13m	db 2, 2, 0 ; width, height, color code
	db  $30+52,$31+52
	db  $32+52,$33+52

;-----------------------------------------------------------------------------


plspincard
	anim	4,car7d
	anim	4,car8d
	anim	4,car9d
	anim	4,car10d
	anim	4,car11d
	anim	4,car12d
	anim	4,car13d
	anim	4,car3d
	animend plspincard

plspincar2d			;counter clockwise
	anim	4,car13d
	anim	4,car12d
	anim	4,car11d
	anim	4,car10d
	anim	4,car9d
	anim	4,car8d
	anim	4,car7d
	anim	4,car3d
	animend plspincar2d



acar1d
	anim	20,car1d
	animend	acar1d
acar2d
	anim	20,car2d
	animend	acar2d
acar3d
	anim	20,car3d
	animend	acar3d
acar4d
	anim	20,car4d
	animend	acar4d
acar5d
	anim	20,car5d
	animend	acar5d
acar6d
	anim	20,car6d
	animend	acar6d


acar13d				;left skid
	anim	20,car13d
	animend	acar13d
acar7d				;right skid
	anim	20,car7d
	animend	acar7d



car1d	db 2, 2, 0 ; width, height, color code
	db  $00+104,$01+104
	db  $02+104,$03+104
car2d	db 2, 2, 0 ; width, height, color code
	db  $04+104,$05+104
	db  $06+104,$07+104
car3d	db 2, 2, 0 ; width, height, color code
	db  $08+104,$09+104
	db  $0a+104,$0b+104
car4d	db 2, 2, 0 ; width, height, color code
	db  $0c+104,$0d+104
	db  $0e+104,$0f+104
car5d	db 2, 2, 0 ; width, height, color code
	db  $10+104,$11+104
	db  $12+104,$13+104
car6d	db 2, 2, 0 ; width, height, color code
	db  $14+104,$15+104
	db  $16+104,$17+104
car7d	db 2, 2, 0 ; width, height, color code
	db  $18+104,$19+104
	db  $1a+104,$1b+104
car8d	db 2, 2, 0 ; width, height, color code
	db  $1c+104,$1d+104
	db  $1e+104,$1f+104
car9d	db 2, 2, 0 ; width, height, color code
	db  $20+104,$21+104
	db  $22+104,$23+104
car10d	db 2, 2, 0 ; width, height, color code
	db  $24+104,$25+104
	db  $26+104,$27+104
car11d	db 2, 2, 0 ; width, height, color code
	db  $28+104,$29+104
	db  $2a+104,$2b+104
car12d	db 2, 2, 0 ; width, height, color code
	db  $2c+104,$2d+104
	db  $2e+104,$2f+104
car13d	db 2, 2, 0 ; width, height, color code
	db  $30+104,$31+104
	db  $32+104,$33+104


;-----------------------------------------------------------------------------

speedometer

	stx speedometertask

;	jsr PICaput
;	dw  needlea

;	lda #0
;	sta PICxhi,x
;	sta PICyhi,x
;	sta averagespeed

	lda #198
;	sta PICylo,x
	sta place		;so it gets output the first time thru

sploop
	ldy onebytexspeed

;	sta PICxlo,x

;	tay			;save to access mphtbl for display

;	cmp highestspeed	;keep highest speed
;	bcc ?nothigh
;	sta highestspeed
;?nothigh
;	clc			;compute average speed
;	adc averagespeed
;	ror a
;	sta averagespeed


	lda #104
	sta space
	lda #9
	sta tmp
	lda #22
	sta tmp+1
	lda mphtbl,y
	jsr numout		;display mph

;FIND PLAYERS PLACE

	lda endofraceflag
	bne ?nochng		;preserve finishing position

	ldy mytask
	lda TSKlap,y
	sta tmp+3
	lda TSKxm,y
	sta tmp+2
	lda TSKxh,y
	sta tmp+1

	lda place
	sta tmp
	lda #1
	sta place

	ldy #8
?plp
	ldx tsknums,y
	lda TSKlap,x
	cmp tmp+3
	beq ?more
	bcc ?behind
	jmp ?infront
?more
	lda TSKxm,x
	cmp tmp+2
	beq ?more2
	bcs ?behind
	jmp ?infront
?more2
	lda TSKxh,x
	cmp tmp+1
	bcs ?behind
?infront
	inc place
?behind
	dey
	bpl ?plp

	lda tmp
	cmp place
	beq ?nochng

	lda #94
	sta space
	lda #2
	sta tmp
	lda #23
	sta tmp+1
	lda place
	jsr numout2		;display position

?nochng
	ldx TSKcurrent

?wait
	lda #1
	jsr TSKwait

	lda taskclock
	and #1
	beq ?wait

	jmp sploop



mphtbl
	db	0,1,3,4,5,6,8,9,10
	db	12,13,14,15,17,18,19,20
	db	22,23,24,26,27,28,29,31
	db	32,33,35,36,37,38,40,41
	db	42,43,45,46,47,49,50,51
	db	52,54,55,56,58,59,60,61
	db	63,64,65,66,68,69,70,72
	db	73,74,75,77,78,79,81,82
	db	83,84,86,87,88,89,91,92
	db	93,95,96,97,98,100,101,102
	db	104,105,106,107,109,110,111,113
	db	114,115,116,118,119,120,121,123
	db	124,125,127,128,129,130,132,133
	db	134,136,137,138,139,141,142,143
	db	144,146,147,148,150,151,152,153
	db	155,156,157,159,160,161,162,164
	db	165,166,167,169,170,171,173,174
	db	175,176,178,179,180,182,183,184
	db	185,187,188,189,190,192,193,194
	db	196,197,198,199,201,202,203,205
	db	206,207,208,210,211,212,213,215
	db	216,217,219,220,221,222,224,225
	db	226,228,229,230,231,233,234,235
	db	237,238,239,240,242,243,244,245
	db	247,248,249,251,252,253,254,255

	db	255,255,255,255,255,255,255,255	;force 1 byte mph display
	db	255,255,255,255,255,255,255,255	;force 1 byte mph display
	db	255,255,255,255,255,255,255,255	;force 1 byte mph display
	db	255,255,255,255,255,255,255,255	;force 1 byte mph display
	db	255,255,255,255,255,255,255,255	;force 1 byte mph display
	db	255,255,255,255,255,255,255,255	;force 1 byte mph display
	db	255,255,255,255,255,255,255,255	;force 1 byte mph display

;	db	257,258,260,261,262,263,265,266
;	db	267,268,270,271,272,274,275,276
;	db	277,279,280,281,283,284,285,286
;	db	288,289,290,291,293,294,295,297
;	db	298,299,300,302,303,304,306,307
;	db	308,309,311,312,313,314,316,317
;	db	318,320,321,322,323,325,326

;-----------------------------------------------------------------------------

motosndtire	;make motor and skidding sound and indicate tire wear

	stx motosndtiretask

;	jsr PICaput
;	dw  needlea

;	lda #0
;	sta PICxhi,x
;	sta PICyhi,x

	lda #gasuse
	sta TSKsecwait,x	;fractional gas

;	lda #220
;	sta PICylo,x

	lda #$13	;low nibble is motor volume
	sta nidutyA
	lda #%00000000
	sta nisweepA

	lda #$12	;for car passing sound
	sta nidutyB
	lda #%00000000
	sta nisweepB

	lda #22
	sta gas		;fill'er up

	lda #1		;the following
	jsr TSKwait	;jsr displaygas was not working. maybe this will fix it

	jsr displaygas

taloop

;	lda #16		;set tire wear indicator, left edge of gauge.
;	clc
;	adc tires
;	sta PICxlo,x

;motor sound (digital)

;	dec digmotocnt
;	bne ?NOMO
;	lda #200
;	sec
;	sbc onebytexspeed
;	lsr a
;	lsr a
;	lsr a
;	lsr a
;	sta digmotocnt
;	lda #$0f
;	sta niwrst
;	lda #$10
;	sta niwrst
;?NOMO

;motor sound (osc)
	lda gas
	cmp #2
	bcs ?nosputter
	jsr nirandom
	cmp #128
	bcs ?motoroff		;sputter motor sound when < 2gal gas left
?nosputter
	lda #0
	sta tmp+1
	lda #$e0
	sta tmp+2		;for car passing sound
	lda #4
	sta tmp+3		;for car passing sound

	lda onebytexspeed
	cmp #32			;minimum speed sound off (saves my ears)
	bcc ?motoroff
	asl a
	rol tmp+1
	sta tmp

	lda #0
	sec
	sbc tmp
	sta nifreqlA
	sta tmp+2		;for car passing sound
	lda #4
	sbc tmp+1
	sta nifreqhA
	sta tmp+3		;for car passing sound

?motoroff
;	ldy mytask		;real skid sound should be done at SKID
;	lda TSKskidding,y
;	beq ?nonoise
;	lda #$0f		;skid sound
;	sta nidutyD
;	lda #$0d
;	sta nifreqD
;	lda #$ff
;	sta nilengthD
?nonoise

;car passing sound

	lda #$ff
	sta tmp
	ldy #8
?slp
	ldx tsknums,y
	lda PICxhi,x
	bne ?tobig
	lda PICxlo,x
	sec
	sbc #128
	bpl ?noneg
	eor #$ff
	clc
	adc #1
?noneg	cmp tmp
	bcs ?tobig
	sta tmp
?tobig	dey
	bpl ?slp
	lda tmp
	cmp #32
	bcc ?goodvol
	lda #31
?goodvol
	lsr a		;to access a table of 8 values
	lsr a
	tay
	lda passvol,y
	ora #$d0	;set wave, rept, no decay (was $f0)
	sta nidutyB

;	lda #$7f
;	sta $4005

	lda tmp+2
	sec
	sbc #$10	;the passing car engine is a little higher than yours
;	lda #$b0
	sta nifreqlB
	bcc ?nocar
	dec tmp+3
	lda tmp+3
	and #%00000111
	sta tmp+3
?nocar	lda tmp+3
;	lda #$fa
	sta nifreqhB

;gas gauge

	lda #nibutA
	bit nijoy
	beq ?nogas
	dec TSKsecwait,x	;fractional gas
	bne ?nogas

	lda #gasuse
	sta TSKsecwait,x	;fractional gas
	dec gas
	jsr displaygas
?nogas

	lda rasterspritey
	cmp #dashy
	beq ?nodashjerk
	dec rasterspritey
?nodashjerk

?wait
	lda #1
	jsr TSKwait

	lda taskclock
	and #1
	bne ?wait

	lda endofraceflag
	bne ?wait
	jmp taloop

passvol	db 5,5,4,4,3,2,1,0

;-----------------------------------------------------------------------------
displaygas
	lda #137
	sta space
	lda #14			;x
	sta tmp
	lda #23
	sta tmp+1
	lda gas
	bpl ?gasok
	lda #0
?gasok
	jsr numout2		;display GAS

	lda #14			;x
	sta tmp
	lda #23
	sta tmp+1

	ldy #45		;char zero tens gas
	lda gas
	beq ?tenout
	bmi ?tenout
	cmp #10
	bcc ?tenout
	iny
	cmp #20
	bcc ?tenout
	iny
?tenout
	tya
	jsr charout
	rts
;-----------------------------------------------------------------------------

;bodycondition			;indicate body condition
;
;	stx bodytask
;
;	jsr PICaput
;	dw  needlea
;
;	lda #0
;	sta PICxhi,x
;	sta PICyhi,x
;;	sta dollarcnt
;
;	lda #220
;	sta PICylo,x
;
;?boloop
;
;	lda #152		;set tire wear indicator, left edge of gauge.
;	clc
;	adc body
;	sta PICxlo,x
;
;;money stuff was here
;
;?wait
;	lda #1
;	jsr TSKwait
;
;	lda taskclock
;	and #1
;	bne ?wait
;
;	jmp ?boloop



damagebody1		;nudge
	lda #1
	jmp damcont

damagebody2		;severe hit  (+nudge)
	lda #3
	jmp damcont

damagebody3		;crash with guardrail
	lda #7

damcont
	sty tmp+3	;save y reg
	clc
	adc body
	sta body
	cmp #87
	bcc ?nolimit
	lda #87
	sta body
?nolimit
;update body damage gauge

	lsr a
	lsr a
	lsr a
	clc
	adc #19			;left edge of gauge
	sta tmp			;x pos
	cmp damchange
	beq ?nochange
	sta damchange
	dec tmp
	lda #26			;y pos
	sta tmp+1
	lda #0
	sta space
	lda #223		;full bar char
	jsr charout
	lda damchange
	sta tmp			;x pos

?nochange
	lda #26			;y pos
	sta tmp+1
	lda #0
	sta space
	lda body
	lsr a
	and #%00000011
	tay
	lda bargauge,y
	jsr charout
	ldy tmp+3	;restore y reg
	rts

;-----------------------------------------------------------------------------

pit
	dec TSKyh,x
	dec TSKyh,x
	jsr negplyspeed

	jsr TSKschedule
	dw pitstop

	ldx starttask
	inc PICxhi,x	;turn off possible flag



	lda #1
	jsr TSKwait	;entire pit sequence takes place during this wait



	jsr nividon

	jsr displaylap
	jsr displaytlap

	lda #1
	jsr TSKwait

	lda #1
	sta dashboard
	sta splitpalflag

	lda #$ff
	sta place	;force screen update

	jsr displaygas

	ldx starttask
	dec PICxhi,x	;turn on possible flag

	ldx mytask
	jmp pitreturn

pitstop

	jsr TSKschedule
	dw gastank
	sta TSKxl,x	;save gastank's task index so I can cancel it later

	ldx mytask
	jsr taskoff

	ldx speedometertask
	jsr taskoff

	ldx motosndtiretask
	jsr taskoff

;	ldx bodytask
;	jsr taskoff

			;don't create tasks after here in this task
	ldy #8
	lda #0
?canceldrones
	ldx tsknums,y
	jsr taskoff
	dey
	bpl ?canceldrones

	ldx TSKcurrent

	jsr TSKvblank
	dw  pitpal	;routine to reinstate pit background palette


	lda #0
	sta PICvramflag
	sta vrambp
	sta vrambuf

	sta niscrollv
	sta sv_niscrollh
	sta sv_niscrollm
	sta niscrolll
	sta niscrollh
	sta niscrollm

	lda #2
	sta splitpalflag

	inc ninmi	;turn off int
	jsr nividoff
	jsr write_bigcarj

;	lda #1
;	sta nibnkchrSH	;big car character bank

	ldx TSKcurrent

	lda #113
	sta rasterspritey

	lda #0
	sta niscrollh
;	lda #1
;	sta dashboard

	lda #2
	sta splitbsprbnk
	lda #3
	sta splitbchrbnk

	lda #0
	sta splitbh
	lda #0
	sta nibnksprSH	;top of screen character bank
	lda #12
	sta nibnkchrSH	;top of screen character bank


;	jsr PICstring
;	db 4,7,"SCREEN1 PIT ART GOES HERE",0
;	jsr PICvramOut

;	jsr PICstring
;	db 16,9+30,"SCREEN2 PIT ART GOES HERE",0
;	jsr PICvramOut

	jsr PICstring
	db 1,14,$ff,0		;raster sprite hits this char
	jsr PICvramOut

	lda #1
	sta PICvramflag
	jsr nividon
	lda #nibgblk+niobjblk+niobjlblk+nibglblk	;turn off left column blanking
	sta nicr1SH
	dec ninmi	;turn on int


	lda #20
	jsr TSKwait	;look at that beautiful pit area before car enters

	jsr skidsound

	lda #4
	jsr TSKwait

	lda #12			;pit entry speed
	sta TSKxspeedh,x
	lda #0
	sta TSKxspeedl,x
?rollin
	lda TSKxspeedl,x
	sec
	sbc #$40		;decelerarion rate
	sta TSKxspeedl,x
	lda TSKxspeedh,x
	sbc #0
	sta TSKxspeedh,x

	lda niscrolll
	clc
	adc TSKxspeedl,x
	lda splitbh
	adc TSKxspeedh,x
	sta splitbh

	lda #1
	jsr TSKwait

	lda splitbh
	cmp #$fe
	bcc ?rollin



;	lda #$ff		;stopping bounce
;	sta niscrollv
;	lda #2
;	jsr TSKwait
;	lda #1
;	sta niscrollv
	lda #$fe
	sta splitbh

;	lda #15
;	jsr TSKwait

;spin wrench

	jsr PALset		;set sprite palette
	db	16			;offset into palette
	db	$0F,$26,$06,$16
	db	$0F,$00,$0f,$28
	db	$0F,$2C,$0c,$1c
	db	$ff			;terminator

	jsr PICaput
	dw  wrena1
	lda #0
	sta PICxhi,x
	sta TSKaccel,x		;will be used to store joystick pos.

	lda #5
	sta TSKcarnum,x		;number of wrench revolutions
	lda #0
	sta TSKxm,x		;tire on/off flag 1=on 0=off
	sta TSKxh,x		;tire front/rear flag 1=rear 0=front


wrenlp
	lda nijoy
	and #$0f		;mask off buttons
	beq ?norevj
	sta tmp
	ldy TSKaccel,x		;index for next joystick position
	lda TSKxm,x
	bne ?tireon
	lda nextposoff,y
	jmp ?tireoff
?tireon
	lda nextpos,y
?tireoff
	cmp tmp
	bne ?norevj
	jsr wrenchsnd
	inc TSKaccel,x		;index for next joystick position
	lda TSKaccel,x
	cmp #8
	bne ?norevj
	lda #0
	sta TSKaccel,x
	lda TSKxm,x
	bne ?tireon3
	dec TSKcarnum,x
	bne ?norevj
	inc TSKcarnum,x		;zero it
	inc TSKxm,x		;tire on/off flag 1=on 0=off
;	lda #3
;	sta PICattr,x		;change wrench color
	jsr wrenchsnd2


;change tires  (the change routines are to big to be here they both end
;	        by jumping to norev)

	lda TSKxh,x		;tire front/rear flag 1=rear 0=front
	bne ?changerearj
	jmp changefront
?changerearj
	jmp changerear


?norevj	jmp norev

?tireon3
	inc TSKcarnum,x
	lda TSKcarnum,x
	cmp #6
	bne norev
;switch to rear tire
	lda #2
	sta PICattr,x		;change wrench color
	jsr wrenchsnd2
	dec TSKcarnum,x		;to 5
	lda TSKxh,x		;tire front/rear flag 1=rear 0=front
	beq ?frontdone
	jmp bothtiresdone
?frontdone
;change to rear tire
	lsr tires		;improve tires by half
	inc TSKxh,x		;tire front/rear flag 1=rear 0=front
	dec TSKxm,x		;tire on/off flag 1=on 0=off
;animate wrench to rear tire
?torear	inc PICxlo,x
	inc PICxlo,x
	inc PICxlo,x
	lda PICxlo,x
	cmp #190
	bcs norev
	lda #1
	jsr TSKwait
	jmp ?torear


norev
	ldy TSKaccel,x
	lda TSKxm,x
	bne ?tireon2
	lda nextposoff,y
	jmp ?tireoff2
?tireon2
	lda nextpos,y
?tireoff2
	tay
	lda wrenpicl,y
	sta PICadrLo,x

	lda wrenpich,y
	sta PICadrHi,x


	lda TSKxh,x
	beq ?front		;rear tires?
	lda wrenxrear,y
	jmp ?rear
?front	lda wrenx,y
?rear	sta PICxlo,x
	lda wreny,y
	sta PICylo,x

?nojoy
	lda #200
	sta PICatime,x		;don't let timer expire
	lda #1
	jsr TSKwait
	lda #niselect
	bit joy0
	bne ?tirestight
	jmp wrenlp


;are tires tight? (can he exitpit)
?tirestight
	lda TSKcarnum,x		;number of wrench revolutions
	cmp #5
	bne ?nottight
	lda TSKaccel,x
;	cmp #1
	beq exitpit
?nottight
	lda #0
	sta space
	jsr PICstring
	db 13,12,101,102,103,104,105,106,0	;this says LOOSE TIRE

	lda #%11010110
	sta $4000
	lda #%11000100
	sta $4001
	lda #%00000000
	sta $4002
	lda #$fc
	sta $4003

	lda #60
	jsr TSKwait
	lda #0
	sta space
	jsr PICstring
	db 13,12,76,27,76,27,76,27,0		;this replaces checkerboard
	jmp wrenlp



bothtiresdone
	lda #0
	sta tires
	inc PICxhi,x	;remove wrench from screen
?waitforselect
	lda #1
	jsr TSKwait
	jsr nirandom	;randomize the random routine
	lda #niselect
	bit nijoy
	beq ?waitforselect

exitpit
	inc PICxhi,x	;remove wrench from screen

	lda TSKxl,x	;saved gascan's task index
	tax
	inc PICxhi,x	;remove gas can from screen
	jsr TSKcancel	;cancel gastank task

	lda TSKxm,x	;get tenths gal
	tay
	ldx motosndtiretask
	lda #0
?tenlp	dey
	bmi ?tendone
	clc
	adc #tenthgal+1
	jmp ?tenlp

?tendone
	sta TSKsecwait,x	;fractional gas
	ldx TSKcurrent

	jsr skidsound

	lda #4
	jsr TSKwait

	lda #0
	sta TSKxspeedh,x
	sta TSKxspeedl,x
	sta niscrollv
	sta splitbh
	lda #1
	sta splitbm
?rollout
	lda TSKxspeedl,x
	clc
	adc #$40		;accelerarion rate
	sta TSKxspeedl,x
	lda TSKxspeedh,x
	adc #0
	sta TSKxspeedh,x

	lda niscrolll
	clc
	adc TSKxspeedl,x
	lda splitbh
	adc TSKxspeedh,x
	sta splitbh

	lda #1
	jsr TSKwait
	lda TSKxspeedh,x
;	lda splitbh
	cmp #11
	bne ?rollout

	lda #$ff
	sta splitbh

	lda #20
	jsr TSKwait	;pause after car exits


	inc ninmi	;turn off int
	jsr niscrclr

	lda meloflag
	bne ?melo
	jsr palgame
	jmp ?nomelo
?melo	jsr palgamem
?nomelo

	jsr getraceinfoadr
	ldy #pitexitscreen
	lda (tmp),y
	ldx mytask
	sta TSKxm,x
	jsr scroll	;sets niscrollh and niscrollm
	lda niscrollh
	sta sv_niscrollh
	lda niscrollm
	sta sv_niscrollm
	jsr setupscreenp

	jsr buffer_slice
	jsr TSKvblank
	dw sliceout		;place new map slices in blanked screen column

	lda #0
	sta nibnksprSH	;character bank
	lda #11
	sta nibnkchrSH	;character bank


	lda #dashy
	sta rasterspritey

	lda #0
	sta dashboard
	sta splitbh
	sta splitbm

	lda #10			;was 1
	sta splitbchrbnk
	sta splitbsprbnk
	sta PICvramflag

	ldx mytask
	jsr taskon

	ldx speedometertask
	jsr taskon

	ldx motosndtiretask
	jsr taskon

;	ldx bodytask
;	jsr taskon

	ldy #8
	lda #0
?droneson
	ldx tsknums,y
	jsr taskon

	lda laptimeh	;number of screens to advance drones=number of seconds
	bne ?not0	;in pit FOR NOW.
	lda #1
?not0	sta tmp
?advance
	dec TSKxm,x
	lda TSKxm,x
	cmp trackwrap		;wrap track
	bne ?nowrap
	inc TSKlap,x
	lda #$ff
	sta TSKxm,x
?nowrap	dec tmp
	bne ?advance

	dey
	bpl ?droneson

	ldx TSKcurrent

;reset sound registers for motor and passing car
	lda #$13	;low nibble is motor volume
	sta nidutyA
	lda #%00000000
	sta nisweepA

	lda #$12	;for car passing sound
	sta nidutyB
	lda #%00000000
	sta nisweepB




;restore tire and damage gauges

;update tire gauge
	lda tires
	beq ?nottip
	pha
	lsr a
	tay
	lsr a
	lsr a
	clc
	adc #2			;left edge of gauge
	sta tmp			;x pos
	tya
	and #%00000011
	tay
	lda #26			;y pos
	sta tmp+1
	lda #0
	sta space
	lda bargauge,y
	jsr charout		;tip of gauge

?tirelp
	pla
	sec
	sbc #8
	bmi ?tiregaugedone

	pha
	lsr a
	lsr a
	lsr a
	clc
	adc #2			;left edge of gauge
	sta tmp			;x pos
	lda #26			;y pos
	sta tmp+1
	lda #223
	jsr charout		;solid part of gauge
	jmp ?tirelp
?tiregaugedone
	jsr PICvramOut
?nottip
;update body gauge
	lda body
	beq ?nobtip
	pha
	lsr a
	tay
	lsr a
	lsr a
	clc
	adc #19			;left edge of gauge
	sta tmp			;x pos
	tya
	and #%00000011
	tay
	lda #26			;y pos
	sta tmp+1
	lda #0
	sta space
	lda bargauge,y
	jsr charout		;tip of gauge

?bodylp
	pla
	sec
	sbc #8
	bmi ?bodygaugedone

	pha
	lsr a
	lsr a
	lsr a
	clc
	adc #19			;left edge of gauge
	sta tmp			;x pos
	lda #26			;y pos
	sta tmp+1
	lda #223
	jsr charout		;solid part of gauge
	jmp ?bodylp
?bodygaugedone
	jsr PICvramOut
?nobtip

	dec ninmi	;turn on int

	ldx TSKcurrent
	jsr TSKcancel		;cancel myself (pitstop task)
	rts			;never to return

;-----------------------------------------------------------------------------

changefront
	jsr PICaput
	dw  tirestill

ftx	equ 52			;front tire x
fty	equ 207			;front tire y
drop	equ 12			;drop and raise tire by this much

	lda #ftx
	sta PICxlo,x
	lda #fty
	sta PICylo,x

	lda #0
	sta PICxhi,x

	lda #1
	jsr TSKwait		;put out tire sprite

	jsr frontwell
	ldy #drop		;move down this much
?tiredown
	lda #1
	jsr TSKwait
	inc PICylo,x
	dey
	bne ?tiredown

	jsr PICaput
	dw  tire
?tireout
	lda #1
	jsr TSKwait
	lda PICxlo,x
	sec
	sbc #4
	sta PICxlo,x
	bcs ?nowrap
	dec PICxhi,x
?nowrap
	ldy PICxhi,x
	beq ?tireout
	cmp #256-40
	bcs ?tireout

	lda #40			;pause while they get the new tire
	jsr TSKwait
	inc PICxhi,x
	lda #$ff
	sta PICxlo,x

?tirein
	lda #1
	jsr TSKwait
	lda PICxlo,x
	sec
	sbc #4
	sta PICxlo,x
	cmp #ftx
	bcs ?tirein

	lda #ftx
	sta PICxlo,x
	jsr PICaput
	dw  tirestill
	ldy #drop		;move up this much
?tireup
	lda #1
	jsr TSKwait
	dec PICylo,x
	dey
	bne ?tireup

	jsr fronttire
	lda #1
	jsr TSKwait
	jsr PICaput
	dw  wrena1

	lda #3
	sta PICattr,x		;change wrench color

	jmp norev


changerear
	jsr PICaput
	dw  tirestill

rtx	equ 192			;front tire x

	lda #rtx
	sta PICxlo,x
	lda #fty
	sta PICylo,x

	lda #0
	sta PICxhi,x

	lda #1
	jsr TSKwait		;put out tire sprite

	jsr rearwell
	ldy #drop		;move down this much
?tiredown
	lda #1
	jsr TSKwait
	inc PICylo,x
	dey
	bne ?tiredown

	jsr PICaput
	dw  tire
?tireout
	lda #1
	jsr TSKwait
	lda PICxlo,x
	sec
	sbc #4
	sta PICxlo,x
	bcs ?nowrap
	dec PICxhi,x
?nowrap
	ldy PICxhi,x
	beq ?tireout
	cmp #256-40
	bcs ?tireout

	lda #40			;pause while they get the new tire
	jsr TSKwait
	inc PICxhi,x
	lda #$ff
	sta PICxlo,x

?tirein
	lda #1
	jsr TSKwait
	lda PICxlo,x
	sec
	sbc #4
	sta PICxlo,x
	cmp #rtx
	bcs ?tirein

	lda #rtx
	sta PICxlo,x
	jsr PICaput
	dw  tirestill
	ldy #drop		;move up this much
?tireup
	lda #1
	jsr TSKwait
	dec PICylo,x
	dey
	bne ?tireup

	jsr reartire
	lda #1
	jsr TSKwait
	jsr PICaput
	dw  wrena1

	lda #3
	sta PICattr,x		;change wrench color

	jmp norev

;-----------------------------------------------------------------------------

fronttire
	lda #$ff
	sta space
	jsr PICstring
	db 6,21+32
	DB $6A-1,$6B-1,$6C-1,$6D-1,$6E-1
	db 0
	jsr PICstring
	db 6,22+32
	DB $84-1,$85-1,$86-1,$87-1,$88-1
	db 0
	jsr PICstring
	db 6,23+32
	DB $A3-1,$A4-1,$A5-1,$A6-1,$A7-1
	db 0
	jsr PICstring
	db 6,24+32
	DB $C1-1,$C2-1,$C3-1,$C4-1,$C5-1
	db 0
	rts
frontwell
	lda #$ff
	sta space
	jsr PICstring
	db 6,21+32
	DB $6A-1,$E8-1,$E9-1,$00-1,$EA-1
	db 0
	jsr PICstring
	db 6,22+32
	DB $EE-1,$EF-1,$F0-1,$F1-1,$F2-1
	db 0
	jsr PICstring
	db 6,23+32
	DB $F5-1,$F6-1,$F7-1,$00-1,$F8-1
	db 0
	jsr PICstring
	db 6,24+32
	DB $FA-1,$FB-1,$FC-1,$FD-1,$FE-1
	db 0
	rts
reartire
	lda #$ff
	sta space
	jsr PICstring
	db 24,21+32
	db $77-1,$78-1,$79-1,$7A-1,$7B-1
	db 0
	jsr PICstring
	db 24,22+32
	db $95-1,$96-1,$97-1,$98-1,$99-1
	db 0
	jsr PICstring
	db 24,23+32
	db $B4-1,$B5-1,$B6-1,$B7-1,$DD-1
	db 0
	jsr PICstring
	db 24,24+32
	db $CF-1,$D0-1,$D1-1,$D2-1,$E2-1
	db 0
	rts
rearwell
	lda #$ff
	sta space
	jsr PICstring
	db 24,21+32
	db $EB-1,$EC-1,$00-1,$ED-1,$7B-1
	db 0
	jsr PICstring
	db 24,22+32
	db $F3-1,$EF-1,$F0-1,$F1-1,$F4-1
	db 0
	jsr PICstring
	db 24,23+32
	db $00-1,$F6-1,$F7-1,$00-1,$F9-1
	db 0
	jsr PICstring
	db 24,24+32
	db $00-1,$FB-1,$FC-1,$FD-1,$FF-1
	db 0
	rts

;-----------------------------------------------------------------------------
pitpal
	lda	#>nipal			;establish pit palette
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;

	ldx	#0
pallp	lda	pit_pal,x		;
	sta	nivramdata		;
	inx
	cpx	#16
	bne	pallp			;
	rts

pit_pal:
	db	$0F,$28,$16,$20		;black	yellow	red	white
	db	$0F,$10,$16,$20		;black	lt gray	red	white
 	db	$0F,$12,$16,$20		;black	medblue	red	white
 	db	$0F,$2C,$2A,$20		;black	lt cyan	green	white


;-----------------------------------------------------------------------------
taskoff
	lda #%01111111
	and TSKflags,x
	sta TSKflags,x	;cancels task
	rts

taskon
	lda TSKflags,x
	ora #%10000000
	sta TSKflags,x	;task on
	rts

wrenchsnd
	lda #$14
	sta nidutyA
	lda #$00
	sta nisweepA

	lda TSKcarnum,x
	asl a
	asl a
	asl a
	ldy TSKxm,x
	bne ?addit
	sec
	sbc TSKaccel,x
	jmp ?subit
?addit	clc
	adc TSKaccel,x
?subit	ldy #0
	sty tmp

	sta tmp+1
	lda #96		;raise this number to lower wrench sound (min=48)
	sec
	sbc tmp+1	;invert direction of sound

	asl a		;move b7 b6 b5 to b2 b1 b0 for freqh
	rol tmp
	asl a
	rol tmp
	asl a
	rol tmp
	sta nifreqlA
	lda tmp
	ora #%00011000
	sta nifreqhA

	lda #$14		;and a little noise
	sta nidutyD
	lda #$8f
	sta nifreqD
	lda #$28
	sta nilengthD
	rts

wrenchsnd2
	lda #$15
	sta nidutyD
	lda #$85
	sta nifreqD
	lda #$28
	sta nilengthD
	rts


charout
	sta numoutn
	lda #0
	sta numoutn+1
	sta PICvramflag

	ldy tmp+1		;the y coordinate
	lda tmp
	jsr PICcurSet			;set the cursor

	lda #<numoutn
	ldy #>numoutn
	jsr PICstring2

	lda #1
	sta PICvramflag
	rts

; joystick directions
;
;  10  8  9
;    \ | /
;  2 -   - 1
;    / | \
;   6  4  5
nextpos	db 8,9,1,5,4,6,2,10
nextposoff	db 10,2,6,4,5,1,9,8

wrenx
	db $00,$47,$31,$00,$3b,$44,$35,$00,$44,$43,$34,$00,$00,$00,$00
wrenxrear
	db $00+140,$47+140,$31+140,$00+140,$3b+140,$44+140,$35+140,$00+140,$44+140,$43+140,$34+140,$00+140,$00+140,$00+140,$00
wreny
	db $08,$c7,$c5,$00,$d1,$cd,$ce,$00,$ba,$be,$be,$00,$00,$00,$00

wrenpicl
	db 0,<wren3,<wren7,0,<wren5,<wren4,<wren6,0,<wren1,<wren2,<wren8
	db 0,0,0,0,0
wrenpich
	db 0,>wren3,>wren7,0,>wren5,>wren4,>wren6,0,>wren1,>wren2,>wren8
	db 0,0,0,0,0


wrena1
	anim	20,wren1
	animend	wrena1
wrena2
	anim	20,wren2
	animend	wrena2
wrena3
	anim	20,wren3
	animend	wrena3
wrena4
	anim	20,wren4
	animend	wrena4
wrena5
	anim	20,wren5
	animend	wrena5
wrena6
	anim	20,wren6
	animend	wrena6
wrena7
	anim	20,wren7
	animend	wrena7
wrena8
	anim	20,wren8
	animend	wrena8


wren1	db 2, 3, 2 ; width, height, color code
	db  01,00
	db  15,00
	db  35,36
wren2	db 3, 3, 2 ; width, height, color code
	db  00,02,03
	db  16,17,18
	db  37,38,00
wren3	db 3, 3, 2 ; width, height, color code
	db  04,00,00
	db  19,20,21
	db  39,00,00
wren4	db 3, 3, 2 ; width, height, color code
	db  05,06,00
	db  22,23,24
	db  00,40,41
wren5	db 3, 3, 2 ; width, height, color code
	db  07,08,09
	db  00,25,00
	db  00,42,00
wren6	db 3, 3, 2 ; width, height, color code
	db  00,10,11
	db  26,27,28
	db  43,44,00
wren7	db 3, 3, 2 ; width, height, color code
	db  00,00,12
	db  29,30,31
	db  00,00,45
wren8	db 3, 3, 2 ; width, height, color code
	db  13,14,00
	db  32,33,34
	db  00,46,47

;tire patterns

tire
	anim	2,tire1
	anim	2,tire2
	anim	2,tire3
	animend	tire

tirestill
	anim	250,tire1
	animend	tirestill



tire1	db 5, 5, 1 ; width, height, color code
	db 94,95,96,97,98
	db 99,100,101,102,103
	db 220,104,105,106,107
	db 108,109,110,111,112
	db 113,114,115,116,117

tire2	db 5, 5, 1 ; width, height, color code
	db 94,118,119,97,98
	db 99,120,101,121,103
	db 220,122,123,106,124
	db 108,125,126,127,112
	db 113,128,115,116,117

tire3	db 5, 5, 1 ; width, height, color code
	db 94,129,130,97,98
	db 131,132,133,134,135
	db 136,220,137,138,139
	db 108,140,141,142,143
	db 113,114,144,145,117



;-----------------------------------------------------------------------------
gastank

tankrt	equ 203		;tanks right x pos

	lda #70
	jsr TSKwait		;wait for car to enter pit

	jsr PICaput
	dw  gastleft

	lda #0
	sta PICxhi,x
	sta laptimel
	sta laptimeh

	lda #tankrt-8
	sta PICxlo,x
	lda #166
	sta PICylo,x

;calc tenths of gallons left
	ldx motosndtiretask
	lda TSKsecwait,x
	ldx TSKcurrent
	ldy #$ff
	sec
?cntten	iny
	sbc #tenthgal+1
	bcs ?cntten
	tya
	sta TSKxm,x		;fractional gas

	lda #226
	sta space
	jsr displaypitgas


gaslp
	lda #226
	sta space

	lda #nibutB
	bit nijoy
	beq ?noa
	lda #nibutA
	bit nijoy
	bne ?noa
	jsr PICaput
	dw  gastleft
	lda #tankrt-8
	sta PICxlo,x
?noa

	lda PICxlo,x
	cmp #tankrt-8		;is tank left?
	bne ?nob
	lda gas
	cmp #22			;is tank full?
	beq ?nob
	lda #nibutA
	bit nijoy		;is button B down?
	beq ?nob
	lda #nibutB		
	bit nijoy		;is button A up?
	bne ?nob
	jsr PICaput
	dw  gastright
	lda #tankrt		;tanks right pos
	sta PICxlo,x

	inc TSKxm,x		;fractional gas
	lda TSKxm,x
	cmp #10
	bne ?nocary
	lda #0
	sta TSKxm,x
	inc gas
?nocary	jsr displaypitgas

	lda #$94		;gas glug sound
	sta nidutyB
	lda #$9b
	sta nisweepB
	lda #$00
	sta nifreqlB
	lda #$6b
	sta nifreqhB
?nob

	lda #8			;x pos
	sta tmp
	lda #8			;y pos
	sta tmp+1
	lda #100		;percent
	sec
	sbc tires
	jsr numout		;display tire condition in pit

;inc pit timer
	inc laptimel
	lda laptimel
	cmp #60
	bne ?nosecond
	lda #0
	sta laptimel
	inc laptimeh
?nosecond


	lda #17			;x pos
	sta tmp
	lda #8			;y pos
	sta tmp+1
	lda laptimel
	jsr numout2		;display pit time (sixtyiths)

	lda #13			;x pos
	sta tmp
	lda #8			;y pos
	sta tmp+1
	lda laptimeh
	jsr numout		;display pit time

;animate background flags

	lda #0
	sta space

	jsr nirandom
	and #%00000111
	tax
	ldy #4
	lda yelx,x
	tax
	jsr nirandom
	and #1
	beq ?yel1
	jsr PICstringXY
	db 110,111,0		;yellow 2
	jmp ?red
?yel1	jsr PICstringXY
	db 17,18,0		;yellow 1

?red
	jsr nirandom
	and #%00000111
	tax
	ldy #4
	lda redx,x
	tax
	jsr nirandom
	and #1
	beq ?red1
	jsr PICstringXY
	db 108,109,0		;red 2
	jmp ?flagdone
?red1	jsr PICstringXY
	db 15,16,0		;red 1

?flagdone
;	ldx TSKcurrent

	lda #1
	jsr TSKwait
	jmp gaslp




redx	db 6,10,14,18,22,6,10,14
yelx	db 8,12,16,20,24,8,12,16

displaypitgas

	lda #22			;x pos
	sta tmp
	lda #8			;y pos
	sta tmp+1
	lda TSKxm,x		;fractional gas
	jsr numout2

	lda #21			;x pos
	sta tmp
	lda #8			;y pos
	sta tmp+1
	lda gas
	jsr numout2

	rts

gastleft
	anim	20,gast
	animend	gastleft

gast	db 6, 3, 0 ; width, height, color code
	db  80,81,82,83,0,0
	db  84,85,86,87,0,0
	db  88,89,90,91,92,92

gastright
	anim	20,gasti
	animend	gastright

gasti	db 5, 3, 0 ; width, height, color code
	db  80,81,82,83,0
	db  84,85,86,87,0
	db  88,89,90,91,92


;-----------------------------------------------------------------------------

carcolor	db 0,2,3,2,0,2,3,0,3,1	;last one is players color
carpat		db 0,2,0,1,1,0,1,2,2	;car patterns (one of each color)

;complete range of starting x's for the pack (120 is players x)
stxtbl		db 15,15,15,50,50,50,85,85,85
		db 120,120,120,155,155,155,190,190,190

lanetoptbl	db lane3top,lane2top,lane1top
		db lane3top,lane2top,lane1top
		db lane3top,lane2top,lane1top,lane2top

;lanebottbl	db lane3top+lanewidth,lane2top+lanewidth,lane1top+lanewidth
;		db lane3top+lanewidth,lane2top+lanewidth,lane1top+lanewidth
;		db lane3top+lanewidth,lane2top+lanewidth,lane1top+lanewidth,lane2top+lanewidth


;other cars in drones lane to coll-detect with. indexed by TSKcarnum*2
yourlane	db 3,6,4,7,5,8,0,6,1,7,2,8,0,3,1,4,2,5

;for accessing lane1y
laneoffset
	db 64,32,0,64,32,0,64,32,0

backpac db 9,9,9,6,6,6,3,3,3,0

mod3	db 0,1,2,0,1,2,0,1,2,0


;==============================================================================

HDRONE

	ldy plstpos
	lda backpac,y
	clc
	adc TSKcarnum,x
	tay
	lda stxtbl,y
	sta tmp

;bump back if player is in your lane and ahead or on you

	lda TSKcarnum,x
	cmp plstpos
	bcc ?nobump

	tay
	lda mod3,y
	ldy plstpos
	cmp mod3,y
	bne ?nobump

	lda tmp
	clc
	adc #35			;x car spacing in starting pack
	sta tmp
?nobump
	lda tmp
	sta TSKxh,x

	ldy TSKcarnum,x
	lda lanetoptbl,y
	clc
	adc #lanewidth/2
	sta TSKyh,x

	lda mod3,y		;spread out the pack vertically a little
	cmp #1
	beq ?spreaddone
	cmp #2
	beq ?up
	inc TSKyh,x
	inc TSKyh,x
	jmp ?spreaddone
?up
	dec TSKyh,x
	dec TSKyh,x
?spreaddone

	lda #0
	sta PICyhi,x
	sta TSKlap,x
	sta TSKyl,x
	sta TSKxl,x
	sta TSKxspeedl,x
	sta TSKyspeedh,x
	sta TSKyspeedl,x
	sta TSKskidding,x

	lda trackwrap2		;start 2 screens before checkered line
	sta TSKxm,x

	lda #4			;starting speed
	sta TSKxspeedh,x


	ldy TSKcarnum,x
	lda carpat,y
	beq ?46
	cmp #1
	beq ?drone
?melo
	jsr PICaput
	dw  acar3m	;melo
	jmp ?patdone
?46
	jsr PICaput
	dw  acar3	;46
	jmp ?patdone
?drone
	jsr PICaput
	dw  acar3d	;drone
?patdone


	ldy TSKcarnum,x
	lda carcolor,y
	sta PICattr,x

	lda #100		;time to green flag
	jsr niranrange
	clc
	adc #80
	sta TSKytimer,x

	lda #100		;time to green flag
	jsr niranrange
	clc
	adc #80
	sta TSKxtimer,x

	lda #1			;accelerating (as the player should be)
	sta TSKaccel,x


hdronelp	;MAIN TASK LOOP----------------------------------------------


; change lanes?

	dec TSKytimer,x
	bne ?noturn

	lda #80
	jsr niranrange
	clc
	adc #10
	sta TSKytimer,x

	lda #0
	sta TSKyspeedl,x
	sta TSKyspeedh,x

	jsr nirandom
	cmp #127		;50/50 to go straight
	bcs ?noturn

	lda #100
	jsr niranrange
	clc
	adc #1
	sta TSKyspeedl,x

	jsr nirandom
	cmp #127		;50/50 to go left or right
	bcs ?noturn

	jsr negyspeed

?noturn
; y move

	clc			;add yspeed to y
	lda TSKyl,x
	adc TSKyspeedl,x
	sta TSKyl,x
	lda TSKyh,x
	adc TSKyspeedh,x
	sta TSKyh,x

; limit y
	ldy TSKcarnum,x
	lda laneoffset,y
	tay
	lda TSKyh,x

	sec
	sbc #2		;lane separation

	cmp lane1y,y
	bcs ?notoplim
	lda lane1y,y

	clc
	adc #2		;lane separation

	sta TSKyh,x
	jsr negyspeed
?notoplim
	lda TSKyh,x

	clc
	adc #2		;lane separation

	cmp lane2y,y
	bcc ?nobotlim
	lda lane2y,y

	sec
	sbc #3		;lane separation

	sta TSKyh,x
	jsr negyspeed
?nobotlim


; y collision?
;collision detect with other drones in your lane
;
;	lda TSKcarnum,x
;	asl a
;	tay
;	lda yourlane,y
;	tay
;	lda tsknums,y
;	tay
;	jsr lcollision
;	bcs ?hitcary
;
;	lda TSKcarnum,x
;	asl a
;	tay
;	lda yourlane+1,y
;	tay
;	lda tsknums,y
;	tay
;	jsr lcollision
;	bcs ?hitcary
;
;	ldy mytask
;	jsr lcollision
;	bcc ?nohitcary
;	jsr nudgesnd
;	jsr damagebody1
;?hitcary
;	lda oldyl		;undo the y movement
;	sta TSKyl,x
;	lda oldyh
;	sta TSKyh,x
;	lda #0
;	sta TSKyspeedl,x
;	sta TSKyspeedh,x
;?nohitcary


; change speed?

	dec TSKxtimer,x
	bne ?nochgspeed

	lda #100
	jsr niranrange
	clc
	adc #40
	sta TSKxtimer,x		;freq. of speed change

	lda #0
	sta TSKaccel,x

	jsr nirandom
	cmp #190		;accel/decel or stop accel/decel
	bcs ?nochgspeed

	lda #6			;was 7
	jsr niranrange
	clc
	adc #1
	sta TSKaccel,x		;acceleration rate

	ldy mytask
	lda TSKlap,x
	cmp TSKlap,y
	beq ?tps		;if on same lap track to players screen
	bcc ?catchup		;catchup if I am laps behind
	jmp ?dropback		;drop back if I am laps ahead
?tps	lda TSKxm,y

	ldy TSKcarnum,x
	clc
	adc droneskill,y	;track to player's screen, plus 1, or minus 1

	cmp TSKxm,x
	beq ?ranacdc
	bcc ?catchup
	jmp ?dropback
?ranacdc
	jsr nirandom
	cmp #127		;50/50 to accel or decel
	bcs ?nochgspeed
?dropback
	jsr negxaccel

?catchup
?nochgspeed

	lda TSKskidding,x
	beq ?noskid
	dec TSKskidding,x
	bne ?notilt
?noskid

	ldy TSKcarnum,x
	lda carpat,y
	beq ?46
	cmp #1
	beq ?drone
?melo
	jsr tiltcarm
	jmp ?tiltdone
?46
	jsr tiltcar
	jmp ?tiltdone
?drone
	jsr tiltcard
?tiltdone

?notilt
	jsr xmovedrone

; x & y collision?
;collision detect with other drones in your lane

	lda TSKcarnum,x
	asl a
	tay
	lda yourlane,y
	tay
	lda tsknums,y
	tay
	jsr lcollision
	bcs ?hitcar

	lda TSKcarnum,x
	asl a
	tay
	lda yourlane+1,y
	tay
	lda tsknums,y
	tay
	jsr lcollision
	bcs ?hitcar

	ldy mytask
	jsr lcollision
	bcs ?checkxyhit
	jmp ?nohitcar
?checkxyhit
	lda TSKyl,x		;save new y
	sta tmp+1
	lda TSKyh,x
	sta tmp+2

	lda oldyl		;undo the y movement to see if it was caused
	sta TSKyl,x		;by y movement
	lda oldyh
	sta TSKyh,x
	jsr lcollision
	bcs ?xhitplayer
?yhitplayer
	jsr nudgesnd
	jsr damagebody1

	lda oldyl		;undo the y movement
	sta TSKyl,x
	lda oldyh
	sta TSKyh,x
	lda #0
	sta TSKyspeedl,x
	sta TSKyspeedh,x
	jmp ?nohitcar

?xhitplayer
	jsr nudgesnd
	jsr damagebody1
	jsr handlexhit
	lda tmp+2		;severity of collision
	beq ?nohitj

	ldx mytask
	jsr severehit		;make player skid a little
	ldx TSKcurrent
	jmp ?hithard

?hitcar
	lda TSKyl,x		;save new y
	sta tmp+1
	lda TSKyh,x
	sta tmp+2

	lda oldyl		;undo the y movement to see if it was caused
	sta TSKyl,x		;by y movement
	lda oldyh
	sta TSKyh,x
	jsr lcollision
	bcs ?xcollide
?ycollide		;yes it was caused by y movement
	lda oldyl		;undo the y movement
	sta TSKyl,x
	lda oldyh
	sta TSKyh,x
	lda #0
	sta TSKyspeedl,x
	sta TSKyspeedh,x
?nohitj	jmp ?nohitcar
?xcollide			;no it was caused by x movement
	lda tmp+1		;put back new y
	sta TSKyl,x
	lda tmp+2
	sta TSKyh,x

	jsr handlexhit
	lda tmp+2		;severity of collision
	beq ?nohitcar
?hithard
	lda TSKxh,x
	and #1
	beq ?counterclockwise


	ldy TSKcarnum,x
	lda carpat,y
	beq ?46spin
	cmp #1
	beq ?dronespin
;?melo
	jsr PICaput
	dw  spincarm
	jmp ?patdone
?46spin
	jsr PICaput
	dw  spincar
	jmp ?patdone
?dronespin
	jsr PICaput
	dw  spincard
	jmp ?patdone

?counterclockwise
	ldy TSKcarnum,x
	lda carpat,y
	beq ?46spin2
	cmp #1
	beq ?dronespin2
;?melo
	jsr PICaput
	dw  spincar2m
	jmp ?patdone
?46spin2
	jsr PICaput
	dw  spincar2
	jmp ?patdone
?dronespin2
	jsr PICaput
	dw  spincar2d
?patdone

	lda #120
	sta TSKskidding,x	;skid duration
	sta TSKxtimer,x		;don't change x speed for that long also
	lda #-6
	sta TSKaccel,x		;decceleration rate

?nohitcar

?endrace
	jsr setscreenpos
	lda #1
	jsr TSKwait

	lda endofraceflag
	bne ?endrace

	lda TSKxl,x	;save in temp area for possible reset by collision
	sta oldxl
	lda TSKxh,x
	sta oldxh
	lda TSKxm,x
	sta oldxm
	lda TSKlap,x
	sta oldlap
	lda TSKyl,x
	sta oldyl
	lda TSKyh,x
	sta oldyh

	jmp hdronelp

;END OF MAIN TASK LOOP-------------------------------------------------------------

negyspeed
	lda TSKyspeedl,x
	eor #$ff
	sta TSKyspeedl,x
	lda TSKyspeedh,x
	eor #$ff
	sta TSKyspeedh,x

	inc TSKyspeedl,x
	bne ?rts
	inc TSKyspeedh,x
?rts	rts


negxaccel
	lda TSKaccel,x
	eor #$ff
	sta TSKaccel,x
	inc TSKaccel,x
	rts


xmovedrone
	lda TSKaccel,x
	beq ?noaccel
	bmi ?testmin

	ldy mytask
	lda TSKxspeedh,y
	clc
	adc #0			;max speed (was 1)
	cmp TSKxspeedh,x
	bcs ?doaccel
	jmp ?noaccel

?testmin
	lda TSKxspeedh,x
	cmp #3			;(was 2)
	bcc ?noaccel

;	ldy mytask
;	lda TSKxspeedh,y	;min speed
;	sec
;	sbc #1
;	bpl ?pos
;	lda #0
;?pos	cmp TSKxspeedh,x
;	bcs ?noaccel

?doaccel
	ldy #$ff
	lda TSKaccel,x
	bmi ?decel
	ldy #0
?decel	sty tmp			;set sign of acceleration

	clc			;accelerate
	lda TSKxspeedl,x
	adc TSKaccel,x
	sta TSKxspeedl,x
	lda TSKxspeedh,x
	adc tmp
	sta TSKxspeedh,x

?noaccel
	sec			;subtract xspeed from x
	lda TSKxl,x
	sbc TSKxspeedl,x
	sta TSKxl,x
	lda TSKxh,x
	sbc TSKxspeedh,x
	sta TSKxh,x
	lda TSKxm,x
	sbc #0
	cmp trackwrap		;wrap track
	bne ?nowrap
	inc TSKlap,x
	lda #$ff
?nowrap	sta TSKxm,x
	rts

plxmove
	sec			;subtract xspeed from x
	lda TSKxl,x
	sbc TSKxspeedl,x
	sta TSKxl,x
	lda TSKxh,x
	sbc TSKxspeedh,x
	sta TSKxh,x
	lda TSKxm,x
	sbc #0
	cmp trackwrap		;wrap track
	bne ?nowrap
	inc TSKlap,x

	lda tires
	cmp #86			;maximum tire damage on gauge
	bcs ?tiresgone
	inc tires		;normal tire wear per lap

;update tire gauge
	lda tires
	lsr a
	tay
	lsr a
	lsr a
	clc
	adc #2			;left edge of gauge
	sta tmp			;x pos
	tya
	and #%00000011
	tay
	lda #26			;y pos
	sta tmp+1
	lda #0
	sta space
	lda bargauge,y
	jsr charout
?tiresgone


	lda #$ff
?nowrap
	cmp TSKxm,x
	sta TSKxm,x
	beq ?noinc
; $$$ display
	lda endofraceflag
	bne ?nocary		;dont inc money after race is over

	ldy place
	lda dollaramount,y
	clc
	adc dollarl
	sta dollarl
	cmp #100
	bcc ?nocary
	sec
	sbc #100
	sta dollarl
	inc dollarh
?nocary
	lda #125
	sta space
	lda #27
	sta tmp
	lda #23
	sta tmp+1
	lda dollarl
	jsr numout2		;display dollarl
	lda #24
	sta tmp
	lda #23
	sta tmp+1
	lda dollarh
	jsr numout		;display dollarh
?noinc
	rts
;place		     1 2 3 4 5 6 7 8 9 10
dollaramount	db 0,5,4,4,3,3,2,2,1,1,0,0	;money indexed by place

setscreenpos
;subtract scroll pos from x pos
	sec
	lda TSKxh,x
	sbc niscrollh
	sta PICxlo,x
	lda TSKxm,x
	sbc niscrollm
	cmp trackwrap1	;wrap track
	bne ?nowrap2
	lda #0
?nowrap2
	sta PICxhi,x
	lda TSKyh,x
	sta PICylo,x

;set priority for guard rail

	cmp #lane3top+9
	ldy TSKcarnum,x
	lda carcolor,y
	bcc ?notbottom		;carry was set by compare
	ora #32
?notbottom
	sta PICattr,x

;	lda #0
;	sta PICyhi,x
	rts


;=============================================================================

lcollision			;NEW LCOLLISION
				;return Carry if picture X overlaps Y

	lda TSKxh,x
	sec
	sbc TSKxh,y
	sta tmp
	lda TSKxm,x
	sbc TSKxm,y
	bpl ?pico1		;positive

	cmp #$ff
	bne ?picono		;distance > 256, no overlap
	lda tmp
	cmp #-13
	bcc ?collrts		;distance > 14, no overlap
	jmp ?ycoll

?pico1
	bne ?picono		;distance > 256, no overlap
	lda tmp
	cmp #14
	bcs ?picono		;distance > 14, no overlap
?ycoll
	lda TSKyh,x		;now do Y
	sec
	sbc TSKyh,y
	bpl ?pico2
	cmp #-7
	rts

?pico2
	cmp #8
	bcs ?picono		;distance > 16, no overlap

	sec			;they overlap
?collrts
	rts

?picono
	clc			;they do not overlap
	rts


;=============================================================================


spincar
	anim	10,car7
	anim	10,car8
	anim	10,car9
	anim	10,car10
	anim	10,car11
	anim	10,car12
	anim	10,car13
	anim	10,car3
	anim	10,car7
	anim	10,car8
	anim	10,car9
	anim	10,car10
	anim	10,car11
	anim	10,car12
	anim	10,car13
hdcarleft
	anim	250,car3
	animend	hdcarleft

spincar2
	anim	10,car13
	anim	10,car12
	anim	10,car11
	anim	10,car10
	anim	10,car9
	anim	10,car8
	anim	10,car7
	anim	10,car3
	anim	10,car13
	anim	10,car12
	anim	10,car11
	anim	10,car10
	anim	10,car9
	anim	10,car8
	anim	10,car7
hdcarleft2
	anim	250,car3
	animend	hdcarleft2

;=============================================================================

spincarm
	anim	10,car7m
	anim	10,car8m
	anim	10,car9m
	anim	10,car10m
	anim	10,car11m
	anim	10,car12m
	anim	10,car13m
	anim	10,car3m
	anim	10,car7m
	anim	10,car8m
	anim	10,car9m
	anim	10,car10m
	anim	10,car11m
	anim	10,car12m
	anim	10,car13m
hdcarleftm
	anim	250,car3m
	animend	hdcarleftm

spincar2m
	anim	10,car13m
	anim	10,car12m
	anim	10,car11m
	anim	10,car10m
	anim	10,car9m
	anim	10,car8m
	anim	10,car7m
	anim	10,car3m
	anim	10,car13m
	anim	10,car12m
	anim	10,car11m
	anim	10,car10m
	anim	10,car9m
	anim	10,car8m
	anim	10,car7m
hdcarleft2m
	anim	250,car3m
	animend	hdcarleft2m
;=============================================================================

spincard
	anim	10,car7d
	anim	10,car8d
	anim	10,car9d
	anim	10,car10d
	anim	10,car11d
	anim	10,car12d
	anim	10,car13d
	anim	10,car3d
	anim	10,car7d
	anim	10,car8d
	anim	10,car9d
	anim	10,car10d
	anim	10,car11d
	anim	10,car12d
	anim	10,car13d
hdcarleftd
	anim	250,car3d
	animend	hdcarleftd

spincar2d
	anim	10,car13d
	anim	10,car12d
	anim	10,car11d
	anim	10,car10d
	anim	10,car9d
	anim	10,car8d
	anim	10,car7d
	anim	10,car3d
	anim	10,car13d
	anim	10,car12d
	anim	10,car11d
	anim	10,car10d
	anim	10,car9d
	anim	10,car8d
	anim	10,car7d
hdcarleft2d
	anim	250,car3d
	animend	hdcarleft2d

;===========================================================================
; Debug procedure to show what is under a cursor
  if dbgcursor
cursor	equ $
	jsr PICaput
	dw curpic

	lda #0
	ldy #128
	jsr PICxyset

	jsr TSKsuspend

	lda PICxlo,x
	beq curs1			;disable if off left

	lda PICpick,x
	jsr numout

curs1	ldy #1
	jsr nijoyget

	lda #nileft
	bit nijoy
	beq cnolf
	jsr PICxdec
cnolf	lda #niright
	bit nijoy
	beq cnort
	jsr PICxinc
cnort	lda #niup
	bit nijoy
	beq cnoup
	jsr PICydec
cnoup	lda #nidown
	bit nijoy
	beq cnodn
	jsr PICyinc

; Keep on screen
cnodn	lda #0
	sta PICxhi,x
	sta PICyhi,x
	
	lda #0
	tay
	jsr PICpickSet
	rts

curpic
	anim	250,curpicp
	animend	curpic

curpicp	db 1, 1, 0, digit0		;"X"-32

  endif
;===========================================================================
	
;===========================================================================
; NumOut:  Output number in accumulator at x (tmp) y (tmp+1)
numout	equ $
;	sta tmp+2
;	lda vrambp
;	cmp #13
;	bcs ?rts	;don't do it if buffer is to full to output
;	lda tmp+2

	ldy #100
	jsr divy		;divide by y, returns in y
	sty numoutn+0

	ldy #10
	jsr divy
	sty numoutn+1

	clc
	adc #digit0
	sta numoutn+2

	lda numoutn+0
	clc
	adc #digit0
	sta numoutn+0

	lda numoutn+1
	clc
	adc #digit0
	sta numoutn+1

	lda #0
	sta numoutn+3
	sta PICvramflag

	ldy tmp+1			;the y coordinate
	lda tmp
	jsr PICcurSet			;set the cursor

	lda #<numoutn
	ldy #>numoutn
	jsr PICstring2

	lda #1
	sta PICvramflag
?rts
	rts

; Divide A by Y
divy	equ $
	sty tmp+2
	ldy #0
divyl	cmp tmp+2
	bcc divyx
	iny
	sec
	sbc tmp+2
	bcs divyl		;no underflow
divyx	rts


;===========================================================================
; NumOut:  Output number in accumulator at x (tmp) y (tmp+1)
numout2	equ $		;ONLY 2 DIGITS
;	sta tmp+2
;	lda vrambp
;	cmp #13
;	bcs ?rts	;don't do it if buffer is to full to output
;	lda tmp+2

;	ldy #100
;	jsr divy		;divide by y, returns in y
;	sty numoutn+0

	ldy #10
	jsr divy
	sty numoutn+0

	clc
	adc #digit0
	sta numoutn+1

	lda numoutn+0
	clc
	adc #digit0
	sta numoutn+0

;	lda numoutn+1
;	clc
;	adc #digit0
;	sta numoutn+1

	lda #0
	sta numoutn+2
	sta PICvramflag

	ldy tmp+1			;the y coordinate
	lda tmp
	jsr PICcurSet			;set the cursor

	lda #<numoutn
	ldy #>numoutn
	jsr PICstring2

	lda #1
	sta PICvramflag
?rts
	rts




	end

