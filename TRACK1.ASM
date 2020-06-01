;---
; track1.asm - routines and data for track 1
;---

	LINKLIST

	include nindef.asm
	include ninref.asm

;---
; map equates
;---
sliceht	equ	18		;height of a map slice
cbytes	equ	5		;number of area color codes for the map slice

BANK4	SECTION

;---
; track1 - make next vertical slice of background for track 1
;---
track0:
	public	track0
	lda	#13			;talledega is in bank 13
	sta	nibnkchrSH		;

	lda	niscrollh		;this will go to hardware next NMI
	sta	sv_niscrollh		;also used by sliceout
	lda	niscrollm		;this will go to hardware next NMI
	sta	sv_niscrollm		;also used by sliceout

	lda	niscrollm		;get current screen number
	eor	#$FF			;calc index into track table
	asl	a			;
	asl	a			;(4 bands per screen)
	sta	maptmp			;save
	lda	niscrollh		;current scroll
	eor	#$FF			;make positive
	and	#%11000000		;make a band number
	clc				;
	rol	a			;move to low bits
	rol	a			;
	rol	a			;
	clc				;displacement for band in track table
	adc	maptmp			;

	tax
	lda	track01,x		;get band number

	tax				;get address of this band
	lda	bandlo,x		;
	sta	maptmp			;
	lda	bandhi,x		;
	sta	maptmp+1		;

	lda	niscrollh		;calc which slice number within the band
	eor	#$FF			;
	and	#%00111000		;
	lsr	a			;
	lsr	a			;
	lsr	a			;
	tay				;get that slice number
	lda	(maptmp),y		;

	tax				;get address of this slice
	lda	slicelo,x		;
	sta	maptmp			;
	lda	slicehi,x		;
	sta	maptmp+1		;
	
	ldy	#0			;index use
?1:	lda	(maptmp),y		;slice to slice buffer for 'slice_out'
	sta	Lbuf,y			;
	iny				;
	cpy	#sliceht		;done with background?
	bne	?1			;no: get next
	jsr	buffer_color		;yes: go buffer color bytes

	lda	niscrollh		;time for a new set of y values?
	and	#$F8			;
	cmp	last_sh			;
	beq	bs_exit			;no: y value okay as they are now
	sta	last_sh			;yes: save for next time in
	ldx	#30			;31 values to the right in the 4 tables
?2:	lda	lane1y,x		;
	sta	lane1y+1,x		;
	lda	lane2y,x		;
	sta	lane2y+1,x		;
	lda	lane3y,x		;
	sta	lane3y+1,x		;
	lda	lane4y,x		;
	sta	lane4y+1,x		;
	dex
	bpl	?2
	lda	(maptmp),y		;new y value from slice definition
	sta	lane1y
	iny
	lda	(maptmp),y
	sta	lane2y
	iny
	lda	(maptmp),y
	sta	lane3y
	iny
	lda	(maptmp),y
	sta	lane4y
	iny

bs_exit:
	rts	

;---
; buffer_color - look 4 bytes (32 pixels) ahead for color info
;---
buffer_color:
	sec
	lda sv_niscrollh
	sbc #32
	sta color_niscrollh
	lda sv_niscrollm
	sbc #0
	cmp trackwrap			;wrap track?
	bne ?nowrap			;no: continue
	lda #$ff			;yes: restart the track
?nowrap	sta color_niscrollm

	lda	color_niscrollm		;get current screen number
	eor	#$FF			;calc index into track table
	asl	a			;
	asl	a			;(4 bands per screen)
	sta	maptmp2			;save
	lda	color_niscrollh		;current scroll
	eor	#$FF			;make positive
	and	#%11000000		;make a band number
	clc				;
	rol	a			;move to low bits
	rol	a			;
	rol	a			;
	clc				;displacement for band in track table
	adc	maptmp2			;

	tax
	lda	track01,x		;get band number

	tax				;get address of this band
	lda	bandlo,x		;
	sta	maptmp2			;
	lda	bandhi,x		;
	sta	maptmp2+1		;

	lda	color_niscrollh		;calc which slice number within the band
	eor	#$FF			;
	and	#%00111000		;
	lsr	a			;
	lsr	a			;
	lsr	a			;
	tay				;get that slice number
	lda	(maptmp2),y		;

	tax				;get address of this slice
	lda	slicelo,x		;
	sta	maptmp2			;
	lda	slicehi,x		;
	sta	maptmp2+1		;
	
	ldy	#sliceht		;index use
?1:	lda	(maptmp2),y		;color to slice buffer for 'slice_out'
	sta	Lbuf,y			;
	iny				;
	cpy	#sliceht+cbytes		;
	bne	?1			;
	rts

	INCLUDE	t_i1.asm
	INCLUDE	t_i2.asm
	INCLUDE	t_i3.asm
	INCLUDE	t_l.asm
	INCLUDE t_n.asm
	INCLUDE t_o.asm
	INCLUDE t_p.asm
	INCLUDE	t_1.asm
	INCLUDE	t_2.asm
	INCLUDE	4b.asm
	INCLUDE	2a_ends.asm

;---
; map data - slices, bands defs, track defs, slice addrs and band addrs
;---
bandlo	db	<band00,<band01,<band02,<band03,<band04
	db	<band05,<band06,<band07,<band08,<band09
	db	<band10,<band11,<band12,<band13,<band14
	db	<band15,<band16,<band17,<band18,<band19
	db	<band20,<band21,<band22,<band23,<band24
	db	<band25,<band26,<band27,<band28,<band29
	db	<band30,<band31,<band32,<band33,<band34
	db	<band35,<band36,<band37,<band38,<band39
	db	<band40,<band41,<band42,<band43,<band44
	db	<band45,<band46,<band47,<band48,<band49
	db	<band50,<band51,<band52,<band53,<band54
	db	<band55,<band56,<band57,<band58,<band59
	db	<band60,<band61,<band62,<band63,<band64
	db	<band65,<band66,<band67,<band68,<band69
	db	<band70,<band71,<band72,<band73,<band74
	db	<band75,<band76,<band77,<band78,<band79
	
bandhi	db	>band00,>band01,>band02,>band03,>band04
	db	>band05,>band06,>band07,>band08,>band09
	db	>band10,>band11,>band12,>band13,>band14
	db	>band15,>band16,>band17,>band18,>band19
	db	>band20,>band21,>band22,>band23,>band24
	db	>band25,>band26,>band27,>band28,>band29
	db	>band30,>band31,>band32,>band33,>band34
	db	>band35,>band36,>band37,>band38,>band39
	db	>band40,>band41,>band42,>band43,>band44
	db	>band45,>band46,>band47,>band48,>band49
	db	>band50,>band51,>band52,>band53,>band54
	db	>band55,>band56,>band57,>band58,>band59
	db	>band60,>band61,>band62,>band63,>band64
	db	>band65,>band66,>band67,>band68,>band69
	db	>band70,>band71,>band72,>band73,>band74
	db	>band75,>band76,>band77,>band78,>band79

slicelo	db	<t_l_1			;000: full warning track w/ sky
	db	<t_l_29			;001: full warning track sm stand sky
	db	<t_l_32			;002: full warning track sm stand cloud
	db	<t_n_26			;003: warning: 1 up
	db	<t_n_24			;004: warning: interface for 1up/2up
	db	<t_n_22			;005: warning: 2 up
	db	<t_n_18			;006: warning: interface for 2up/3up
	db	<t_n_14			;007: warning: 3 up
	db	<t_n_09			;008: warning: interface for 3up/4up
	db	<t_n_05			;009: warning: 4 up
	db	<t_n_03			;010: warning: interface for 4up/5up
	db	<t_n_01			;011: warning: 5up
	db	<t_o_31			;012: warning: interface for 5up/6up
	db	<t_o_27			;013: warning: 6up
	db	<t_o_23			;014: warning: interface for 6up/7up
	db	<t_o_17			;015: warning: 7 up
	db	<t_o_13			;016: warning: interface for 7up/8up
	db	<t_o_12			;017: wall/warn: interface for 7up/8up
	db	<t_o_06			;018: wall/warn: 8 up
	db	<t_o_04			;019: wall/warn: interface for 8up/9up
	db	<t_o_01			;020: wall: 9 up
	db	<t_p_32			;021: wall: interface for 9up/10up
	db	<t_p_31			;022: wall: 10 up
	db	<t_p_28			;023: wall: interface for 10up/11up
	db	<t_p_26			;024: wall: 11 up
	db	<t_p_24			;025: wall: interface for 11up/12up
	db	<t_p_22			;026: wall: 12 up
	db	<t_p_19			;027: wall: interface for 12up/13up
	db	<t_p_17			;028: wall: 13 up
	db	<t_p_14			;029: wall: interface for 13up/14up
	db	<t_p_12			;030: wall: 14 up
	db	<t_p_10			;031: wall: interface for 14up/15up
	db	<t_p_08			;032: wall: 15 up
	db	<t_p_06			;033: wall: interface for 15up/16up
	db	<t_p_03			;034: wall: 16 up
	db	<t_p_02			;035: wall: interface for 16up/17up
	db	<t_p_01			;036: wall: 17 up

; end of mountain & clouds
	db	<e_2a_01,<e_2a_02,<e_2a_03,<e_2a_04	;slices 37 thru 44
	db	<e_2a_05,<e_2a_06,<e_2a_07,<e_2a_08
; start of mountains & clouds
	db	<e_2a_09,<e_2a_10,<e_2a_11,<e_2a_12	;slices 45 thru 52
	db	<e_2a_13,<e_2a_14,<e_2a_15,<e_2a_16

	db	<sl053,<sl054
	db	<sl055,<sl056,<sl057,<sl058,<sl059
	db	<sl060,<sl061,<sl062,<sl063

	db	<t_i1_01,<t_i1_02,<t_i1_03,<t_i1_04	;cloud bank 1
	db	<t_i1_05,<t_i1_06,<t_i1_07,<t_i1_08	;slices 64 thru 93
	db	<t_i1_09,<t_i1_10,<t_i1_11,<t_i1_12
	db	<t_i1_13,<t_i1_14,<t_i1_15,<t_i1_16
	db	<t_i1_17,<t_i1_18,<t_i1_19,<t_i1_20
	db	<t_i1_21,<t_i1_22,<t_i1_23,<t_i1_24
	db	<t_i1_25,<t_i1_26,<t_i1_27,<t_i1_28
	db	<t_i1_29,<t_i1_30,<t_i1_31,<t_i1_32

	db	<t_i2_01,<t_i2_02,<t_i2_03,<t_i2_04	;cloud bank 2
	db	<t_i2_05,<t_i2_06,<t_i2_07,<t_i2_08	;slices 96 thru 127
	db	<t_i2_09,<t_i2_10,<t_i2_11,<t_i2_12
	db	<t_i2_13,<t_i2_14,<t_i2_15,<t_i2_16
	db	<t_i2_17,<t_i2_18,<t_i2_19,<t_i2_20
	db	<t_i2_21,<t_i2_22,<t_i2_23,<t_i2_24
	db	<t_i2_25,<t_i2_26,<t_i2_27,<t_i2_28
	db	<t_i2_29,<t_i2_30,<t_i2_31,<t_i2_32

	db	<t_i3_01,<t_i3_02,<t_i3_03,<t_i3_04	;cloud bank 3
	db	<t_i3_05,<t_i3_06,<t_i3_07,<t_i3_08	;slices 128 thru 159
	db	<t_i3_09,<t_i3_10,<t_i3_11,<t_i3_12
	db	<t_i3_13,<t_i3_14,<t_i3_15,<t_i3_16
	db	<t_i3_17,<t_i3_18,<t_i3_19,<t_i3_20
	db	<t_i3_21,<t_i3_22,<t_i3_23,<t_i3_24
	db	<t_i3_25,<t_i3_26,<t_i3_27,<t_i3_28
	db	<t_i3_29,<t_i3_30,<t_i3_31,<t_i3_32

	db	<t_1_01,<t_1_02,<t_1_03,<t_1_04		;grandstand finish line
	db	<t_1_05,<t_1_06,<t_1_07,<t_1_08		;slices 160 thru 191
	db	<t_1_09,<t_1_10,<t_1_11,<t_1_12
	db	<t_1_13,<t_1_14,<t_1_15,<t_1_16
	db	<t_1_17,<t_1_18,<t_1_19,<t_1_20
	db	<t_1_21,<t_1_22,<t_1_23,<t_1_24
	db	<t_1_25,<t_1_26,<t_1_27,<t_1_28
	db	<t_1_29,<t_1_30,<t_1_31,<t_1_32

	db	<t_2_01,<t_2_02,<t_2_03,<t_2_04		;city scape
	db	<t_2_05,<t_2_06,<t_2_07,<t_2_08		;slices 192 thru 223
	db	<t_2_09,<t_2_10,<t_2_11,<t_2_12
	db	<t_2_13,<t_2_14,<t_2_15,<t_2_16
	db	<t_2_17,<t_2_18,<t_2_19,<t_2_20
	db	<t_2_21,<t_2_22,<t_2_23,<t_2_24
	db	<t_2_25,<t_2_26,<t_2_27,<t_2_28
	db	<t_2_29,<t_2_30,<t_2_31,<t_2_32

	db	<t_4b_01,<t_4b_02,<t_4b_03,<t_4b_04	;pine forest
	db	<t_4b_05,<t_4b_06,<t_4b_07,<t_4b_08	;slices 224 thru 255
	db	<t_4b_09,<t_4b_10,<t_4b_11,<t_4b_12
	db	<t_4b_13,<t_4b_14,<t_4b_15,<t_4b_16
	db	<t_4b_17,<t_4b_18,<t_4b_19,<t_4b_20
	db	<t_4b_21,<t_4b_22,<t_4b_23,<t_4b_24
	db	<t_4b_25,<t_4b_26,<t_4b_27,<t_4b_28
	db	<t_4b_29,<t_4b_30,<t_4b_31,<t_4b_32

slicehi
	db	>t_l_1			;000: full warning track w/ sky
	db	>t_l_29			;001: full warning track sm stand sky
	db	>t_l_32			;002: full warning track sm stand cloud
	db	>t_n_26			;003: warning: 1 up
	db	>t_n_24			;004: warning: interface for 1up/2up
	db	>t_n_22			;005: warning: 2 up
	db	>t_n_18			;006: warning: interface for 2up/3up
	db	>t_n_14			;007: warning: 3 up
	db	>t_n_09			;008: warning: interface for 3up/4up
	db	>t_n_05			;009: warning: 4 up
	db	>t_n_03			;010: warning: interface for 4up/5up
	db	>t_n_01			;011: warning: 5up
	db	>t_o_31			;012: warning: interface for 5up/6up
	db	>t_o_27			;013: warning: 6up
	db	>t_o_23			;014: warning: interface for 6up/7up
	db	>t_o_17			;015: warning: 7 up
	db	>t_o_13			;016: warning: interface for 7up/8up
	db	>t_o_12			;017: wall/warn: interface for 7up/8up
	db	>t_o_06			;018: wall/warn: 8 up
	db	>t_o_04			;019: wall/warn: interface for 8up/9up
	db	>t_o_01			;020: wall: 9 up
	db	>t_p_32			;021: wall: interface for 9up/10up
	db	>t_p_31			;022: wall: 10 up
	db	>t_p_28			;023: wall: interface for 10up/11up
	db	>t_p_26			;024: wall: 11 up
	db	>t_p_24			;025: wall: interface for 11up/12up
	db	>t_p_22			;026: wall: 12 up
	db	>t_p_19			;027: wall: interface for 12up/13up
	db	>t_p_17			;028: wall: 13 up
	db	>t_p_14			;029: wall: interface for 13up/14up
	db	>t_p_12			;030: wall: 14 up
	db	>t_p_10			;031: wall: interface for 14up/15up
	db	>t_p_08			;032: wall: 15 up
	db	>t_p_06			;033: wall: interface for 15up/16up
	db	>t_p_03			;034: wall: 16 up
	db	>t_p_02			;035: wall: interface for 16up/17up
	db	>t_p_01			;036: wall: 17 up

; end of mountain & clouds
	db	>e_2a_01,>e_2a_02,>e_2a_03,>e_2a_04	;slices 37 thru 44
	db	>e_2a_05,>e_2a_06,>e_2a_07,>e_2a_08
; start of mountains & clouds
	db	>e_2a_09,>e_2a_10,>e_2a_11,>e_2a_12	;slices 45 thru 52
	db	>e_2a_13,>e_2a_14,>e_2a_15,>e_2a_16

	db	>sl053,>sl054
	db	>sl055,>sl056,>sl057,>sl058,>sl059
	db	>sl060,>sl061,>sl062,>sl063

	db	>t_i1_01,>t_i1_02,>t_i1_03,>t_i1_04	;cloud bank 1
	db	>t_i1_05,>t_i1_06,>t_i1_07,>t_i1_08	;slices 64 thru 95
	db	>t_i1_09,>t_i1_10,>t_i1_11,>t_i1_12
	db	>t_i1_13,>t_i1_14,>t_i1_15,>t_i1_16
	db	>t_i1_17,>t_i1_18,>t_i1_19,>t_i1_20
	db	>t_i1_21,>t_i1_22,>t_i1_23,>t_i1_24
	db	>t_i1_25,>t_i1_26,>t_i1_27,>t_i1_28
	db	>t_i1_29,>t_i1_30,>t_i1_31,>t_i1_32

	db	>t_i2_01,>t_i2_02,>t_i2_03,>t_i2_04	;cloud bank 2
	db	>t_i2_05,>t_i2_06,>t_i2_07,>t_i2_08	;slices 96 thru 127
	db	>t_i2_09,>t_i2_10,>t_i2_11,>t_i2_12
	db	>t_i2_13,>t_i2_14,>t_i2_15,>t_i2_16
	db	>t_i2_17,>t_i2_18,>t_i2_19,>t_i2_20
	db	>t_i2_21,>t_i2_22,>t_i2_23,>t_i2_24
	db	>t_i2_25,>t_i2_26,>t_i2_27,>t_i2_28
	db	>t_i2_29,>t_i2_30,>t_i2_31,>t_i2_32

	db	>t_i3_01,>t_i3_02,>t_i3_03,>t_i3_04	;cloud bank 3
	db	>t_i3_05,>t_i3_06,>t_i3_07,>t_i3_08	;slices 128 thru 159
	db	>t_i3_09,>t_i3_10,>t_i3_11,>t_i3_12
	db	>t_i3_13,>t_i3_14,>t_i3_15,>t_i3_16
	db	>t_i3_17,>t_i3_18,>t_i3_19,>t_i3_20
	db	>t_i3_21,>t_i3_22,>t_i3_23,>t_i3_24
	db	>t_i3_25,>t_i3_26,>t_i3_27,>t_i3_28
	db	>t_i3_29,>t_i3_30,>t_i3_31,>t_i3_32

	db	>t_1_01,>t_1_02,>t_1_03,>t_1_04		;grandstand finish line
	db	>t_1_05,>t_1_06,>t_1_07,>t_1_08		;slices 160 thru 191
	db	>t_1_09,>t_1_10,>t_1_11,>t_1_12
	db	>t_1_13,>t_1_14,>t_1_15,>t_1_16
	db	>t_1_17,>t_1_18,>t_1_19,>t_1_20
	db	>t_1_21,>t_1_22,>t_1_23,>t_1_24
	db	>t_1_25,>t_1_26,>t_1_27,>t_1_28
	db	>t_1_29,>t_1_30,>t_1_31,>t_1_32

	db	>t_2_01,>t_2_02,>t_2_03,>t_2_04		;city scape
	db	>t_2_05,>t_2_06,>t_2_07,>t_2_08		;slices 192 thru 223
	db	>t_2_09,>t_2_10,>t_2_11,>t_2_12
	db	>t_2_13,>t_2_14,>t_2_15,>t_2_16
	db	>t_2_17,>t_2_18,>t_2_19,>t_2_20
	db	>t_2_21,>t_2_22,>t_2_23,>t_2_24
	db	>t_2_25,>t_2_26,>t_2_27,>t_2_28
	db	>t_2_29,>t_2_30,>t_2_31,>t_2_32

	db	>t_4b_01,>t_4b_02,>t_4b_03,>t_4b_04	;pine forest
	db	>t_4b_05,>t_4b_06,>t_4b_07,>t_4b_08	;slices 224 thru 255
	db	>t_4b_09,>t_4b_10,>t_4b_11,>t_4b_12
	db	>t_4b_13,>t_4b_14,>t_4b_15,>t_4b_16
	db	>t_4b_17,>t_4b_18,>t_4b_19,>t_4b_20
	db	>t_4b_21,>t_4b_22,>t_4b_23,>t_4b_24
	db	>t_4b_25,>t_4b_26,>t_4b_27,>t_4b_28
	db	>t_4b_29,>t_4b_30,>t_4b_31,>t_4b_32

;---
; Talladega
;---
track01
	db	45,46,47,44		;finish line and grand stands
	db	44,44,01,01		;grandstands

	db	52,53,54,55,56,57,58,59	;medium curve up
	db	14			;max curve
	db	60,61,62,63,64,65,66,67	;medium curve down

	db	44			;grandstands
	db	40,41,42,43		;straight away w/ clouds (side straight)
	db	36,37,38,39		;straight away w/ clouds (side straight)
	db	00,01			;little stands, warning

	db	68,69,70		;fast curve up
	db	71,72,73		;fast curve down
	
	db	79			;start mountains & clouds
	db	74,75,76,77		;back straight with pine forest
	db	74,75,76,77		;back straight with pine forest
	db	74,75,76,77		;back straight with pine forest

	db	44,44		;grandstand 
	db	44			;grandstand
	db	52,53,54,55,56,57,58,59	;medium curve up
	db	14			;max curve
	db	60,61,62,63,64,65,66,67	;medium curve down

	db	44,33,34,35		;straight away w/ clouds
	db	40,41,42,43		;straight away w/ clouds
	db	44,44,44		;grandstand
	db	44,44			;this is two extra?????????

;===========================================================================;

track00
	db	45,46,47,44	;finish line and grand stands
	db	44,44,44,44	;grandstands
	db	44,44,44,44	;grandstands
	db	40,41,42,43	;straight away w/ clouds
	db	40,41,42,43	;straight away w/ clouds
	db	32,33,34,35	;straight away w/ clouds
	db	36,37,38,39	;straight away w/ clouds

	db	00,01,01,01	;curve up: full warning track start
	db	02,03,04,05	;curve up: to 5 up from full warning
	db	06,07,08,09	;curve up: from warn:5up/6up to wall only 9up
	db	10,11,12,13	;curve up: to max in last slice

	db	14,14,14,14	;max curve

	db	15,16,17,18	;curve down:
	db	19,20,21,22	;curve down:
	db	23,24,25,26	;curve down:

	db	44,44,44,44	;grand stands
	db	40,41,42,43	;straightaway w/ clouds
	db	40,41,42,43	;straightaway w/ clouds
	db	32,33,34,35	;straightaway w/ clouds
	db	32,33,34,35	;straightaway w/ clouds
	db	36,37,38,39	;straightaway w/ clouds
	db	40,41,42,43	;straightaway w/ clouds

	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape
	db	48,49,50,51	;city scape

	db	32,33,34,35	;straightaway w/ clouds
	db	40,41,42,43	;straightaway w/ clouds
	db	36,37,38,39	;straightaway w/ clouds
	db	40,41,42,43	;straightaway w/ clouds

	db	00,01,01,01	;curve up: full warning track start
	db	02,03,04,05	;curve up: to 5 up from full warning
	db	06,07,08,09	;curve up: from warn:5up/6up to wall only 9up
	db	10,11,12,13	;curve up: to max in last slice

	db	14,14,14,14	;max curve

	db	15,16,17,18	;curve down:
	db	19,20,21,22	;curve down:
	db	23,24,25,26	;curve down:

	db	01,01,01,27	;full warning w/ mini stands
	db	36,37,38,39	;straightaway w/ clouds
	db	32,33,34,35	;straightaway w/ clouds
	db	40,41,42,43	;straightaway w/ clouds
	db	32,33,34,35	;straightaway w/ clouds
	db	40,41,42,43	;straightaway w/ clouds
	db	40,41,42,43	;straightaway w/ clouds
	db	44,44,44,44	;grandstands
	db	44,44,44,44	;grandstands

band00	db	02,01,01,01,01,01,01,01	;full warning, end of clouds & sm stand
band01	db	00,00,00,00,00,00,00,00	;full warning, no clouds
band02	db	00,00,00,03,03,03,03,04	;full warning to 1up to i(1up/2up)
band03	db	04,05,05,06,06,06,06,07	;i(1up/2up) to 2up to i(2up/3up) to 3up
band04	db	07,07,07,08,08,08,08,08	;3up to i(3up/4up)
band05	db	09,09,09,09,10,10,11,11	;4up to i(4up/5up) to 5up
band06	db	12,12,13,13,13,13,14,14	;i(5up/6up) to 6up to i(6up/7up)
band07	db	14,14,15,15,15,15,15,15	;i(6up/7up) to 7up
band08	db	16,16,16,16,17,18,18,18	;i(7up/8up) to wall start to wall 8up
band09	db	18,18,18,19,19,20,20,20	;wall 8up to i(8up/9up) to wall 9up
band10	db	21,22,23,23,23,24,24,25	;i(9up/10up)-10up-i(10up/11up)-11up-i(.
band11	db	25,26,26,27,27,27,28,28	;i(11up/12up)-12up-i(12up/13up)-13up
band12	db	29,29,29,30,30,31,31,32	;i(13up/14up)-14up-i(14up/15up)-15up
band13	db	32,33,33,34,34,34,35,36	;15up-i(15up/16up)-16up-i(16/17)-17up

band14	db	36,36,36,36,36,36,36,36	;max curve

band15	db	36,35,34,34,34,33,33,32	;opposite of band13
band16	db	32,31,31,30,30,29,29,29	;opposite of bank12
band17	db	28,28,27,27,27,26,26,25	;opposite of bank11
band18	db	25,24,24,23,23,23,22,21	;opposite of bank10
band19	db	20,20,20,19,19,18,18,18	;opposite of bank09
band20	db	18,18,18,17,16,16,16,16	;opposite of bank08
band21	db	15,15,15,15,15,15,14,14	;opposite of bank07
band22	db	14,14,13,13,13,13,12,12	;opposite of bank06
band23	db	11,11,10,10,09,09,09,09	;opposite of bank05
band24	db	08,08,08,08,08,07,07,07	;opposite of bank04
band25	db	07,06,06,06,06,05,05,04	;opposite of bank03
band26	db	04,03,03,03,03,00,00,00	;opposite of bank02

band27	db	01,01,01,01,01,01,01,01	;ends 1st curve

band28	db	56,57,56,57,56,57,56,57		;4 pixels up
band29	db	58,59,58,59,58,59,58,59		;5 pixels up
band30	db	60,61,60,61,60,61,60,61		;6 pixels up
band31	db	62,63,62,63,62,63,62,63		;7 pixels up

;---
; test cloud bands
;---
band32	db	159,158,157,156,155,154,153,152
band33	db	151,150,149,148,147,146,145,144
band34	db	143,142,141,140,139,138,137,136
band35	db	135,134,133,132,131,130,129,128
band36	db	127,126,125,124,123,122,121,120
band37	db	119,118,117,116,115,114,113,112
band38	db	111,110,109,108,107,106,105,104
band39	db	103,102,101,100,099,098,097,096
band40	db	095,094,093,092,091,090,089,088
band41	db	087,086,085,084,083,082,081,080
band42	db	079,078,077,076,075,074,073,072
band43	db	071,070,069,068,067,066,065,064

band44	db	32+159,31+159,30+159,29+159,28+159,27+159,26+159,25+159	;T_1 D
band45	db	24+159,23+159,22+159,21+159,20+159,19+159,18+159,17+159	;T_1 C
band46	db	16+159,15+159,14+159,13+159,12+159,11+159,10+159,09+159	;T_1 B
band47	db	08+159,07+159,06+159,05+159,04+159,03+159,02+159,01+159	;T_1 A

band48	db	32+191,31+191,30+191,29+191,28+191,27+191,26+191,25+191	;T_2 H
band49	db	24+191,23+191,22+191,21+191,20+191,19+191,18+191,17+191	;T_2 G
band50	db	16+191,15+191,14+191,13+191,12+191,11+191,10+191,09+191	;T_2 F
band51	db	08+191,07+191,06+191,05+191,04+191,03+191,02+191,01+191	;T_2 E

;---
; medium curve bands
;---
band52	db	03,03,04,04,05,05,06,06	;medium curve up
band53	db	07,07,08,08,09,09,10,10	;medium curve up
band54	db	11,11,12,12,13,13,14,14	;medium curve up
band55	db	15,15,16,16,17,17,18,18	;medium curve up
band56	db	19,19,20,20,21,21,22,22	;medium curve up
band57	db	23,23,24,24,25,25,26,26	;medium curve up
band58	db	27,27,28,28,29,29,30,30	;medium curve up
band59	db	31,31,32,32,33,33,34,35	;medium curve up
band60	db	35,34,33,33,32,32,31,31	;medium curve down
band61	db	30,30,29,29,28,28,27,27	;medium curve down
band62	db	26,26,25,25,24,24,23,23	;medium curve down
band63	db	22,22,21,21,20,20,19,19	;medium curve down
band64	db	18,18,17,17,16,16,15,15	;medium curve down
band65	db	14,14,13,13,12,12,11,11	;medium curve down
band66	db	10,10,09,09,08,08,07,07	;medium curve down
band67	db	06,06,05,05,04,04,03,03	;medium curve down

;---
; fast curve bands
;---
band68	db	03,04,05,06,07,08,09,10	;fast curve up
band69	db	11,12,13,14,17,17,17,17	;fast curve up
band70	db	18,19,20,21,22,23,24,25	;fast curve up
band71	db	26,25,24,23,22,21,20,19	;fast curve down
band72	db	18,17,16,15,14,13,12,11	;fast curve down
band73	db	10,09,08,07,06,05,04,03	;fast curve down

;---
; pine forest bands
;---
band74	db	32+223,31+223,30+223,29+223,28+223,27+223,26+223,25+223	;4B D
band75	db	24+223,23+223,22+223,21+223,20+223,19+223,18+223,17+223	;4B C
band76	db	16+223,15+223,14+223,13+223,12+223,11+223,10+223,09+223	;4B B
band77	db	08+223,07+223,06+223,05+223,04+223,03+223,02+223,01+223	;4B A

band78	db	44,43,42,41,40,39,38,37	;end of mountains and sky

band79	db	52,51,50,49,48,47,46,45	;start of mountains and sky

sl044	db	0
sl045	db	0
sl046	db	0
sl047	db	0
sl048	db	0
sl049	db	0
sl050	db	0
sl051	db	0
sl052	db	0
sl053	db	0
sl054	db	0
sl055	db	0
sl056	db	0
sl057	db	0
sl058	db	0
sl059	db	0
sl060	db	0
sl061	db	0
sl062	db	0
sl063	db	0
sl017	db	0

;===========================================================================
;---
; external data
;---
	extern	Lbuf
	extern	niscrolll,niscrollm
	extern	track
	extern	track_jmp

;---
; module data for MAPSTUFF.ASM and TRACK#.ASM
;---
	extern	last_sh,lane1y,lane2y,lane3y,lane4y
	extern	sv_niscrollh,sv_niscrollm
	extern	color_niscrollm,color_niscrollh
	extern	nicr0SH
	extern	trackwrap

;---
; zero page data for MAPSTUFF.ASM and TRACK#.ASM
;---
	extern	PAGE0 maptmp		;2 byte pointer
	extern	PAGE0 maptmp2		;2 byte pointer

	END
