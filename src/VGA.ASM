;  Example on how to use Methods for Turbo Pascal in Assembler
;  using 80386 instructions.


; Set up Pascal Model of Calling Conventions

IDEAL
MODEL TPASCAL

; Enable 386 Instructions

P386N

; Declare public variables which will be used (Data Segment)


DATASEG

EXTRN SegA000: WORD


; Declare Code (Code Segment)
; Self parameter as always passed as a parameter in an Object

CODESEG


PROC TVideo@ClearScreen FAR Self: DWORD
 PUBLIC TVideo@ClearScreen
 MOV EAX, 0000h
 LES DI, [Self]       ; (* Load Pointer to Object    *)
 MOV DL, 00h
 MOV DH, DL
 ROR EAX, 16
 MOV AX, DX
 ROR EAX, 16
 MOV AX, DX
 XOR DI, DI
 MOV ES, [SegA000]
 CLD
 MOV ECX, 16000
 REP STOSD
 RET
 ENDP

ENDS      ; (* End of Code Segment *)
END

