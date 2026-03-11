        cpu 7508
        org 0
	JMP	init

DLY_REG1		equ	010h
DLY_REG2		equ  011h
DLY_REG3		equ  012h
DLY_REG4		equ  013h


TEMP1		equ  014h
TEMP2		equ  015h
TEMP3		equ  016h

DISPVAL1		equ  020h
DISPVAL2		equ  021h
DISPVAL3		equ  022h

CNT1		equ	030h

SUBTMP1		equ	017h	; sub_rt

SUBARG1L	equ	018h
SUBARG1H	equ	019h
SUBARG3L	equ	01Ah
SUBARG3H	equ	01Bh

DIVARG1L		equ  01Ch
DIVARG1H	equ	01Dh
DIVRET_L		equ	01Eh
DIVRET_H		equ	01Fh
DIVMOD_L	equ	023h
DIVMOD_H	equ	024h
DIVARG2L		equ  025h

ADCVAL_H	equ	032h
ADCVAL_L		equ	031h

	org 40h
init:
	; Register clear
	LAI	0
	LDEI	0
	LHLI	0

	; P5_0 = #CS, P6_0 = #EOC. Others = N.C.
	LAI	0
	OP	4
	OP	5
	OP	6

	OP	0	; ADC port

	; LED port
	LAI	0Ah
	OP3

	; DIP Switch port
	IP	1
	
	; Display LED port
	LAI	0Fh
	OP	2

	LAI	1
	OP	7
main:  
	LAI 0
	LDEI	0	; DE <- 0x00  

	RC			; Reset carry

	; Set stack pointer SP = 0xDE
	LHLI	TEMP1	; Set HL = TEMP1 addr
	LAI	0Fh
	ST			; (TEMP1) <- 0xF
	LAI	0Dh
	TAMSP		; Stack pointer <- A & (HL)[3:1] & 0 = 0xDE

	; Clear RAM val TEMP1, TEMP2, TEMP3
	LAI	0
	XADR	(TEMP1)
	LAI	0
	XADR	(TEMP2)
	LAI	0
	XADR	(TEMP3)
	LAI	0
	XADR	(SUBTMP1)
	LAI	0
	XADR	(ADCVAL_H)
	LAI	0
	XADR	(ADCVAL_L)

	; Clear RAM val
	LAI	0
	XADR	(SUBARG1L)
	LAI	0
	XADR	(SUBARG1H)
	LAI	0
	XADR	(SUBARG3L)
	LAI	0
	XADR	(SUBARG3H)


	
	; Clear RAM val DISPVAL1, DISPVAL2, DISPVAL3
	; display '-'
	LAI	0Dh
	XADR	(DISPVAL1)
	LAI	0Dh
	XADR	(DISPVAL2)
	LAI	0Dh
	XADR	(DISPVAL3)

	; Clear RAM val CNT1
	LAI	01h
	XADR	(CNT1)

	call	disp_num_to_led_100

	; Set initial LED
	LADR	(CNT1)
	OP3

loop:
	; LED count-up
	IDRS		(CNT1)	; +1
	nop				; skip if overflow

	LADR	(CNT1)	; A <- ++i
    	OP3         			; P3 <- A

ADC_conv:
	; Set #CS (#CS = 0)
	LAI	01h
	OP	5

	; ADC conversion time
	; call	delay		; wait for ADC
	
	; Wait until P6_0 = #EOC is on
eoc_wait_lp:
	IP 6
	CMA
	SKABT 0	; if A_0 = 1 (P6_0 = 0)
	JMP	eoc_wait_lp

	; Clear #CS
	LAI 00h
	OP 5

	; Prepare SPI
	LAI	06h
	OP	0Fh	; Set 

	; set SPI sending data
	LHLI	TEMP1	; Set HL = TEMP1 addr
	LAI	00h		; Transfer data 0x0
	ST			; (TEMP1) <- A = 0x0

	LAI 00h		; A <- 0x0

	TAMSIO		; SIO		<- (HL) & A

	; Start SPI transfer
	SIO

	; Wait until transfer is completed
wait_spi_tr:
	SKI	2
	JCP	wait_spi_tr

	; Receive SPI data
	LHLI	TEMP3	; Set HL = TEMP1 addr
	TSIOAM

	; Save data
	LHLI	ADCVAL_H
	ST

	LADR		(TEMP3)
	LHLI	ADCVAL_L
	ST

ADC_end:
	; Set #CS (#CS = 0)
	LAI	01h
	OP	5

debug_disp:


process_recv_val:

div_ADCval_5:

	LHLI	DIVARG2L
	LAI	5
	ST

	LADR	(ADCVAL_L)	
	XADR	(DIVARG1L)

	LADR	(ADCVAL_H)
	XADR	(DIVARG1H)

	call	div84_rt

	LADR	(DIVMOD_L)

rotate_left_digt:
	; rotate left
	RC
	RAR		; C A3 A2 A1 (C = A0)
	RAR		; A0 C A3 A2 (C = A1)
	RAR		; A1 A0 C A3 (C = A2)
	RAR		; A2 A1 A0 C (C = A3)

	; set display
	LHLI	DISPVAL3		; set HL addr
	ST

div_ADCval_10:
	
	LHLI	DIVARG2L
	LAI	0Ah
	ST

	LADR	(DIVRET_L)	
	XADR	(DIVARG1L)

	LADR	(DIVRET_H)
	XADR	(DIVARG1H)

	call	div84_rt

	LHLI	DISPVAL2
	LADR	(DIVMOD_L)
	ST

	LHLI	DISPVAL1
	DDRS	(DIVRET_L)
	nop
	LADR	(DIVRET_L)
	ST

	call disp_num_to_led_100
	
    call delay2
    call delay2
    call delay2


    JMP  loop

disp_num_to_led_100:

	; Latch on-off
	; Left LED Latch = en
	LAI	06h
	OP	2

	; Dispval1 -> 100 
	LADR	(DISPVAL1)
	OP	7

	LAI   07h
	OP	2

	LAI   05h
	OP	2

	LADR	(DISPVAL2)
	OP	7

	LAI   07h
	OP	2

	LAI	03h
	OP	2

	LADR	(DISPVAL3)
	OP	7

	LAI 07h
	OP	2

	RT

; A <- D - E
sub_4D_4E_rt:
	; 2's complement
	TEA		; A <- E
	CMA		; ~A

	LHLI	SUBTMP1	; set HL SUBTMP1
	ST		; (HL) <- A = (~E)

	TDA		; A <- D

	SC		; Set carry	

	ACSC	; A <- A + (HL) + C = D + (~E) + 1. skip if carry
	JCP	sub_4D_4E_borrow		; skip if overflow

sub_4D_4E_noborrow:
	RC	; Carry = 0
	RT

sub_4D_4E_borrow:
	SC	; Carry = 1
	RT

; SUBARG3H & SUBARG3L = SUBARG1H & SUBARG1L - E
sub84_rt:
	; init
	LAI	0
	LHLI		SUBARG3L
	ST
	LHLI		SUBARG3H
	ST

	; load 
	LADR	(SUBARG1L)
	TAD

; Debug

	; A <- D - E
	call	sub_4D_4E_rt
	
	; (SUBARG3L)	<- A = D - "
	LHLI		SUBARG3L
	ST			

	; if Carry	: mid-borrow
	SKC
	JMP	sub84_nomidborrow	; skip if C = 1
	JMP	sub84_midborrow

	; if not Carry : no mid-borrow
sub84_nomidborrow:
	; (SUBARG3H) <- (SUBARG1H)
	LADR	(SUBARG1H)
	LHLI		SUBARG3H
	ST

	RC

	RT	

sub84_midborrow:
	; (SUBARG1H) <- (SUBARG1H) - 1
	DDRS	(SUBARG1H)		
	JMP	sub84_noborrow; if not borrow

sub84_borrow:
	; (SUBARG3H) <- (SUBARG1H)
	LADR	(SUBARG1H)
	LHLI		SUBARG3H
	ST
	
	; Set carry
	SC		

	RT

sub84_noborrow:
	; (SUBARG3H) <- (SUBARG1H)
	LADR	(SUBARG1H)
	LHLI		SUBARG3H
	ST					

	; Reset carry
	RC		

	RT

div84_rt:
	LAI	0
	LHLI		DIVRET_L
	ST
	LHLI		DIVRET_H
	ST
	LHLI		DIVMOD_L
	ST
	LHLI		DIVMOD_H
	ST

	LADR	(DIVARG1L)
	LHLI		SUBARG1L
	ST

	LADR	(DIVARG1H)
	LHLI		SUBARG1H
	ST

	; if 2L = 0 then RT
	LADR	(DIVARG2L)
	TAE
	
	SKAEI	0
	JMP	div84_loop		; skip if A = 0

div84_zerodiv:
	RT

div84_loop:
	call	sub84_rt

	SKC	
	JMP	div84_noborrow

div84_borrow:
	LADR	(SUBARG1L)
	LHLI		DIVMOD_L
	ST

	LADR	(SUBARG1H)
	LHLI		DIVMOD_H
	ST

	RT

div84_noborrow:
	LADR	(SUBARG3H)
	LHLI		SUBARG1H
	ST

	LADR	(SUBARG3L)
	LHLI		SUBARG1L
	ST
	
	IDRS		(DIVRET_L)
	JMP	div84_nocarry		; skip if overflow

div84_carry:
	IDRS		(DIVRET_H)	
	nop
div84_nocarry:
	JMP	div84_loop
	
delay2:
	XAE	; A -> E
	PSHDE

dly_init_ram:
	LAI	0
	XADR	(DLY_REG4)
dly_loop4:
	LAI	0
	XADR	(DLY_REG3)
dly_loop3:
	LAI	0
	XADR	(DLY_REG2)
dly_loop2:
	LAI	0				; 1 cycle 
	XADR	(DLY_REG1)	; 2 cycles
dly_loop1:
	IDRS		(DLY_REG1)	; 2 cycles x 16
	JMP		dly_loop1		; 2 cycles x 15
	IDRS		(DLY_REG2)
	JMP		dly_loop2
	IDRS		(DLY_REG3)
	JMP		dly_loop3
;	IDRS		(DLY_REG4)
;	JMP		dly_loop4

	POPDE
	XAE	; E -> A

	RT

        end
