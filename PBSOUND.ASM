
	LINKLIST

	include	nindef.asm
	include	ninref.asm

	external	wave0
	external	envr0
	external	decay0
	external	decayr0
	external	sweep0
	external	swedir0
	external	sweepr0
	external	sweeps0
	external	freqlo0
	external	freqhi0
	external	envdur0
	external	wave1
	external	envr1
	external	decay1
	external	decayr1
	external	sweep1
	external	swedir1
	external	sweepr1
	external	sweeps1
	external	freqlo1
	external	freqhi1
	external	envdur1
	external	envr2
	external	freqlo2
	external	freqhi2
	external	envdur2
	external	ntype3
	external	envr3
	external	decay3
	external	decayr3
	external	mfreq3
	external	envdur3



	external	rptcnt

	external	savey0
	external	savey1
	external	savey2
	external	savey3

	external	twaits0
	external	twaits1
	external	twaits2
	external	twaits3



	external	tracka
	external	dracka

	external	trackb
	external	drackb

	external	trackc
	external	drackc

	external	trackd
	external	drackd



;===========================================================================
; Beginning of sound module
;===========================================================================

BANK1	SECTION

	PUBLIC	sndinit,sndplay
sndinit
	asl a
	tay
	lda trsela,y
	sta tracka
	lda trsela+1,y
	sta tracka+1
	lda drsela,y
	sta dracka
	lda drsela+1,y
	sta dracka+1

	lda trselb,y
	sta trackb
	lda trselb+1,y
	sta trackb+1
	lda drselb,y
	sta drackb
	lda drselb+1,y
	sta drackb+1

	lda trselc,y
	sta trackc
	lda trselc+1,y
	sta trackc+1
	lda drselc,y
	sta drackc
	lda drselc+1,y
	sta drackc+1

	lda trseld,y
	sta trackd
	lda trseld+1,y
	sta trackd+1
	lda drseld,y
	sta drackd
	lda drseld+1,y
	sta drackd+1


	lda #0
	sta rptcnt
	sta rptcnt+1
	sta rptcnt+2
	sta rptcnt+3

	sta savey0
	sta savey1
	sta savey2
	sta savey3

	lda #1
	sta twaits0
	sta twaits1
	sta twaits2
	sta twaits3

	lda #$0f
	sta s15


sndplay
	lda twaits0
	cmp #$ff
	beq ?no0
	dec twaits0
	bne ?no0
	ldx #0
	jsr sng0
?no0
	lda twaits1
	cmp #$ff
	beq ?no1
	dec twaits1
	bne ?no1
	ldx #1
	jsr sng1
?no1
	lda twaits2
	cmp #$ff
	beq ?no2
	dec twaits2
	bne ?no2
	ldx #2
	jsr sng2
?no2
	lda twaits3
	cmp #$ff
	beq ?no3
	dec twaits3
	bne ?no3
	ldx #3
	jsr sng3
?no3
	rts




s0	equ	$4000
s1	equ	$4001
s2	equ	$4002
s3	equ	$4003
s4	equ	$4004
s5	equ	$4005
s6	equ	$4006
s7	equ	$4007
s8	equ	$4008
s9	equ	$4009
sa	equ	$400a
sb	equ	$400b
sc	equ	$400c
sd	equ	$400d
se	equ	$400e
sf	equ	$400f
s10	equ	$4010
s11	equ	$4011
s12	equ	$4012
s13	equ	$4013
s15	equ	$4015


; INSERT BTR2 DB FILE FROM EDITOR HERE!
; RETAIN ONE SET OF INSTRUMENT SETTINGS AND NUMBER THE TRACK LABELS

ich0sel	db $1,$1,$1,$1,$1,$1,$1,$1
iwave0	db $0,$0,$2,$0,$2,$0,$1,$0
ienvr0	db $0,$0,$0,$0,$0,$0,$1,$0
idecay0	db $1,$1,$1,$1,$1,$1,$1,$1
idecayr0	db $5,$5,$5,$5,$5,$5,$5,$4
isweep0	db $0,$1,$0,$1,$0,$0,$0,$1
iswedir0	db $1,$0,$1,$1,$0,$0,$0,$0
isweepr0	db $7,$4,$4,$4,$7,$7,$7,$0
isweeps0	db $7,$5,$5,$5,$7,$7,$7,$3
ifreqlo0	db $0,$0,$0,$0,$0,$0,$0,$0
ifreqhi0	db $1,$1,$1,$1,$1,$1,$1,$1
ienvdur0	db $18,$18,$18,$18,$18,$18,$11,$18
ich1sel	db $1,$1,$1,$1,$1,$1,$1,$1
iwave1	db $2,$2,$2,$2,$1,$1,$3,$2
ienvr1	db $0,$0,$0,$0,$0,$0,$0,$0
idecay1	db $1,$1,$1,$1,$1,$1,$1,$1
idecayr1	db $5,$5,$5,$5,$5,$5,$4,$5
isweep1	db $0,$1,$0,$1,$0,$0,$0,$1
iswedir1	db $0,$0,$1,$1,$0,$0,$0,$0
isweepr1	db $7,$4,$4,$4,$7,$7,$7,$0
isweeps1	db $7,$5,$5,$5,$7,$7,$7,$4
ifreqlo1	db $0,$0,$0,$0,$0,$0,$0,$0
ifreqhi1	db $1,$1,$1,$1,$1,$1,$1,$1
ienvdur1	db $18,$18,$18,$18,$18,$18,$18,$18
ich2sel	db $1,$1,$1,$1,$1,$1,$1,$0
ienvr2	db $0,$0,$0,$0,$0,$0,$0,$0
ifreqlo2	db $0,$0,$0,$0,$0,$0,$0,$A
ifreqhi2	db $1,$1,$1,$1,$1,$1,$1,$4
ienvdur2	db $18,$18,$18,$18,$18,$18,$18,$18
ich3sel	db $1,$1,$1,$1,$1,$1,$1,$1
intype3	db $1,$1,$1,$1,$0,$0,$0,$0
ienvr3	db $0,$0,$0,$0,$0,$0,$0,$0
idecay3	db $1,$1,$1,$1,$1,$1,$1,$1
idecayr3	db $5,$5,$5,$5,$5,$5,$5,$3
imfreq3	db $6,$6,$6,$6,$4,$4,$4,$9
ienvdur3	db $18,$18,$18,$18,$18,$18,$18,$7


;BTR2
tracka1	db $34,$0,$8B,$34,$18,$34,$18,$16
	db $14,$0,$16,$14,$12,$0,$34,$18
	db $16,$14,$16,$18,$14,$12,$34,$0
	db $18,$16,$14,$0,$16,$14,$12,$0
	db $34,$18,$16,$14,$16,$18,$14,$1B
	db $34,$0,$14,$34,$1D,$1B,$19,$0
	db $1C,$1B,$19,$0,$1B,$19,$18,$19
	db $1B,$19,$18,$0,$34,$20,$34,$18
	db $16,$14,$0,$16,$14,$12,$0,$34
	db $18,$16,$14,$16,$18,$12,$14,$32
dracka1	db $0,$50,$1,$1,$50,$0,$14,$A
	db $1E,$14,$14,$A,$1E,$14,$2,$A
	db $A,$A,$A,$A,$A,$1E,$0,$1E
	db $14,$A,$1E,$14,$14,$A,$1E,$14
	db $2,$A,$A,$A,$A,$A,$A,$1E
	db $3,$1E,$28,$0,$14,$A,$1E,$14
	db $14,$A,$1E,$14,$A,$A,$A,$A
	db $A,$A,$1E,$1E,$1,$28,$0,$14
	db $A,$1E,$14,$14,$A,$1E,$14,$2
	db $A,$A,$A,$A,$A,$A,$50,$0
trackb1	db $34,$0,$8B,$34,$20,$34,$20,$1E
	db $1D,$0,$1E,$1D,$1B,$0,$0,$0
	db $81,$34,$34,$12,$34,$25,$23,$22
	db $0,$28,$1B,$25,$0,$27,$24,$27
	db $24,$0,$34,$1E,$34,$20,$1E,$1D
	db $0,$1E,$1D,$1B,$0,$0,$0,$0
	db $32
drackb1	db $0,$50,$1,$1,$50,$0,$14,$A
	db $1E,$14,$14,$A,$1E,$14,$50,$28
	db $A,$3,$3,$28,$0,$14,$A,$1E
	db $14,$14,$A,$1E,$14,$14,$14,$14
	db $1E,$1E,$1,$28,$0,$14,$A,$1E
	db $14,$14,$A,$1E,$14,$50,$28,$14
	db $0
trackc1	db $34,$0,$87,$1B,$20,$18,$20,$97
	db $19,$1D,$19,$20,$83,$1B,$20,$18
	db $20,$8A,$0,$0,$32
drackc1	db $0,$50,$1,$A,$A,$A,$A,$4
	db $A,$A,$A,$A,$4,$A,$A,$A
	db $A,$4,$28,$14,$0
trackd1	db $34,$6,$0,$8E,$6,$0,$7,$0
	db $87,$6,$0,$8,$0,$87,$6,$0
	db $9,$0,$D8,$6,$0,$32
drackd1	db $0,$5,$5,$2,$5,$5,$5,$5
	db $4,$5,$5,$5,$5,$4,$5,$5
	db $5,$5,$4,$5,$5,$0



	IF 0

;YELLOW
tracka2	db $34,$0,$0,$0,$0,$A,$8,$7
	db $A,$A,$A,$C,$A,$8,$7,$A
	db $F,$11,$13,$0,$13,$13,$A,$A
	db $13,$13,$11,$F,$E,$F,$11,$13
	db $11,$0,$A,$7,$A,$A,$A,$C
	db $A,$8,$7,$A,$F,$11,$13,$0
	db $A,$A,$14,$14,$14,$14,$13,$11
	db $F,$F,$A,$13,$11,$F,$0,$32
dracka2	db $4,$40,$40,$40,$40,$8,$8,$10
	db $10,$10,$10,$10,$20,$10,$10,$10
	db $18,$8,$20,$10,$10,$10,$10,$10
	db $10,$10,$20,$10,$18,$8,$18,$8
	db $20,$10,$10,$10,$10,$10,$10,$10
	db $20,$10,$10,$10,$18,$8,$20,$10
	db $10,$10,$10,$10,$10,$10,$10,$18
	db $8,$18,$8,$18,$8,$20,$10,$0
trackb2	db $34,$0,$0,$0,$0,$0,$93,$8
	db $3,$8,$3,$8,$3,$3,$8,$3
	db $3,$8,$A,$5,$5,$8,$3,$8
	db $3,$8,$3,$3,$8,$3,$8,$8
	db $3,$8,$3,$8,$3,$0,$32
drackb2	db $4,$40,$40,$40,$40,$40,$1,$10
	db $40,$10,$10,$20,$20,$18,$8,$40
	db $40,$40,$40,$20,$10,$10,$40,$10
	db $10,$20,$20,$18,$8,$40,$40,$10
	db $10,$20,$20,$20,$20,$10,$0
trackc2	db $34,$0,$0,$0,$0,$0,$93,$20
	db $1F,$1D,$1F,$1D,$1F,$1F,$1D,$1F
	db $1F,$1D,$1D,$1D,$1D,$22,$1F,$1D
	db $1F,$1D,$1F,$1F,$1D,$1F,$20,$1D
	db $1F,$1D,$1F,$1D,$1F,$0,$32
drackc2	db $4,$40,$40,$40,$40,$40,$1,$10
	db $40,$10,$10,$20,$20,$18,$8,$40
	db $40,$40,$40,$20,$10,$10,$40,$10
	db $10,$20,$20,$18,$8,$40,$40,$10
	db $10,$20,$20,$20,$20,$10,$0
trackd2	db $34,$6,$0,$6,$0,$6,$0,$A
	db $0,$8,$0,$D,$0,$D,$0,$D
	db $0,$8,$0,$0,$32
drackd2	db $4,$4,$4,$4,$4,$4,$C,$4
	db $C,$4,$4,$4,$4,$4,$4,$4
	db $4,$4,$20,$C,$0


;JOHN
tracka3	db $34,$0,$0,$0,$0,$0,$0,$0
	db $0,$5,$0,$5,$A,$A,$A,$C
	db $D,$C,$D,$A,$8,$0,$5,$8
	db $0,$5,$0,$5,$A,$A,$A,$C
	db $D,$C,$D,$F,$11,$0,$D,$11
	db $0,$D,$F,$11,$11,$11,$F,$D
	db $F,$F,$F,$C,$D,$D,$D,$C
	db $A,$C,$C,$C,$D,$F,$11,$F
	db $D,$C,$5,$A,$A,$A,$8,$A
	db $0,$0,$32
dracka3	db $5,$28,$14,$28,$14,$28,$14,$14
	db $1E,$5,$5,$A,$A,$A,$14,$A
	db $14,$A,$14,$A,$28,$A,$A,$28
	db $A,$5,$5,$A,$A,$A,$14,$A
	db $14,$A,$14,$A,$28,$A,$A,$28
	db $A,$5,$5,$14,$A,$A,$A,$A
	db $14,$A,$14,$A,$14,$A,$A,$A
	db $A,$14,$A,$A,$A,$A,$1E,$1E
	db $1E,$1E,$A,$A,$A,$14,$A,$28
	db $A,$A,$0
trackb3	db $34,$0,$0,$0,$0,$0,$0,$0
	db $0,$0,$A,$A,$1,$1,$A,$A
	db $1,$1,$5,$5,$1,$1,$5,$5
	db $A,$A,$5,$5,$A,$5,$A,$5
	db $A,$3,$5,$5,$0,$32
drackb3	db $5,$28,$14,$28,$14,$28,$14,$14
	db $1E,$A,$50,$28,$50,$28,$50,$28
	db $28,$14,$28,$14,$28,$14,$28,$14
	db $28,$14,$28,$14,$1E,$1E,$1E,$1E
	db $1E,$14,$A,$28,$14,$0
trackc3	db $34,$0,$31
drackc3	db $5,$28,$0
trackd3	db $34,$18,$0,$C,$0,$83,$32
drackd3	db $5,$A,$A,$5,$5,$2,$0


;DIXIE2
tracka4	db $34,$14,$11,$D,$0,$D,$0,$D
	db $F,$11,$12,$14,$14,$14,$11,$11
	db $16,$16,$16,$14,$16,$14,$16,$18
	db $19,$1B,$1D,$19,$14,$19,$14,$11
	db $14,$F,$11,$D,$0,$14,$14,$19
	db $1D,$1B,$19,$16,$19,$16,$1B,$16
	db $1B,$14,$19,$1D,$1B,$19,$16,$18
	db $19,$16,$14,$11,$19,$11,$11,$F
	db $11,$D,$11,$F,$16,$14,$11,$19
	db $1D,$1B,$19,$11,$D,$11,$F,$16
	db $14,$11,$1D,$1B,$1B,$19,$0,$0
	db $32
dracka4	db $6,$6,$6,$6,$6,$6,$6,$6
	db $6,$6,$6,$C,$C,$C,$6,$6
	db $C,$C,$12,$6,$12,$6,$6,$6
	db $6,$6,$24,$6,$6,$24,$6,$6
	db $24,$6,$6,$18,$18,$6,$6,$C
	db $C,$C,$C,$C,$18,$C,$24,$C
	db $24,$C,$C,$C,$C,$C,$C,$C
	db $C,$C,$C,$C,$12,$6,$C,$18
	db $C,$24,$C,$24,$C,$C,$C,$12
	db $6,$C,$18,$C,$24,$C,$24,$C
	db $C,$C,$24,$6,$C,$18,$60,$30
	db $0
trackb4	db $34,$0,$0,$11,$11,$11,$0,$12
	db $12,$16,$12,$0,$12,$0,$0,$19
	db $0,$11,$0,$C,$0,$0,$0,$0
	db $12,$12,$13,$13,$12,$0,$0,$12
	db $12,$11,$0,$D,$C,$0,$0,$D
	db $C,$12,$11,$D,$11,$0,$12,$11
	db $0,$0,$D,$C,$12,$11,$0,$14
	db $12,$12,$11,$0,$0,$32
drackb4	db $6,$30,$C,$C,$C,$C,$C,$C
	db $6,$6,$12,$6,$12,$18,$6,$24
	db $C,$24,$C,$24,$C,$30,$C,$30
	db $24,$C,$24,$C,$24,$C,$30,$18
	db $18,$C,$24,$C,$18,$C,$24,$C
	db $24,$C,$C,$C,$12,$6,$C,$18
	db $C,$24,$C,$24,$C,$C,$C,$24
	db $6,$C,$18,$60,$30,$0
trackc4	db $34,$0,$31
drackc4	db $6,$30,$0
trackd4	db $34,$0,$31
drackd4	db $6,$30,$0


;CAMP
tracka5	db $34,$16,$0,$16,$0,$16,$0,$13
	db $16,$18,$16,$13,$0,$13,$11,$13
	db $11,$16,$0,$16,$0,$16,$0,$13
	db $16,$18,$16,$13,$0,$11,$13,$11
	db $F,$0,$81,$0,$F,$F,$13,$16
	db $1B,$0,$18,$18,$1B,$18,$16,$13
	db $14,$16,$16,$13,$13,$16,$16,$18
	db $16,$13,$11,$13,$14,$13,$11,$11
	db $F,$0,$32
dracka5	db $6,$7,$7,$7,$7,$7,$7,$E
	db $E,$E,$E,$E,$E,$E,$2A,$E
	db $1C,$7,$7,$7,$7,$7,$7,$E
	db $E,$E,$E,$E,$E,$1C,$E,$E
	db $1C,$E,$21,$E,$15,$7,$E,$E
	db $2A,$E,$15,$7,$E,$E,$2A,$7
	db $7,$E,$E,$7,$7,$7,$7,$E
	db $E,$1C,$E,$7,$7,$E,$7,$7
	db $2A,$70,$0
trackb5	db $34,$0,$F,$13,$A,$13,$F,$13
	db $F,$0,$A,$E,$A,$E,$0,$F
	db $13,$A,$13,$F,$13,$F,$0,$A
	db $E,$F,$81,$0,$13,$0,$16,$0
	db $F,$F,$0,$8,$0,$14,$0,$F
	db $3,$0,$F,$13,$A,$13,$F,$13
	db $F,$A,$D,$A,$D,$1B,$16,$F
	db $0,$32
drackb5	db $6,$E,$E,$E,$E,$E,$E,$E
	db $E,$E,$E,$2A,$E,$1C,$E,$E
	db $E,$E,$E,$E,$E,$E,$E,$E
	db $2A,$2A,$19,$E,$E,$E,$E,$E
	db $E,$1C,$E,$E,$E,$E,$E,$E
	db $1C,$E,$E,$E,$E,$E,$E,$E
	db $1C,$E,$E,$E,$E,$E,$E,$E
	db $70,$0
trackc5	db $34,$0,$31
drackc5	db $6,$38,$0
trackd5	db $34,$0,$6,$0,$9,$0,$6,$0
	db $97,$0,$0,$32
drackd5	db $6,$E,$7,$7,$7,$7,$7,$15
	db $6,$38,$2A,$0

	ENDIF

;STAND
tracka2	db $34,$0,$8B,$8,$0,$B,$0,$D
	db $0,$D,$0,$D,$0,$D,$0,$D
	db $0,$10,$0,$14,$0,$12,$0,$10
	db $0,$D,$D,$0,$0,$0,$0,$0
	db $E3,$0,$32
dracka2	db $0,$40,$1,$8,$8,$8,$8,$8
	db $8,$8,$8,$4,$4,$4,$4,$4
	db $4,$10,$8,$8,$8,$8,$8,$8
	db $8,$40,$18,$8,$40,$40,$40,$40
	db $1D,$8,$0
trackb2	db $34,$0,$8F,$14,$0,$12,$0,$10
	db $0,$10,$0,$10,$0,$10,$0,$10
	db $0,$12,$0,$8,$0,$B,$0,$D
	db $0,$D,$D,$0,$E3,$32
drackb2	db $0,$40,$1,$8,$8,$8,$8,$8
	db $8,$8,$8,$4,$4,$4,$4,$4
	db $4,$10,$8,$8,$8,$8,$8,$8
	db $8,$40,$18,$8,$19,$0
trackc2	db $34,$0,$87,$D,$0,$D,$0,$D
	db $0,$D,$0,$D,$0,$B,$0,$D
	db $0,$D,$0,$D,$0,$D,$0,$D
	db $0,$10,$0,$E3,$32
drackc2	db $0,$40,$1,$10,$8,$8,$8,$8
	db $8,$4,$4,$4,$C,$18,$18,$10
	db $8,$8,$8,$8,$8,$4,$4,$4
	db $C,$18,$18,$18,$0
trackd2	db $34,$2,$0,$0,$4,$0,$0,$2
	db $0,$3,$0,$4,$0,$6,$0,$A
	db $0,$32
drackd2	db $4,$4,$C,$10,$4,$C,$10,$4
	db $C,$4,$4,$4,$4,$4,$C,$4
	db $C,$0



;RAP
tracka3	db $34,$0,$0,$1F,$0,$0,$7,$0
	db $32
dracka3	db $7,$18,$18,$C,$C,$18,$C,$C
	db $0
trackb3	db $34,$1,$3,$5,$15,$3,$5,$7
	db $B,$5,$7,$9,$D,$32
drackb3	db $7,$18,$C,$C,$C,$18,$C,$C
	db $18,$18,$C,$C,$C,$0
trackc3	db $34,$0,$32
drackc3	db $0,$9,$0
trackd3	db $34,$13,$13,$0,$3,$0,$32
drackd3	db $7,$18,$18,$18,$18,$18,$0


;BEAT
tracka4	db $34,$7,$0,$13,$0,$84,$0,$1
	db $D,$13,$0,$13,$0,$84,$0,$1
	db $D,$32
dracka4	db $0,$4,$4,$4,$4,$4,$10,$8
	db $18,$4,$4,$4,$4,$4,$10,$8
	db $18,$0
trackb4	db $34,$8,$0,$14,$0,$84,$0,$12
	db $6,$8,$0,$14,$0,$84,$0,$8
	db $14,$32
drackb4	db $0,$4,$4,$4,$4,$4,$10,$8
	db $18,$4,$4,$4,$4,$4,$10,$8
	db $18,$0
trackc4	db $34,$0,$8,$0,$14,$9F,$32
drackc4	db $0,$4,$4,$4,$4,$4,$0
trackd4	db $34,$B,$0,$B,$0,$6,$0,$B
	db $0,$B,$0,$6,$0,$32
drackd4	db $0,$8,$8,$8,$8,$8,$8,$8
	db $8,$8,$18,$8,$18,$0


;WIN SCREEN
tracka5	db $34,$11,$0,$F,$0,$12,$0,$F
	db $0,$1D,$1E,$20,$0,$20,$20,$22
	db $20,$1E,$25,$1D,$1D,$1B,$1B,$19
	db $32
dracka5	db $2,$20,$20,$20,$20,$20,$20,$20
	db $20,$10,$10,$8,$8,$20,$8,$8
	db $20,$20,$20,$10,$10,$8,$8,$10
	db $0
trackb5	db $34,$D,$0,$C,$0,$D,$0,$C
	db $0,$D,$0,$C,$0,$D,$0,$C
	db $0,$14,$14,$16,$14,$14,$16,$14
	db $14,$16,$14,$F,$12,$11,$32
drackb5	db $2,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$10,$10,$20,$10,$10,$20
	db $10,$10,$10,$10,$10,$10,$0
trackc5 db $34,$14,$14,$12,$14,$14,$14,$14
	db $0,$14,$0,$14,$0,$16,$16,$0
	db $16,$0,$16,$0,$18,$18,$0,$18
	db $0,$18,$0,$32
drackc5	db $0,$40,$40,$40,$40,$40,$10,$8
	db $8,$8,$8,$8,$8,$10,$8,$8
	db $8,$8,$8,$8,$10,$8,$8,$8
	db $8,$8,$8,$0
trackd5	db $34,$A,$0,$34,$1,$3,$5,$6
	db $8,$9,$8,$34,$6,$0,$8,$0
	db $32
drackd5	db $4,$4,$4,$3,$8,$10,$10,$10
	db $10,$10,$10,$4,$4,$4,$4,$4
	db $0


;  END OF DB FILE



; TRACK ADDRESS TABLE TO SELECT WHICH SONG TO PLAY
; PLACE THE NUMBERED TRACK LABELS FROM ABOVE, INTO THIS TABLE FOR SELECTION

trsela	dw tracka1,tracka2,tracka3,tracka4,tracka5
drsela	dw dracka1,dracka2,dracka3,dracka4,dracka5

trselb	dw trackb1,trackb2,trackb3,trackb4,trackb5
drselb	dw drackb1,drackb2,drackb3,drackb4,drackb5

trselc	dw trackc1,trackc2,trackc3,trackc4,trackc5
drselc	dw drackc1,drackc2,drackc3,drackc4,drackc5

trseld	dw trackd1,trackd2,trackd3,trackd4,trackd5
drseld	dw drackd1,drackd2,drackd3,drackd4,drackd5

;trsela	dw tracka1,tracka2
;drsela	dw dracka1,dracka2

;trselb	dw trackb1,trackb2
;drselb	dw drackb1,drackb2

;trselc	dw trackc1,trackc2
;drselc	dw drackc1,drackc2

;trseld	dw trackd1,trackd2
;drseld	dw drackd1,drackd2


;======================================
repeat
	bpl ?rts
	and #$7f
	beq ?rts	;repeat count of zero error
	sta tmp+1	;save repeat count
	lda rptcnt,x
	bne ?rept	;already repeating
	lda tmp+1
	sta rptcnt,x
?backup	tya
	sec
	sbc tmp
	tay
	rts

?rept	dec rptcnt,x
	bne ?backup
	iny
?rts	rts

;======================================

sng0

?repeat
	ldy savey0

?notes
	lda (dracka),y
	sta tmp
	lda (tracka),y
	jsr repeat
	lda (tracka),y

	cmp #52
	bne ?noti
	sty tmp+1
	ldy tmp
	jsr ichannel0
	ldy tmp+1
	iny
	jmp ?notes
?noti
	cmp #49
	beq ?songend
	cmp #50
	bne ?norept
	ldy #0
	jmp ?notes
?norept

	lda (tracka),y

	asl a
	tax
	lda notetab,x
	sta s2
	inx
	stx tmp

	ldx envdur0
	lda envdurtbl,x
	ldx tmp
	ora notetab,x
	sta s3

	lda (dracka),y
	iny

	sty savey0
	sta twaits0
	rts
?songend
	lda #0
	sta s2
	sta s3
	lda #$ff
	sta twaits0
	rts


;======================================

sng1

?repeat
	ldy savey1

?notes
	lda (drackb),y
	sta tmp
	lda (trackb),y
	jsr repeat
	lda (trackb),y

	cmp #52
	bne ?noti
	sty tmp+1
	ldy tmp
	jsr ichannel1
	ldy tmp+1
	iny
	jmp ?notes
?noti
	cmp #49
	beq ?songend
	cmp #50
	bne ?norept
	ldy #0
	jmp ?notes
?norept

	lda (trackb),y

	asl a
	tax
	lda notetab,x
	sta s6
	inx
	stx tmp

	ldx envdur1
	lda envdurtbl,x
	ldx tmp
	ora notetab,x
	sta s7

	lda (drackb),y
	iny

	sty savey1
	sta twaits1
	rts
?songend
	lda #0
	sta s6
	sta s7
	lda #$ff
	sta twaits1
	rts


;======================================

sng2

?repeat
	ldy savey2

?notes
	lda #$ff
	sta s8
	lda envr2
	bne ?constant
	lda #$7f
	sta s8
?constant
	lda (drackc),y
	sta tmp
	lda (trackc),y
	jsr repeat
	lda (trackc),y
	beq ?silence

	cmp #52
	bne ?noti
	sty tmp+1
	ldy tmp
	jsr ichannel2
	ldy tmp+1
	iny
	jmp ?notes
?noti
	cmp #49
	beq ?songend
	cmp #50
	bne ?norept
	ldy #0
	jmp ?notes
?norept

	lda (trackc),y

	asl a
	tax
	lda notetab,x
	sta sa
	inx
	stx tmp

	ldx envdur2
	lda envdurtbl,x
	ldx tmp
	ora notetab,x
	sta sb
	jmp ?nosilent
?silence

	lda (trackc),y
	sta sa
	sta sb
	sta s8
?nosilent
	lda (drackc),y
	iny

	sty savey2
	sta twaits2
	rts
?songend
	lda #0
	sta sa
	sta sb
	lda #$ff
	sta twaits2
	rts


;======================================

sng3

?repeat
	ldy savey3

?notes
	lda envr3
	asl a

	ora decay3
	asl a
	asl a
	asl a
	asl a

	ora decayr3
	sta sc

	lda (drackd),y
	sta tmp
	lda (trackd),y
	jsr repeat
	lda (trackd),y
	beq ?silence

	cmp #52
	bne ?noti
	sty tmp+1
	ldy tmp
	jsr ichannel3
	ldy tmp+1
	iny
	jmp ?notes
?noti
	cmp #49
	beq ?songend
	cmp #50
	bne ?norept
	ldy #0
	jmp ?notes
?norept

	lda ntype3
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	ora (trackd),y
	sta se

	ldx envdur3
	lda envdurtbl,x
	sta sf
	jmp ?nosilent
?silence
	lda #0

	sta se
	sta sf
	lda #$10
	sta sc
?nosilent
	lda (drackd),y
	iny

	sty savey3
	sta twaits3
	rts
?songend
	lda #0
	sta se
	sta sf
	lda #$10
	sta sc
	lda #$ff
	sta twaits3
	rts


;======================================

ichannel0
	lda iwave0,y
	asl a

	ora ienvr0,y
	asl a

	ora idecay0,y
	asl a
	asl a
	asl a
	asl a

	ora idecayr0,y
	sta s0

	lda #4
	sta s1
	lda isweep0,y
	beq ?nosweep

	lda #%00001000
	ora isweepr0,y
	asl a
	ora iswedir0,y
	asl a
	asl a
	asl a
	ora isweeps0,y
	sta s1
?nosweep
	lda ifreqlo0,y
	sta s2

	lda ienvdur0,y
	sta envdur0

	sty tmp
	tay

	lda envdurtbl,y

	ldy tmp

	ora ifreqhi0,y
	sta s3

	rts

;======================================

ichannel1
	lda iwave1,y
	asl a

	ora ienvr1,y
	asl a

	ora idecay1,y
	asl a
	asl a
	asl a
	asl a

	ora idecayr1,y
	sta s4

	lda #4
	sta s5
	lda isweep1,y
	beq ?nosweep

	lda #%00001000
	ora isweepr1,y
	asl a
	ora iswedir1,y
	asl a
	asl a
	asl a
	ora isweeps1,y
	sta s5
?nosweep
	lda ifreqlo1,y
	sta s6

	lda ienvdur1,y
	sta envdur1

	sty tmp
	tay

	lda envdurtbl,y

	ldy tmp

	ora ifreqhi1,y
	sta s7

	rts

;======================================

ichannel2
	lda #$ff
	sta s8
	lda ienvr2,y
	sta envr2
	bne ?constant
	lda #$7f
	sta s8
?constant
	lda ifreqlo2,y
	sta sa

	lda ienvdur2,y
	sta envdur2

	sty tmp
	tay

	lda envdurtbl,y

	ldy tmp

	ora ifreqhi2,y
	sta sb

	rts

;======================================

ichannel3
	lda ienvr3,y
	sta envr3
	asl a

	ora idecay3,y
	asl a
	asl a
	asl a
	asl a

	ora idecayr3,y
	sta sc

	lda idecay3,y
	sta decay3
	lda idecayr3,y
	sta decayr3

	lda intype3,y
	sta ntype3
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	asl a
	ora imfreq3,y
	sta se

	lda ienvdur3,y
	sta envdur3
	sty tmp
	tay

	lda envdurtbl,y

	ldy tmp
	sta sf

	rts

;===============================================

envdurtbl
	db $18
	db $28
	db $38
	db $48
	db $58
	db $68
	db $78
	db $88
	db $98
	db $a8
	db $b8
	db $c8
	db $d8
	db $e8
	db $f8

	db $f0
	db $20
	db $a0
	db $50
	db $d0
	db $30
	db $b0
	db $40
	db $c0
	db $08

;===============================================
; Note Table -- contains Nintendo equivalent frequency for notes
;   Defined notes are: 

; C#,Ebb,D#,F#,G#,Bbb,A# removed by OBE

;	C, C#, Db, D, Ebb, D#, Eb, E, F, F#, Gb, G, G#, Ab, A, Bbb, A#, Bb, B

notetab dw	0		;this is a rest

	;starting with C at 2 octaves below middle C
	dw	1113,1036,994,921,888,838
	dw	785,738,697,666,627,592

	;starting with C at 1 octave below middle C
	dw	557,521,500,463,447,419
	dw	392,371,348,334,313,297

	;middle C
	dw	278,261,250,232,223,209
	dw	196,186,174,167,157,149

	;C at 1 octave above middle C
	dw	139,130,125,116,111,104
	dw	98,93,87,83,78,74

;===========================================================================
; End of sound module
;===========================================================================

	end
