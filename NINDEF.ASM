; NINDEF.ASM:  System Definitions for NINSYS.ASM interface

; 2500 AD Assembler directives
	spaces on		;Enables spaces between operands
	chip 6502
;	longa off
;	longi off

nicols	equ 32			;screen width
nirows	equ 30			;screen height

; PPU REGISTERS
nicr0		equ $2000	;control register 0 (write only)
nicr1		equ $2001	;control register 1 (write only)
nistatus	equ $2002	;status register (read only)
nioamaddr	equ $2003	;OAM address register (write only; auto inc)
				; MAINTAIN 00 (?)

;;nioamdata	equ $2004	;OAM data register (write only)
				;USE DMA INSTEAD

niscroll	equ $2005	;scroll register (write only twice: H & V)
nivramaddr	equ $2006	;vram address register 
				; (write only twice: Hi & Lo)
nivramdata	equ $2007	;vram data register (R/W:  auto-increments)

; Note:  if scroll or VRAM addr is changed, must reinitialize the other

; Bit fields for PPU registers
; Control register 0
nimsbh		equ $01		;msb of hscroll offset
nimsbv		equ $02		;msb of vscroll offset
niincm		equ $04		;vram auto inc mode: 0=+1, 1=+32
niobjseg	equ $08		;obj chr area:  [0]=0000-0FFF;  1 =1000-1FFF
nibgseg		equ $10		;bkg chr area:   0 =0000-0FFF; [1]=1000-1FFF
ni8x16		equ $20		;character size:  0=8x8; 1=8x16
nislave		equ $40		;master/slave: ALWAYS SET 0=master
niinton		equ $80		;interrupt: 0=disable; 1=enable

; Note: when in 8x16 mode, OBJSEG has no effect. 
; Even OBJ #s come from first bank; odd come from second bank

; Control register 1
nimono		equ $01		;0=color; 1=monochrome
nibglblk	equ $02		;bkg left side blanking:  0=blanking
niobjlblk	equ $04		;obj left side blanking:  0=blanking
nibgblk		equ $08		;bkg blanking: 0=blanking
niobjblk	equ $10		;obj blanking: 0=blanking
nibkred		equ $20		;background color 1=red
nibkgreen	equ $40		;1=green
nibkblue	equ $80		;1=blue

; Status Register
nistrike	equ $40		;coincidence flag
niint		equ $80		;interrupt flag 

; VRAM Address space
niobj		equ $0000
nibg		equ $1000
niscreen0	equ $2000
niscreen1	equ $2400
niscreen3	equ $2c00
niscreen2	equ $2800

; COLOR GENERATOR RAM
; Is at 3F00h..3F1Fh in VRAM address space
; Can only be written during vertical blank
; Contains a 6 bit quantity:
;  2-bit-level 4-bit-color
; 52 colors are available

nipal	equ $3F00			;palette address
 
;;niclev0	equ $00			;lowest level intensity (black)
;;niclev1	equ $10
;;niclev2	equ $20
;;niclev3	equ $30			;highest intensity (white)

; Color definitions.  
; Odd colors are also valid, but do not know what color they are
; DO NOT USE  D, E, 1D, 1E, 1F, 2D, 2E, 2F

niblack		equ $0F			;was 0

nigreydk	equ 0			;was $10

;;nigrey		equ $20		;is almost white
nigrey		equ $3D
niwhite		equ $30

nibluedk	equ $10+2
niblue		equ $20+2
nibluelt	equ $30+2

nimagenta	equ $20+4

nireddk		equ $10+6
nired		equ $20+6

niorange	equ $30+6		;peach; skin color

niyellow	equ $30+8

nigreendk	equ $10+10
nigreen		equ $20+10

nicyan		equ $20+12		;highest colors


; SOUND

; SOUND
nidutyA		equ $4000	;duty, continuous/length, amplitude gain/envelope
nisweepA	equ $4001	;sweep
nifreqlA	equ $4002	;sound A frequency low
nifreqhA	equ $4003	;length counter 'start', freq hi 3 bits
nidutyB		equ $4004	;duty, continuous/length, amplitude gain/envelope
nisweepB	equ $4005	;sweep
nifreqlB	equ $4006	;sound A frequency low
nifreqhB	equ $4007	;length counter 'start', frequency hi 3 bits
nienvC		equ $4008 	;continuous/length, envelope  data
nifreqlC	equ $400A	;sound C frequency low
nifreqhC	equ $400B	;length data, freq hi 3 bits
nidutyD		equ $400C	;continuous/length, amplitude/envelope for D
nifreqD		equ $400E	;sample clock frequency
nilengthD	equ $400F	;length counter; start

niwre0		equ $4010	;bit 7 = sound DMA IRQ enable (hi)
nideltdata	equ $4011
nideltaddr	equ $4012
nideltcntr	equ $4013

niwrf0		equ $4014	;object dma page.  Write here at start of NMI
				;to transfer OAM (sprite) buffer to hardware

niwrst		equ $4015	;sound A, B enable/length flag

niporta		equ $4016	;hand controller port A
niportb		equ $4017	;portP

; Input port bit defintions
niright		equ $01		;right
nileft		equ $02		;left
nidown		equ $04		;down
niup		equ $08		;up
nistart		equ $10		;start
niselect	equ $20		;menu
nibutB		equ $40		;button B
nibutA		equ $80		;button A


; MMC1 REGISTERS
mmc1r0		equ $9FFF	;mmc3 control register 0
mmc1r1		equ $BFFF	;mmc3 control register 1
mmc1r2		equ $DFFF	;mmc3 control register 2
mmc1r3		equ $FFFF	;mmc3 control register 3

; Bit fields for MMC1 registers
; Control register 0
mmc1chrbank4k	equ %00010000	;allow sprites and characters separate banking
mmc1pgmbank16k	equ %00001000	;allow 16K byte banking of program
mmc1pgmbankhigh	equ %00000100	;banks 16K byte of program in at $C000
mmc1_4screens	equ %00000010	;allow 2 screens
mmc1vscrolling	equ %00000001	;sets vertical scrolling


; SPRITES
; Offsets within sprite record
niobjsz	equ 4			;# bytes in record
niobjy	equ 0			;y position
niobjc	equ 1			;character
niobja	equ 2			;attribute
niobjx	equ 3			;x position

; Bit fields within attribute
niobjvflip	equ $80
niobjhflip	equ $40
niobjprior	equ $20
niobjcolor	equ $03		;low 2 bits = color code

; Picture record
PICwidth	equ 0			;in 8 x 8 units
PICheight	equ 1
PICcolor	equ 2			;area color code 0..3
PICdata		equ 3			;width x height character codes follow

TSKmax		equ 15	;was 24 obe	;max # tasks - 1



;  flags2 definitons
TSKcolide	equ $80			;set if task should be tested for
					;collision and scrolled with background
TSKbhit		equ $40			;set by bulit when hit

;************************

name	equ	$7f1		;players name ram


	end
