;---
; topview.asm - Goodyear blimp view routines
;---

	LINKLIST

	include nindef.asm
	include ninref.asm

	CODE

;---
; external subroutines
;---
	extern	buffer_slice		;in MAPSTUFF.ASM
	extern	dashwords		;in MAPSTUFF.ASM
	extern	do_sprite_DMA		;in ROUTINES.ASM
	extern	hide_sprites		;in ROUTINES.ASM
	extern	setVRAMaddr		;in ROUTINES.ASM
	extern	sliceout		;in MAPSTUFF.ASM
	extern	snd_disable		;in ROUTINES.ASM
	extern	snd_enable		;in ROUTINES.ASM
	extern	umul8x8			;in NINSYSC.ASM
	extern	wait_for_start		;in ROUTINES.ASM
	extern	waitvb			;in ROUTINES.ASM
	extern	write_x_lines		;in ROUTINES.ASM


;---
; SHOW_TOPVIEW - display the top view of the track
;---
	PUBLIC	show_topview
show_topview
	rts

;---
; WRITE_TOPVIEW - write the topview map into screen 1
;---
write_topview:
	public	write_topview
	lda	#<niscreen0		;set working screen
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;

	ldx	#0			;clear screen 0
	ldy	#0			;
	jsr	setVRAMaddr		;
	jsr	niscrclr_any		;

	ldx	track			;dispatch a track routine
	lda	tveclo,x		;
	sta	track_vector		;
	lda	tvechi,x		;
	sta	track_vector+1		;
	jsr	track_jmp		;

	ldx	track			;calculate offset of track name in table
	stx	multiplier		;
	ldx	#27			;
	stx	multiplicand		;
	jsr	umul8x8			;
	
	lda	#<track_names		;calculate address of track name
	clc				;
	adc	multiresult		;
	sta	tvtmp			;
	lda	#>track_names		;
	adc	multiresult+1		;
	sta	tvtmp+1			;

	lda	#0			;write 3 blank spaces to the screen
	sta	nivramdata		;
	sta	nivramdata		;
	sta	nivramdata		;

	ldy	#0			;write the track name to the screen
?10	lda	(tvtmp),y		;
	sta	nivramdata		;
	iny				;
	cpy	#27			;
	bne	?10			;
	
	jsr	settvpal		;set topview palette

	ldx	#8			;set color memory for race stats
	ldy	#31			;
	jsr	setVRAMaddr		;
	lda	#$55			;
	ldx	15			;
?20	sta	nivramdata		;
	dex				;
	bne	?20			;
	lda	#05			;
	ldx	#8			;
?30	sta	nivramdata		;
	dex				;
	bne	?30			;
	
	rts
track_jmp	jmp	(track_vector)

;---
; WRITE_ATLANTA - write the Atlanta track
;---
write_atlanta:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_ovalbot		;output bottom of the oval
	rts

;---
; WRITE_BRISTOL - write the Bristol track
;---
write_bristol:
	jsr	write_narotop		;output top of the narrow oval
	jsr	write_ovalbot		;output bottom of the narrow oval
	rts

;---
; WRITE_CHARLOTTE - write Charlotte track
;---
write_charlotte:
	jsr	write_ovaltop		;output top of the oval
	lda	#<charbot		;prime the source pointer
	sta	tvtmp			;
	lda	#>charbot		;
	sta	tvtmp+1			;
	ldx	#7			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_DARLINGTON - write the Darlington track
;---
write_darlington:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_ovalbot		;output bottom of the oval
	rts

;---
; WRITE_DAYTONA - write Daytona track
;---
write_daytona:
	jsr	write_ovaltop		;output top of the oval
	lda	#<daybot		;prime the source pointer
	sta	tvtmp			;
	lda	#>daybot		;
	sta	tvtmp+1			;
	ldx	#8			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_DOVER - write the Dover Downs track
;---
write_dover:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_ovalbot		;output bottom of the oval
	rts

;---
; WRITE_MARTINSVILLE - write the Martinsville Speedway track
;---
write_martinsville:
	jsr	write_narotop		;output top of the narrow oval
	jsr	write_ovalbot		;output bottom of the narrow oval
	rts

;---
; WRITE_MICHIGAN - write Michigan International Speedway track
;---
write_michigan:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_rondbot		;output bottom of round track
	rts

;---
; WRITE_NORTHCAR - write North Carolina Motor Speedway track
;---
write_northcar:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_flatbot		;output bottom of flattened kidney track
	rts

;---
; WRITE_NORTHWILK - write North Wilkesboro Speedway track
;---
write_northwilk:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_ovalbot		;output bottom of the oval track
	rts

;---
; WRITE_PHOENIX - write Phoenix International Speedway track
;---
write_phoenix:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_phoebot		;output bottom of Phoenix track
	rts

;---
; WRITE_POCONO - write all of Pocono International Raceway
;---
write_pocono:
	ldx	#0			;show oval top start on line 4
	ldy	#2			;
	jsr	setVRAMaddr		;
	lda	#<pocono		;prime the source pointer
	sta	tvtmp			;
	lda	#>pocono		;
	sta	tvtmp+1			;
	ldx	#17			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_RICHMOND - write Richmond International Raceway track
;---
write_richmond:
	jsr	write_ovaltop		;output top of the oval
	jsr	write_rondbot		;output bottom of round track
	rts

;---
; WRITE_TALLADEGA - write Talladega track
;---
write_talladega:
	jsr	write_ovaltop		;output top of the oval
	lda	#<daybot		;prime the source pointer
	sta	tvtmp			;
	lda	#>daybot		;
	sta	tvtmp+1			;
	ldx	#8			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_OVALTOP - write the top of the oval track to the screen
;---
write_ovaltop:
	ldx	#0			;show oval top start on line 4
	ldy	#2			;
	jsr	setVRAMaddr		;
	lda	#<ovaltop		;prime the source pointer
	sta	tvtmp			;
	lda	#>ovaltop		;
	sta	tvtmp+1			;
	ldx	#6			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_OVALBOT - write the bottom of the oval track to the screen
;---
write_ovalbot:
	lda	#<ovalbot		;prime the source pointer
	sta	tvtmp			;
	lda	#>ovalbot		;
	sta	tvtmp+1			;
	ldx	#5			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_NAROTOP - write the top of the narrow track to the screen
;---
write_narotop:
	ldx	#0			;show oval top start on line 4
	ldy	#2			;
	jsr	setVRAMaddr		;
	lda	#<ovaltop		;prime the source pointer
	sta	tvtmp			;
	lda	#>ovaltop		;
	sta	tvtmp+1			;
	ldx	#5			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_RONDBOT - write round bottom for Michigan et al
;---
write_rondbot:
	lda	#<rondbot		;prime the source pointer
	sta	tvtmp			;
	lda	#>rondbot		;
	sta	tvtmp+1			;
	ldx	#7			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_FLATBOT - write flattened kidney bottom for North Carolina et al
;---
write_flatbot:
	lda	#<flatbot		;prime the source pointer
	sta	tvtmp			;
	lda	#>flatbot		;
	sta	tvtmp+1			;
	ldx	#6			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; WRITE_PHOEBOT - write Phoenix track bottom
;---
write_phoebot:
	lda	#<phoebot		;prime the source pointer
	sta	tvtmp			;
	lda	#>phoebot		;
	sta	tvtmp+1			;
	ldx	#7			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; DOTS_ALL - for the car sprites
;---
dots_all
	rts

;---
; SCREEN1 - write one copy of current screen to VRAM (interrupts must be off)
;---
screen1
	public	screen1
	jsr	buffer_slice
	jsr	sliceout
	lda	niscrollh
	sec
	sbc	#8
	sta	niscrollh
	cmp	#$ff
	bne	screen1
	rts

;---
; MAKE_TRACK - rebuild screen 0 and 1 with current screen number & previous
;---
make_track:
	public	make_track
	lda	niscrollm		;save for buffer_slice & sliceout
	sta	tv_niscrollm		;
	lda	niscrollh		;
	sta	tv_niscrollh		;
	lda	sv_niscrollm		;
	sta	tv_sv_niscrollm		;
	lda	sv_niscrollh		;
	sta	tv_sv_niscrollh		;

	jsr	setgmpal		;reset the game's palette
	lda	#$ff
	sta	niscrollh

	lda	tv_sv_niscrollm		;do this screen second
	pha				;

	sta	niscrollm		;assume not at trackwrap
	inc	niscrollm		;
	bne	?1			;not at trackwrap
	lda	trackwrap1		;trackwrap+1
	sta	niscrollm

?1:	jsr	screen1			;make the current screen

	pla				;set current screen number
	sta	niscrollm		;
	lda	#$ff
	sta	niscrollh
	jsr	screen1			;make the previous screen

	jsr	dashwords		;put out coincidence lines & headings
	jsr	newdash

	lda	#0			;reset scroll and address registers
	sta	nivramaddr		;
	sta	nivramaddr		;
	sta	niscroll		;
	sta	niscroll		;

	lda	tv_niscrollm		;restore for buffer_slice & sliceout var
	sta	niscrollm		;
	lda	tv_niscrollh		;
	sta	niscrollh		;
	lda	tv_sv_niscrollm		;
	sta	sv_niscrollm		;
	lda	tv_sv_niscrollh		;
	sta	sv_niscrollh		;

	rts

;---
; ON_WAIT_OFF - debugging: turn video on, wait for start button, video off
;---
on_wait_off:
	lda	#nibgblk+niobjblk	;video on
	sta	nicr1			;

	jsr	wait_for_start		;button to be pressed

	lda	#0			;video off
	sta	nicr1			;BLANK IMMEDIATELY!

	rts

;---
; SETGMPAL - set the game palette
;---
setgmpal
	lda	#>nipal			;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;

	lda	#<gmpal			;set palette game palette
	sta	tvtmp			;
	lda	#>gmpal			;
	sta	tvtmp+1			;
	ldx	#1			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; SETTVPAL - set the topview palette
;---
settvpal
	lda	#>nipal			;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;

	lda	#<tvpal			;set palette game palette
	sta	tvtmp			;
	lda	#>tvpal			;
	sta	tvtmp+1			;
	ldx	#1			;number of lines to move
	jsr	write_x_lines		;
	rts

;---
; NEWDASH - put out new track dashboard
;---
newdash:
	public	newdash
	lda	#<niscreen0		;set working screen
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;

	ldx	#0			;set cursor
	ldy	#20			;
	jsr	setVRAMaddr		;

	lda	#<tdash_map		;map data and color bytes
	sta	tvtmp			;
	lda	#>tdash_map		;
	sta	tvtmp+1			;
	ldx	#12			;number of lines to move
	jsr	write_x_lines		;

	rts

;---
; track vectors
;---
tveclo:
	db	<write_daytona
	db	<write_richmond
	db	<write_northcar
	db	<write_atlanta
	db	<write_darlington		;TBD #2
	db	<write_bristol			;TBD #1
	db	<write_northwilk
	db	<write_martinsville		;TBD #3
	db	<write_talladega
	db	<write_charlotte
	db	<write_dover
	db	<write_pocono
	db	<write_michigan
	db	<write_phoenix

tvechi:
	db	>write_daytona
	db	>write_richmond
	db	>write_northcar
	db	>write_atlanta
	db	>write_darlington		;TBD #2
	db	>write_bristol			;TBD #1
	db	>write_northwilk
	db	>write_martinsville		;TBD #3
	db	>write_talladega
	db	>write_charlotte
	db	>write_dover
	db	>write_pocono
	db	>write_michigan
	db	>write_phoenix
	
maxtracks	equ	tvechi-tveclo
	
;---
; ovaltop - common part: the top part of an oval; top of Daytona, et al
;---
ovaltop	db	000h,000h,000h,000h,000h,000h,001h,002h	;1st row
	db	003h,003h,003h,003h,003h,003h,003h,003h
	db	003h,003h,003h,003h,003h,003h,003h,003h
	db	003h,004h,005h,000h,000h,000h,000h,000h

	db	000h,000h,000h,000h,006h,007h,008h,009h	;2nd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,00Ah,00Bh,00Ch,00Dh,000h,000h,000h

	db	000h,000h,000h,00Eh,00Fh,010h,000h,000h	;3rd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,011h,012h,013h,000h,000h

	db	000h,000h,000h,014h,015h,000h,000h,000h	;4th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,016h,017h,000h,000h

	db	000h,000h,000h,018h,000h,000h,000h,000h	;5th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,019h,000h,000h

	db	000h,000h,000h,01Ah,000h,000h,000h,000h	;6th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,01Bh,000h,000h

;---
; OVALBOT - oval bottom for Atlanta, Darlington, Dover Downs, North Wilkesboro
;---
ovalbot	db	000h,000h,000h,03Dh,000h,000h,000h,000h	;1st row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,03Eh,000h,000h

	db	000h,000h,000h,03Fh,00Dh,000h,000h,000h	;2nd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,006h,040h,000h,000h

	db	000h,000h,000h,041h,042h,043h,000h,000h	;3rd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,044h,045h,046h,000h,000h

	db	000h,000h,000h,000h,047h,048h,049h,04Ah	;4th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,04Bh,04Ch,04Dh,04Eh,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,04Fh,050h	;5th row
	db	051h,038h,038h,038h,038h,038h,038h,038h
	db	038h,038h,038h,038h,038h,038h,038h,038h
	db	052h,053h,054h,000h,000h,000h,000h,000h

;---
; CHARBOT - bottom 7 rows for Charlotte Motor Speedway
;---
charbot	db	000h,000h,000h,055h,000h,000h,000h,000h	;1st row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,056h,000h,000h

	db	000h,000h,000h,057h,058h,000h,000h,000h	;2nd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,059h,05Ah,000h,000h

	db	000h,000h,000h,000h,05Bh,05Ch,000h,000h	;3rd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,05Dh,05Eh,000h,000h,000h

	db	000h,000h,000h,000h,000h,05Fh,060h,061h	;4th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,062h,063h,064h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,065h	;5th row
	db	066h,067h,068h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,069h,06Ah
	db	06Bh,06Ch,000h,000h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,000h	;6th  row
	db	000h,06Dh,06Eh,06Fh,070h,000h,000h,000h
	db	000h,000h,000h,000h,071h,072h,073h,074h
	db	000h,000h,000h,000h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,000h	;7th row
	db	000h,000h,000h,000h,065h,075h,038h,038h
	db	038h,038h,038h,076h,06Ch,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h

;---
; DAYBOT - track bottom for Daytona/Talladega (8 rows)
;---
daybot	db	000h,000h,000h,01Ch,000h,000h,000h,000h	;1st row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,01Dh,000h,000h

	db	000h,000h,000h,01Eh,01Fh,000h,000h,000h	;2nd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,020h,021h,000h,000h

	db	000h,000h,000h,011h,012h,00Dh,000h,000h	;3rd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,006h,00Fh,010h,000h,000h

	db	000h,000h,000h,000h,011h,022h,023h,024h	;4th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,025h,026h,027h,010h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,028h,029h	;5th row
	db	023h,024h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,025h
	db	026h,02Ah,02Bh,000h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,000h	;6th row
	db	028h,029h,023h,024h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,025h,026h,02Ah
	db	02Bh,000h,000h,000h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,000h	;7th row
	db	000h,000h,028h,02Ch,02Dh,02Eh,02Fh,000h
	db	000h,000h,030h,031h,032h,033h,02Bh,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,000h	;8th row
	db	000h,000h,000h,000h,034h,035h,036h,037h
	db	038h,039h,03Ah,03Bh,03Ch,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h

;---
; RONDBOT - bottom 7 rows round bottom  (e.g.: Michigan International Speedway)
;---
rondbot	db	000h,000h,000h,0B2h,000h,000h,000h,000h	;1st row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,0B3h,000h,000h

	db	000h,000h,000h,0B4h,043h,000h,000h,000h	;2nd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,044h,0B5h,000h,000h

	db	000h,000h,000h,047h,0B6h,043h,000h,000h	;3rd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,044h,0B7h,04Eh,000h,000h

	db	000h,000h,000h,000h,0B8h,0B9h,0BAh,000h	;4th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,0BBh,0BCh,0BDh,000h,000h,000h

	db	000h,000h,000h,000h,000h,088h,0BEh,0BFh	;5th row
	db	0C0h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	0C1h,0C2h,0C3h,0C4h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,088h	;6th row
	db	0C5h,0C6h,0C7h,0C8h,0C9h,0CAh,000h,000h
	db	000h,000h,000h,0CBh,0CCh,0CDh,0CEh,0CFh
	db	0D0h,0C4h,000h,000h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,000h	;7th row
	db	000h,000h,000h,0D1h,0D2h,0D3h,0D4h,038h
	db	038h,038h,0D5h,0D6h,0D7h,0D8h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h

;---
; FLATBOT - bottom of flattened kidney track for North Carolina Motor Speedway
;---
flatbot	db	000h,000h,000h,0B2h,000h,000h,000h,000h	;1st row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,0B3h,000h,000h

	db	000h,000h,000h,0B4h,043h,000h,000h,000h	;2nd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,044h,0B5h,000h,000h

	db	000h,000h,000h,047h,0B6h,043h,000h,000h	;3rd row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,044h,0B7h,04Eh,000h,000h

	db	000h,000h,000h,000h,0B8h,0B9h,0BAh,000h	;4th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,0BBh,0BCh,0BDh,000h,000h,000h

	db	000h,000h,000h,000h,000h,088h,0BEh,0BFh	;5th row
	db	0C0h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	0C1h,0C2h,0C3h,0C4h,000h,000h,000h,000h

	db	000h,000h,000h,000h,000h,000h,000h,088h	;6th row
	db	0C5h,0D4h,038h,038h,038h,038h,038h,038h
	db	038h,038h,038h,038h,038h,038h,038h,0D5h
	db	0D0h,0C4h,000h,000h,000h,000h,000h,000h

;---
; PHOEBOT - bottom of Phoenix track
;---
phoebot	db	000h,000h,000h,0B2h,000h,000h,000h,000h	;1
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,0B3h,000h,000h
	db	000h,000h,000h,0B4h,043h,000h,000h,000h	;2
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,044h,0B5h,000h,000h
	db	000h,000h,000h,041h,042h,068h,000h,000h	;3
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,044h,0B7h,04Eh,000h,000h
	db	000h,000h,000h,000h,06Dh,06Eh,06Fh,070h	;4
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,0BBh,0BCh,0BDh,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,065h	;5
	db	066h,067h,068h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	0C1h,0C2h,0C3h,0C4h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h	;6
	db	000h,06Dh,06Eh,06Fh,070h,000h,000h,000h
	db	000h,000h,000h,0CBh,0CCh,0CDh,0CEh,0CFh
	db	0D0h,0C4h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h	;7
	db	000h,000h,000h,000h,065h,037h,038h,038h
	db	038h,038h,0D5h,0D6h,0D7h,0D8h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h

;---
; POCONO - data for topview of Pocono International Raceway
;---
pocono	db	000h,000h,000h,000h,000h,000h,000h,000h	;1st row
	db	000h,000h,044h,077h,078h,079h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h	;2nd row
	db	000h,07Ah,07Bh,07Ch,07Dh,07Eh,07Fh,080h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h	;3rd row
	db	081h,082h,000h,000h,000h,000h,000h,083h
	db	084h,085h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,086h	;4th row
	db	087h,000h,000h,000h,000h,000h,000h,000h
	db	088h,089h,08Ah,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,044h,08Bh	;5th row
	db	08Ch,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,06Dh,08Dh,08Eh,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,08Fh,090h	;6th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,091h,092h,068h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,093h,094h,000h	;7th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,095h,096h,097h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,098h,099h,000h,000h	;8th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,09Ah
	db	09Bh,09Ch,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,00Eh,09Dh,000h,000h,000h	;9th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,09Eh,09Fh,024h,000h,000h,000h,000h
	db	000h,000h,000h,0A0h,0A1h,000h,000h,000h	;10th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,0A2h,0A3h,0A4h,000h,000h,000h
	db	000h,000h,000h,0A5h,000h,000h,000h,000h	;11th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,0A6h,0A7h,000h,000h
	db	000h,000h,000h,0A8h,000h,000h,000h,000h	;12th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,0A9h,000h,000h
	db	000h,000h,000h,03Dh,000h,000h,000h,000h	;13th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,0AAh,000h,000h
	db	000h,000h,000h,03Fh,00Dh,000h,000h,000h	;14th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,0ABh,000h,000h
	db	000h,000h,000h,041h,042h,043h,000h,000h	;15th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,0ACh,000h,000h
	db	000h,000h,000h,000h,047h,048h,049h,04Ah	;16th row
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,044h,0AEh,0AFh,000h,000h
	db	000h,000h,000h,000h,000h,000h,04Fh,050h	;17th row
	db	038h,038h,038h,038h,038h,038h,038h,038h
	db	038h,038h,038h,038h,038h,038h,038h,038h
	db	038h,038h,038h,0B0h,0B1h,000h,000h,000h

;---
; TRACK_NAMES - ordered by track number
;---
track_names:
	db	0DCh,0D9h,0F1h,0ECh,0E7h,0E6h,0D9h,000h	;track  9 Daytona
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,0F4h
	db	0FCh,0F7h,000h,0E5h,0E1h,0E4h,0DDh
	db	0EAh,0E1h,0DBh,0E0h,0E5h,0E7h,0E6h,0DCh	;track 12 Richmond
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,0FCh,0F9h
	db	0F4h,0F7h,000h,0E5h,0E1h,0E4h,0DDh
	db	0E6h,0E7h,0EAh,0ECh,0E0h,000h,0DBh,0D9h	;track 12 North Carol.
	db	0EAh,0E7h,0E4h,0E1h,0E6h,0D9h,000h,000h
	db	000h,0F3h,0FCh,0E7h
	db	0F3h,0F9h,000h,0E5h,0E1h,0E4h,0DDh
	db	0D9h,0ECh,0E4h,0D9h,0E6h,0ECh,0D9h,000h	;track 11 Atlanta
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,0F3h,0FCh,0F7h
	db	0F4h,0F4h,000h,0E5h,0E1h,0E4h,0DDh
	db	0DCh,0D9h,0EAh,0E4h,0E1h,0E6h,0DFh,0ECh	;track  8 Darlington
	db	0E7h,0E6h,000h,000h,000h,000h,000h,000h
	db	000h,0F3h,0FCh,0F5h
	db	0F8h,0F8h,000h,0E5h,0E1h,0E4h,0DDh
	db	0DAh,0EAh,0E1h,0EBh,0ECh,0E7h,0E4h,000h	;track  6 Bristol
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,0FCh,0F7h
	db	0F5h,0F5h,000h,0E5h,0E1h,0E4h,0DDh
	db	0E6h,0E7h,0EAh,0ECh,0E0h,000h,0EFh,0E1h	;track 13 North Wilk.
	db	0E4h,0E3h,0DDh,0EBh,0DAh,0E7h,0EAh,0E7h
	db	000h,000h,0FCh,0F8h
	db	0F4h,0F7h,000h,0E5h,0E1h,0E4h,0DDh
	db	0E5h,0D9h,0EAh,0ECh,0E1h,0E6h,0EBh,0EEh	;track 10 Martinsville
	db	0E1h,0E4h,0E4h,0DDh,000h,000h,000h,000h
	db	000h,000h,0FCh,0F7h
	db	0F4h,0F8h,000h,0E5h,0E1h,0E4h,0DDh
	db	0ECh,0D9h,0E4h,0E4h,0D9h,0DCh,0DDh,0DFh	;track  2 Talladega
	db	0D9h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,0F4h,0FCh
	db	0F8h,0F8h,000h,0E5h,0E1h,0E4h,0DDh
	db	0DBh,0E0h,0D9h,0EAh,0E4h,0E7h,0ECh,0ECh	;track  3 Charlotte
	db	0DDh,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,0F3h
	db	0FCh,0F7h,000h,0E5h,0E1h,0E4h,0DDh
	db	0DCh,0E7h,0EEh,0DDh,0EAh,000h,000h,000h	;track  5 Dover
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,0F3h
	db	0FCh,0E7h,000h,0E5h,0E1h,0E4h,0DDh
	db	0E8h,0E7h,0DBh,0E7h,0E6h,0E7h,000h,000h	;track  7 Pocono
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,0F4h
	db	0FCh,0F7h,000h,0E5h,0E1h,0E4h,0DDh
	db	0E5h,0E1h,0DBh,0E0h,0E1h,0DFh,0D9h,0E6h	;track  4 Michigan
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,0F4h
	db	0FCh,0E7h,000h,0E5h,0E1h,0E4h,0DDh
	db	0E8h,0E0h,0E7h,0DDh,0E6h,0E1h,0F0h,000h	;track  1 Phoenix
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,0F3h
	db	0FCh,0E7h,000h,0E5h,0E1h,0E4h,0DDh



;---
; GMPAL - game palette
;---
gmpal	db niblack,$26,$10,$30
	db niblack,$1C,$1A,$2C
 	db niblack,$1B,$1A,$2A
 	db niblack,$3D,$1A,$05

; Sprites
	db niblack,$15,$38,$13
	db niblack,$2c,$38,$1a
	db niblack,$00,$22,$11
	db niblack,$3d,$30,$15

;---
; TVPAL - game palette
;---
tvpal	db $1A,$00,$30,$10		;green	drkgray	white	gray
	db $1A,$30,$30,$30		;white	white	white	white
 	db $1A,$30,$30,$30		;white	white	white	white
 	db $1A,$30,$30,$30		;white	white	white	white

; Sprites
	db $1A,$15,$38,$13
	db $1A,$2c,$38,$1a
	db $1A,$00,$22,$11
	db $1A,$3d,$30,$15

;---
;	d:tdash.map
;---
tdash_map:
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$01,$02,$02,$03,$04,$05,$06
	db	$07,$08,$09,$0A,$0B,$0C,$0D,$0E
	db	$0F,$10,$11,$12,$13,$14,$15,$06
	db	$16,$02,$02,$02,$02,$02,$17,$00
	db	$00,$18,$19,$1A,$1B,$1C,$1D,$1E
	db	$1F,$00,$00,$00,$20,$21,$22,$23
	db	$24,$25,$26,$27,$28,$29,$2A,$2B
	db	$2C,$2D,$2E,$2F,$30,$31,$32,$00
	db	$00,$33,$D2,$D2,$35,$36,$37,$38
	db	$39,$3A,$3B,$3C,$3D,$3E,$3F,$40
	db	$41,$42,$43,$44,$45,$46,$47,$48
	db	$49,$B3,$B3,$B3,$B3,$B3,$4A,$00
	db	$00,$4B,$4C,$4D,$4E,$4F,$50,$51
	db	$52,$53,$54,$55,$56,$57,$58,$59
	db	$5A,$5B,$5C,$5D,$5E,$5F,$60,$61
	db	$62,$63,$64,$65,$66,$67,$68,$00
	db	$00,$69,$6A,$6A,$6A,$6A,$6A,$6A
	db	$6A,$6A,$6A,$6A,$6A,$6A,$6B,$6C
	db	$6D,$6E,$6A,$6A,$6A,$6A,$6A,$6A
	db	$6A,$6A,$6A,$6A,$6A,$6A,$6F,$00
	db	$00,$70,$71,$71,$71,$71,$71,$71
	db	$71,$71,$71,$71,$71,$72,$73,$74
	db	$75,$76,$77,$71,$71,$71,$71,$71
	db	$71,$71,$71,$71,$71,$71,$78,$00
	db	$00,$79,$7A,$34,$7B,$7C,$7D,$7E
	db	$7F,$80,$34,$81,$82,$83,$BE,$BE
	db	$BE,$BE,$85,$7A,$86,$87,$88,$89
	db	$8A,$8B,$8C,$8D,$8E,$82,$8F,$00
	db	$00,$34,$34,$34,$90,$91,$92,$93
	db	$94,$95,$34,$34,$34,$96,$97,$98
	db	$99,$97,$9A,$34,$9B,$9C,$9D,$9E
	db	$9F,$A0,$A1,$A2,$A3,$34,$34,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
;---
;	d:tdash.col
;---
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$50,$10
	db	$00,$00,$00,$80,$20,$00,$00,$00
	db	$00,$0F,$03,$00,$00,$0F,$0F,$00

;---
; write_victory - write the victory lane screen
;---
write_victory:
	public	write_victory
	jsr	nividoff

	lda	#<niscreen0		;set working screen
	sta	VRAMbase		;
	lda	#>niscreen0		;
	sta	VRAMbase+1		;

	ldx	#0			;clear screen 0
	ldy	#0			;
	jsr	setVRAMaddr		;
	jsr	niscrclr_any		;

	ldx	#0			;position to top of screen and write
	ldy	#0			;
	jsr	setVRAMaddr		;
	lda	#<victory_map		;prime the source pointer
	sta	tvtmp			;
	lda	#>victory_map		;
	sta	tvtmp+1			;
	ldx	#30			;number of lines to move
	jsr	write_x_lines		;

	lda	#>nipal			;set VRAM address to palette area
	sta	nivramaddr		;
	lda	#<nipal			;
	sta	nivramaddr		;

	lda	#<palvictory		;set palette to xreg palette
	sta	tvtmp			;
	lda	#>palvictory		;
	sta	tvtmp+1			;
	ldx	#1			;number of lines to move
	jsr	write_x_lines		;

	rts

;---
;	victory.map
;---
victory_map:
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$3C,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3E,$00,$00,$00
	db	$00,$00,$00,$43,$00,$00,$00,$00
	db	$00,$00,$36,$29,$23,$34,$2F,$32
	db	$39,$00,$2C,$21,$2E,$25,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$11,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$11,$12
	db	$13,$14,$15,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$12,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$16,$17
	db	$18,$19,$15,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$13,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$11,$10
	db	$10,$10,$10,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$14,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$11,$10
	db	$10,$10,$10,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$15,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$11,$10
	db	$10,$10,$10,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$16,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$11,$10
	db	$10,$10,$10,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$17,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$11,$10
	db	$10,$10,$10,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$18,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$11,$10
	db	$10,$10,$10,$10,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$44,$42,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$41,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$3C,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3D,$3D,$3D,$3D
	db	$3D,$3D,$3D,$3D,$3E,$00,$00,$00
	db	$00,$00,$00,$43,$00,$00,$00,$00
	db	$00,$00,$00,$00,$23,$32,$25,$24
	db	$29,$34,$33,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$24,$25,$33,$29
	db	$27,$2E,$0D,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$00,$23,$28,$32
	db	$29,$33,$00,$2F,$22,$25,$32,$34
	db	$28,$0C,$00,$2C,$2F,$35,$00,$28
	db	$21,$25,$28,$2E,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$30,$32,$2F,$27
	db	$32,$21,$2D,$2D,$29,$2E,$27,$0D
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$00,$2C,$2F,$35
	db	$00,$28,$21,$25,$28,$2E,$0C,$00
	db	$23,$28,$32,$29,$33,$00,$2F,$22
	db	$25,$32,$34,$28,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$27,$32,$21,$30
	db	$28,$29,$23,$33,$0D,$00,$2D,$21
	db	$32,$2B,$00,$33,$30,$32,$25,$2E
	db	$27,$25,$32,$0C,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$00,$2B,$25,$29
	db	$34,$28,$00,$23,$2F,$2F,$30,$25
	db	$32,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$2D,$35,$33,$29
	db	$23,$00,$06,$00,$33,$2F,$35,$2E
	db	$24,$0D,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$3F,$00,$00,$00
	db	$00,$00,$00,$43,$00,$23,$28,$32
	db	$29,$33,$00,$2F,$22,$25,$32,$34
	db	$28,$0C,$00,$2C,$2F,$35,$00,$28
	db	$21,$25,$28,$2E,$3F,$00,$00,$00
	db	$00,$00,$00,$44,$42,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$42,$42,$42,$42
	db	$42,$42,$42,$42,$41,$00,$00,$00
	db	$00,$00,$30,$32,$25,$33,$33,$00
	db	$33,$34,$21,$32,$34,$00,$34,$2F
	db	$00,$32,$25,$33,$34,$21,$32,$34
	db	$00,$27,$21,$2D,$25,$0E,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00
	db	$00,$00,$00,$00,$00,$00,$00,$00

;---
; victory screen palette
;---
palvictory:
	db	$07,$28,$38,$20		;gold	yellow	ltyel	medwhite
	db	$07,$0F,$0F,$20		;gold	black	black	medwhite
 	db	$07,$08,$0F,$38		;gold	dkbrown	black	yellow
 	db	$07,$12,$18,$38		;gold	medblue	brown	yellow
; Sprites
	db	$07,$15,$38,$00
	db	$07,$2c,$38,$22
	db	$07,$00,$22,$06
	db	$07,$3d,$30,$0A

;----
; data local and external
;---

;---
; local data
;---
	extern	tv_sv_niscrollm		;ds 1	;save sv_niscrollm
	extern	tv_sv_niscrollh		;ds 1	;save sv_niscrollh
	extern	tv_niscrollm		;ds 1	;save niscrollm
	extern	tv_niscrollh		;ds 1	;save niscrollh
	extern	VRAMbase		;ds 2	;screen base address
	extern	track_vector		;ds 3	;indirect jump for track rtns
	extern	track			;ds 1	;track number

;---
; external data
;---
	extern	mytask
	extern	nicr0SH
	extern	niscrollm
	extern	sv_niscrollh
	extern	sv_niscrollm
	extern	trackwrap1
	extern	tsknums

;---
; zeropage data
;---
	extern	PAGE0 tvtmp		;2 byte pointer

	END
