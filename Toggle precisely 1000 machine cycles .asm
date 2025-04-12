; This 8051 program toggles Port 1.0 pin precisely after every 1000 machine cycles. 

ORG 0000H          ; Origin, start address for the code
AJMP MAIN          ; Jump to the main program
ORG 000BH          ; Timer 0 interrupt vector location
AJMP TIMER0_ISR    ; Jump to Timer 0 Interrupt Service Routine (ISR)

MAIN:              		  ; Start of the main program
	MOV TMOD, #01H        ; Set Timer 0 in mode 1 (16-bit timer mode)
    SETB ET0              ; Enable Timer 0 interrupt
    SETB EA               ; Enable global interrupts
	MOV R1, #0FCH		  ; Reload value for TH0 (explained later)
	MOV R0, #041H		  ; Reload value for TL0 (explained later)
	MOV R7, #0			  ; Initialize R7, it will increment by one each time Timer0 ISR is executed 	
    SETB TR0              ; Start Timer 0
	SETB TF0			  ; Time 0 interrupt will be generated to call Timer0 ISR

Main_loop:
    ADD A, #45			  ; Do something
	MOV B, #33			  ; Do something
	MUL AB                ; Do something
	SETB C                ; Do something
	SJMP Main_loop        ; Infinite main program loop

; Timer 0 Interrupt Service Routine (ISR)
TIMER0_ISR:
	PUSH 0E0H		      ; Push A (mem address 0E0H) to stack before A is modified in subsequent Timer0 ISR operations.
    PUSH PSW			  ; Puse PSW to stack before C flag in it is modified in subsequent Timer0 ISR operations.
    INC R7				  ; Increment R7 each time Timer0 ISR is executed to keep a count of it
	CLR C 				  ; Cleared because C is involved in SUBB operation later
    MOV A, #20H			  ; (#20H-(TL0)) machine cycles will elapse during the time Timer0 is frozen below
	CLR TR0               ; Freeze Timer 0 (TH0 and TL0 vlaues are frozen here)
						  ; Another (#20H-(TL0)) machine cycles are spent during the time Timer0 is frozen
	SUBB A, TL0
	RRC A				  ; divide A by two, becauase each DJNZ execution used later requires two machine cycles, C carries remainder
Count_loop: 
	DJNZ 0E0H, Count_loop ; #20H - (TL0) machine cycles will be spent in this loop. 
	JNC Skip_NOP  
	NOP					  ; another extra machine cycle is spent here if TL0 was odd (indicated by C <> 0)
Skip_NOP: 
    MOV TH0, R1           ; Reload initial value high byte for a delay
    MOV TL0, R0           ; Add initial value low byte to TL0
	
	SETB TR0              ; Restart Timer 0, total time spent from freezing to unfreezing Timer0 
						  ; = #20H - (TL0) + 1 (CLR) + 1 (SUBB) + 1 (RRC) + 2 (JNC) + 2 + 2 (MOV + MOV) = #29H - (TL0)   
						  ; Therefore, restart value of TH0,TL0 should be #10000H + #29H - #1000 (in decimal) = #0FC18H + #29H - (TL0) 
						  ; => Restart values TH0 = #0FCH, and that of TL0 = #18H + #29H = #41H (which is used above for R0).
    CPL P1.0              ; Toggle P1.0 pin
	POP PSW
	POP 0E0H
    RETI                  ; Return from interrupt
END                       ; End directive