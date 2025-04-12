; This 8051 program toggles Port 1.0 pin in every 1000 machine cycles on an average 

ORG 0000H          ; Origin, start address for the code
AJMP MAIN          ; Jump to the main program
ORG 000BH          ; Timer 0 interrupt vector location
AJMP TIMER0_ISR    ; Jump to Timer 0 Interrupt Service Routine (ISR)

MAIN:              		  ; Start of the main program
	MOV TMOD, #01H        ; Set Timer 0 in mode 1 (16-bit timer mode)
    SETB ET0              ; Enable Timer 0 interrupt
    SETB EA               ; Enable global interrupts
	MOV R1, #0FCH		  ; Reload value for TH0 (explained later)
	MOV R0, #01BH		  ; Reload value for TL0 (explained later)
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
	PUSH 0E0H		      ; Push A (mem address 0E0H) to stack before A is modified in subsequeer0 ISR operations.
    INC R7				  ; Increment R7 each time Timer0 ISR is executed to keep a count of it
    MOV TH0, R1           ; Reload initial high byte value for the delay
	MOV A, R0			  ; R0 has #18H + #3 = #1BH; A <- #1BH
	CLR TR0               ; Freeze Timer 0 (TH0 and TL0 vlaues are frozen here), time spent in frozen state in this and the following to instructions
						  ; = 1 (CLR) + 1 (ADD) + 1 (MOV) = 3 machine cycles
	ADD A, TL0			  ; A <- A + (TL0)  (the value in TL0 in frozen state - accounting for the extra time used before reaching here)
    MOV TL0, A            ; Restart value of TH0,TL0 should be #10000H - #1000 (in decimal) + #3 (time in frozen state) = #0FC1BH 
						  ; => Restart values TH0 = #0FCH, and that of TL0 = #1BH.
	SETB TR0              ; Restart Timer 0
    CPL P1.0              ; Toggle P1.0 pin
	POP 0E0H
    RETI                  ; Return from interrupt
END                       ; End directive