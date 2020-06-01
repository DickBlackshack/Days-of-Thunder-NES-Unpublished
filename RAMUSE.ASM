
	LINKLIST

	DATA

;data for PB

	GLOBALS ON

niscrolll	ds 1
niscrollm	ds 1
tach		ds 1
plstpos		ds 1		;players starting position
laptimeh	ds 1
laptimel	ds 1
oldxl		ds 1		;saved xy for collision restore
oldxh		ds 1		;saved xy for collision restore
oldxm		ds 1		;saved xy for collision restore
oldyl		ds 1		;saved xy for collision restore
oldyh		ds 1		;saved xy for collision restore
oldlap		ds 1		;saved xy for collision restore
turn		ds 2		;for crash routine to set yspeed for straight
onebytexspeed	ds 1		;calculated by steer used by speedometer and tach
place		ds 1		;players car position in race 1-10
tires		ds 1		;tire condition
body		ds 1		;body condition
dollarl		ds 1		;dollars inced by place during race
dollarh		ds 1		;dollars inced by place during race
tdollarl	ds 1		;total dollars
tdollarh	ds 1		;total dollars
damchange	ds 1		;change in damage gauge
digmotocnt	ds 1		;digtal motor sound counter
endofraceflag	ds 1		;tasks do nothing if non-zero
race		ds 1		;race number
droneskill	ds 9		;how well drones track players position
gas		ds 1
mytask		ds 1		;players task number
speedometertask	ds 1		;task number
motosndtiretask	ds 1		;task number
bodytask	ds 1
finish		ds 14		;race finishing position stats
earnl		ds 14		;earnings per race
earnh		ds 14		;earnings per race
car		ds 1		;which of the three cars is being used
				;also used to access geartbls
cardamage	ds 3		;damage condition of the three cars
trackwrap	ds 1
trackwrap1	ds 1
trackwrap2	ds 1
trackwrap3	ds 1
pauseflag	ds 1		;non zero = paused
starttask	ds 1		;the start tasks task id
meloflag	ds 1		;non zero = use melo yellow car

Lbuf		ds 64			;VRAM write buffer, 32 horizontal, 30 vertical

;indexed by yourlane
tsknums	ds 9	;for collision detect

numoutn	ds 4

	PAGE0
trackadr	ds 2
	DATA

	GLOBALS OFF










;---
; data for MAPSTUFF.ASM
;---
last_sh	ds	1			;last value of niscrollh
lane1y	ds	32			;32 slices: y values for top of lane 1
lane2y	ds	32			;32 slices: y values for top of lane 2
lane3y	ds	32			;32 slices: y values for top of lane 3
lane4y	ds	32			;32 slices: y values for top of lane 4
	public	last_sh
	public	lane1y
	public	lane2y
	public	lane3y
	public	lane4y

sv_niscrollm	ds	1
sv_niscrollh	ds	1
color_niscrollm	ds	1
color_niscrollh	ds	1
nicr0SH		ds	1		;PPU control register 0 shadow
	public	sv_niscrollh
	public	sv_niscrollm
	public	color_niscrollm
	public	color_niscrollh
	public	nicr0SH

;---
; data for TOPVIEW.ASM
;---
debcnt		ds	1		;debounce counter
sv_niwrst	ds	1		;sound channel enable bits
tv_sv_niscrollm	ds	1		;save sv_niscrollm
tv_sv_niscrollh	ds	1		;save sv_niscrollh
tv_niscrollm	ds	1		;save niscrollm
tv_niscrollh	ds	1		;save niscrollh
VRAMbase	ds	2		;screen base address
track_vector	ds	3		;indirect jump for track routines
track		ds	1		;track number
	public	debcnt
	public	sv_niwrst
	public	tv_sv_niscrollm
	public	tv_sv_niscrollh
	public	tv_niscrollm
	public	tv_niscrollh
	public	VRAMbase
	public	track_vector
	public	track

;---
; data for TITLE.ASM
;---
xpos		ds	1		;cursor postion/scroll position
ypos		ds	1		;cursor position
xspeedl		ds	1		;screech in
xspeedh		ds	1		;screech in
startdown	ds	1		;start button was pressed
ycount		ds	1		;used by holdlogo routine
	public	xpos
	public	ypos
	public	xspeedl
	public	xspeedh
	public	startdown
	public	ycount

;---
; data for PERSON.ASM
;---
frame	ds	1			;current frame number
flindex	ds	1			;frame list index
fline	ds	4
	public	fline
	public	frame
	public	flindex








;---
; zero page data for MAPSTUFF.ASM
;---
	PAGE0
maptmp	ds	2
maptmp2	ds	2
	public	maptmp
	public	maptmp2

;---
; zero page data for MAPSTUFF.ASM
;---
tvtmp	ds	2			;pointer for topview routines
	public	tvtmp

;---
; zero page data for TITLE.ASM
;---
sndspd	ds	1			;frequency
sndvol	ds	1			;amplitude
	public	sndspd
	public	sndvol


;---
; zero page data for PERSON.ASM
;---
frmptr	ds	2			;frame list pointer
	public	frmptr







;OBE'S music driver ram

	DATA

	globals on

;CHANNEL 0 SQUARE
wave0	ds 1;wave shape	            0-3
envr0	ds 1;envelope repeat        0=off 1=on
decay0	ds 1;decay                  1=off 0=on
decayr0	ds 1;if decay on decay rate 0-f
	    ;if decay off volume    0-f
sweep0	ds 1;freq sweep             0=off 1=on
swedir0	ds 1;sweep direction        0=down 1=up
sweepr0	ds 1;sweep rate             0-7
sweeps0	ds 1;sweep speed            0-7
freqlo0	ds 1;frequency low          0-ff
freqhi0	ds 1;frequency high         0-7
envdur0	ds 1;envelope duration      0-18

;CHANNEL 1 SQUARE
wave1	ds 1;wave shape	            0-3
envr1	ds 1;envelope repeat        0=off 1=on
decay1	ds 1;decay                  1=off 0=on
decayr1	ds 1;if decay on decay rate 0-f
	    ;if decay off volume    0-f
sweep1	ds 1;freq sweep             0=off 1=on
swedir1	ds 1;sweep direction        0=down 1=up
sweepr1	ds 1;sweep rate             0-7
sweeps1	ds 1;sweep speed            0-7
freqlo1	ds 1;frequency low          0-ff
freqhi1	ds 1;frequency high         0-7
envdur1	ds 1;envelope duration      0-18

;CHANNEL 2 TRIANGLE
envr2	ds 1;envelope or constant   0=env 1=con
freqlo2	ds 1;frequency low          0-ff
freqhi2	ds 1;frequency high         0-7
envdur2	ds 1;envelope duration      0-18

;CHANNEL 3 NOISE
ntype3	ds 1;noise type	            0-1
envr3	ds 1;envelope repeat        0=off 1=on
decay3	ds 1;decay                  1=off 0=on
decayr3	ds 1;if decay on decay rate 0-f
	    ;if decay off volume    0-f
mfreq3	ds 1;max frequency          0-f
envdur3	ds 1;envelope duration      0-18



rptcnt	ds	4

savey0	ds	1
savey1	ds	1
savey2	ds	1
savey3	ds	1

twaits0	ds	1
twaits1	ds	1
twaits2	ds	1
twaits3	ds	1


	PAGE0
; SELECTED SONGS TRACK ADDRESS

tracka	ds	2
dracka	ds	2

trackb	ds	2
drackb	ds	2

trackc	ds	2
drackc	ds	2

trackd	ds	2
drackd	ds	2

saved_nibnkchr	ds	1
saved_nibnkspr	ds	1




;	DATA
;
;	ORG	$07f1
;
;name		ds 15		;players name
;

	globals off


	end
