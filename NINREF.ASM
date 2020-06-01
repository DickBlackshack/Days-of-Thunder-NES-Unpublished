; NINREF.ASM:  External references for NINSYS.ASM

;===========================================================================
;	PAGE0

	extern PAGE0 tmp			;4 bytes of temp storage
	extern PAGE0 nicr1SH			;shadow of control register 1
	extern PAGE0 nibnkchrSH		;shadow of character bank
	extern PAGE0 nibnksprSH		;shadow of sprite bank
	extern PAGE0 nijoy			;last read joystick value, debounced
	extern PAGE0 joy0			;last read joystick value, undebounced

	extern PAGE0 nisource
	extern PAGE0 nicount
	extern PAGE0 nidest	;generic arguments, all words

	extern PAGE0 nirunstate		;run length expansion vars

	extern PAGE0 niscrollh		;horizontal scroll value
	extern PAGE0 niscrollv		;vertical scroll value

	extern PAGE0 intflag			;tells background interupt has occured
	extern PAGE0 TSKcurrent		;currently executing task

; Tables
	extern PAGE0 PICxlo			;x position, low	lower left
	extern PAGE0 PICxhi			;x position, high
	extern PAGE0 PICylo			;y position, low
	extern PAGE0 PICyhi			;y position, high
;	extern PAGE0 PICz			;depth


	extern PAGE0 ninmi
	extern PAGE0 vrambp

	extern PAGE0 multiplier
	extern PAGE0 multiplicand
	extern PAGE0 multiresult

	extern PAGE0 oldintflag

	extern PAGE0 pich	;obe


;===========================================================================
;	DATA

	extern sprbuf			;sprite buffer; DMA'ed from here
	extern PICattr			;picture attribute
	extern PICpick			;character pick table
	extern PICpickLo, PICpickHi	;pick address

	extern TSKcardir		;cars direction bits like joystick

	extern TSKadrLo, TSKadrHi	;task address
	extern TSKflags			;task status
	extern TSKwaitLo		;task wait count

;===========================================================================
;	CODE

; Utilities
	extern nibnkchr			;select a character bank
	extern nicase			;case statement
	extern nijoyget			;read joystick Y
	extern nipicput			;put full screen picture to screen
					; A = low, Y = hi, video is turned off
	extern nirandom			;get random # between 0..FF
	extern niranrange		;get random # between 0..A-1

; NIRUN:  Run length expansion
; Call with the following variables set:
;  nirunsrc:  	pointer to run length encoded string
;  nirunstate:	zero if start of string
;  niruncount:  # of bytes to be expanded
;  nirundst:    run length destination.
;		IF = NIVRAMDATA, IS NOT INCREMENTED (direct screen output)
	extern nirun, nirunnew		;new does not require state init

	extern niscrclr			;clear screen
	extern niscrclr_any		;clear current screen
	extern nivaset			;set vram address
	extern nividoff			;video off
	extern nividon			;video on
	
;===========================================================================
; Palette primitives
	extern PALset			;set palette (takes effect next cycle)
;	db offset 0..1F, color, ..., color, $FF

; Picture primitives
	extern PICcurSet		;set vram write cursor to A,Y
	extern PICoverlap		;return Carry if picture X overlaps Y
	extern PICpickScan		;perform pick scanning (VBLANK only)
	extern PICpickSet		;set pick address based on currnt coords
	extern PICput			;associate picture address with a task
	extern PICaput			;associate picture address with a task
	extern PICput2			;picture address is in TMP
	extern PICstring		;output db x, y, asciz string
	extern PICstring2		;output string from addr A,Y
	extern PICvramPut		;put picture to VRAM buffer
	extern PICvramPut2		;(address is in tmp)
	extern PICxadd			;add to Xpos
	extern PICxdec			;decrement Xpos
	extern PICxflip			;set xflip attribute
	extern PICxinc			;increment Xpos
	extern PICxset			;set Xpos from A (low); hi = 0
	extern PICxset2			;set Xpos from Y (low) & A (high)
	extern PICxsub
	extern PICxyset			;set Xpos, Ypos from A, Y
	extern PICyadd
	extern PICyset			;set Ypos from A (low); hi = 0
	extern PICyset2			;set Ypos from Y (low) & A (high)
	extern PICydec			;decrement Ypos
	extern PICyinc			;increment Ypos
	extern PICysub
	extern picset
	extern PICanimlo
	extern PICanimhi

; Tasking primitives
	extern TSKcancel
	extern TSKhandler
	extern TSKinit
	extern TSKschedule		;address following call
	extern TSKschedule2		;address in TMP
	extern TSKsuspend
	extern TSKvblank		;install special vblank task
	extern TSKwait			;wait A ticks before resuming


	extern TSKhstreet
	extern TSKdroney
	extern TSKsecwait
	extern PAGE0 TSKxspeedl
	extern PAGE0 TSKxspeedh
	extern TSKyspeedl
	extern TSKyspeedh
	extern TSKytimer
	extern TSKxtimer
	extern TSKxl
	extern PAGE0 TSKxh
	extern PAGE0 TSKxm
	extern TSKyl
	extern PAGE0 TSKyh
	extern TSKaccel
	extern TSKcarnum
	extern PAGE0 TSKlap
;	extern PICxloo
;	extern PICyloo
	extern TSKflags2
	extern TSKskidding

	extern rasterspritey
	extern dashy

	END
