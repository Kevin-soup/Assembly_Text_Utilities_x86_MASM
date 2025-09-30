Assembly Text Utilities (x86, MASM)  

; Author: Kevin Lin
; Last Modified: 03/12/2025
; Description: This program stores temperature measurements from a file, convert each ASCII character into signed 
;	integers, and then prints them out in reverse order. Scenerio: an intern recording thermometer data messed up. 
;	The readings are good, but the order is reversed. This program was designed to correct the issue.


INCLUDE Irvine32.inc

;--------------------------------------------------------------------------------------------
; Name: mGetString
;
; Description: Display a prompt and then get the user’s keyboard input into a memory location.
;	 
; Precondition: none.
;
; Postcondition: none.
;
; Recieves:
;	promptOff	= OFFSET prompt.
;	inputOff	= OFFSET user input.  
;	strLength	= length of input string.
;	countOff	= number of bytes read by the macro.
;
; Returns: 
;	inputOff	= generated string array from user input. 
;	promptOff	= number of bytes inputed by user.
;--------------------------------------------------------------------------------------------
mGetString MACRO promptOff:REQ, inputOff:REQ, strLength:REQ, countOff:REQ
	push	EAX
	push	ECX
	push	EDX
	
	; Print prompt.
	mDisplayString	promptOff 
	
	; Get user input.
	mov		EDX, inputOff
	mov		ECX, strLength
	call	ReadString
	mov		[countOff], EAX
	
	; Exit mGetString macro.
	pop		EDX
	pop		ECX
	pop		EAX	
ENDM

;--------------------------------------------------------------------------------------------
; Name: mDisplayString
;
; Description: Print the string which is stored in a specified memory location.
;
; Precondition: none.
;
; Postcondition: none.
;
; Recieves:
;	stringOff	= string address.  
;
; Returns: none.
;--------------------------------------------------------------------------------------------
mDisplayString MACRO stringOff:REQ
	push	EDX

	; Print String.
	mov		EDX, stringOff
	call	WriteString
	
	; Exit mDisplayString macro.
	pop		EDX
ENDM


;--------------------------------------------------------------------------------------------
; Name: mDisplayChar
;
; Description: Print an ASCII-formatted character.
;	 
; Precondition: Provided character must be an immediate or constant.
;
; Postcondition: none.
;
; Recieves:
;	ascChar		= ASCII character.
;
; Returns: none.
;--------------------------------------------------------------------------------------------
mDisplayChar MACRO ascChar:REQ 
	push	EAX

	; Print character.
	mov		AL, ascChar
	call	WriteChar
	
	; Exit mDisplayChar macro.
	pop		EAX
ENDM


	TEMPS_PER_DAY	= 24
	DELIMITER		EQU <","> 
	STRING_LENGTH	= 30
	NEGATIVE		EQU <"-"> 
	MULTIPLE_LINE	= 11


.data

	title1		BYTE	"               Welcome to the Intern Error-Corrector!        by Kevin Lin", 13, 10, 0
	intro1 		BYTE	"This program reverses the ordering of temperature values from any ',' -delimited file.", 13, 10, 0
	intro2 		BYTE	"Keep in mind that files must be ASCII-formatted! ", 13, 10, 0
	prompt1 	BYTE	"Enter the name of the file to be read: ", 0
	disMsg 		BYTE	"Here are the temperatures in order!", 13, 10, 0
	errorMsg 	BYTE	"    Invalid file input. Please try again!", 13, 10, 0
	farewell 	BYTE	"Hope that helps resolve the issue, goodbye!", 13, 10, 0
	extra1		BYTE	"** EC1: Program is able to handle multiple-line input files.", 13, 10, 0
	extra2		BYTE	"** EC2: Program implements a WriteVal procedure rather than using WriteInt.", 13, 10, 0
	userInput	BYTE	STRING_LENGTH DUP(?)							; Store user input. File header.
	inputCount 	DWORD	0												; Number of characters from user input.
	fileBuffer	BYTE	TEMPS_PER_DAY * 4 * MULTIPLE_LINE DUP(?)		; File buffer memory location.
	bufferByte	DWORD	0												; Number of bytes read from file buffer.
	bufferCount	DWORD	0												; Track number of bytes parsed in file buffer.	
	tempString	BYTE	8 DUP(?)										; Store string converted from integer value.
	strPrint	BYTE	8 DUP(?)										; Store reveresed string from WriteVal.
	tempArray 	SDWORD	?												; Store converted temperatures from file.


.code
main PROC

	; Program header.
	mDisplayString	OFFSET title1 
	call	CrLf
	mDisplayString	OFFSET intro1
	mDisplayString	OFFSET intro2
	call	CrLf
	mDisplayString	OFFSET extra1
	mDisplayString	OFFSET extra2
	call	CrLf

	; Get user input.
	mGetString		OFFSET prompt1, OFFSET userInput, STRING_LENGTH, OFFSET inputCount

	; Open input file. 
	mov		EDX, OFFSET userInput
	call	OpenInputFile											
	cmp		EAX, INVALID_HANDLE_VALUE									; Check for valid file.	
	jne		_fileValid
	call	CrLf
	mDisplayString  OFFSET errorMsg												
	jmp		_exitMain													; Exit program on invalid input. 	

	; Read file.
_fileValid:
	mov		ECX, TEMPS_PER_DAY * 4 * MULTIPLE_LINE 
	mov		EDX, OFFSET fileBuffer
	call	ReadFromFile 
	mov		bufferByte, EAX

	; Print display message. 
	call	CrLf
	mDisplayString	OFFSET disMsg										
	call	CrLf

	; Convert string from file to integer.	
_multiLine:
	push	OFFSET bufferCount
	push	OFFSET tempArray
	push	OFFSET fileBuffer
	call	ParseTempsFromString

	; Print temperatures in reverse order.
	push	OFFSET tempString
	push	OFFSET strPrint
	push	OFFSET tempArray
	call	WriteTempsReverse
	call	CrLf

	; EC1: Handle file with multiple lines.
	mov		EAX, bufferByte
	mov		EBX, bufferCount
	cmp		EAX, EBX
	jg		_multiLine

	; Print farewell.
	call	CrLf
	mDisplayString	OFFSET farewell 
	call	CrLf

_exitMain:

	Invoke ExitProcess,0	
main ENDP


;--------------------------------------------------------------------------------------------
; Name: ParseTempsFromString
;
; Description: Convert the string of ascii-formatted numbers to their numeric value representations. 
;	 
; Precondition: none.
;
; Postcondition: none.
;
; Recieves:
;	[EBP + 16]	= OFFSET bufferCount.
;	[EBP + 12]	= OFFSET tempArray.
;	[EBP + 8]	= OFFSET fileBuffer.
;
; Returns: 
;	tempArray	= Array of recorded temperatures. 
;	bufferCount	= Number of bytes parsed in file buffer.	
;--------------------------------------------------------------------------------------------
ParseTempsFromString PROC
	LOCAL	signValue: DWORD, ptrValue: DWORD	
	push	EAX
	push	EBX
	push	ECX
	push	EDX
	push	EDI
	push	ESI

	; Set up local variable.
	mov		EAX, [EBP + 16]												
	mov		EBX, [EAX]		
	mov		ptrValue, EBX												; ptrValue = value of bufferCount.	
	mov		signValue, 0

	; Set up register.	
	mov		EDI, [EBP + 12]												; EDI = address of tempArray.	
	mov		ESI, [EBP + 8]
	add		ESI, ptrValue												; ESI = address of fileBuffer + bufferCount.	
	mov		EAX, 0
	mov		EBX, 0
	mov		ECX, 0				
	mov		DL, 10

	; Load value from fileBuffer.
	cld
_parseLoop:
	lodsb
	inc		ptrValue
	cmp		AL, NEGATIVE												; Check value for negative sign.
	je		_trackSign
	cmp		AL, DELIMITER												; Check value for delimiter.
	je		_beginStore

	; Convert ASCII to integer.
	sub		AL, 48
	movsx	EAX, AL
	xchg	EAX, EBX
	mul		DL
	add		EBX, EAX
	jmp		_parseNext

	; Handle negative sign.
_trackSign:
	mov		signValue, 1												; Negative sign = 1. Postive sign = 0.
	jmp		_parseNext

	; Store value to tempArray.
_beginStore:
	mov		EAX, EBX
	cmp		signValue, 1
	jne		_storeValue

_negateValue:
	neg		EAX															; Convert value to negative if needed.

_storeValue:
	stosd
	xor		EAX, EAX													; Reset register.
	xor		EBX, EBX
	mov		signValue, 0												; Reset signValue.
	inc		ECX
	cmp		ECX, TEMPS_PER_DAY
	je		_exitParse

	; Loop through all values.
_parseNext:
	jmp		_parseLoop

	; Exit ParseTempsFromString procedure.
_exitParse:
	add		ptrValue, 2
	mov		EAX, ptrValue
	mov		EBX, [EBP + 16]	
	mov		[EBX], EAX													; Replace bufferCount with new ptrValue.

	pop		ESI
	pop		EDI
	pop		EDX
	pop		ECX
	pop		EBX
	pop		EAX
	ret		12
ParseTempsFromString ENDP


;--------------------------------------------------------------------------------------------
; Name: WriteTempsReverse
;
; Description: Print integers in the array in reverse order.
;	 
; Precondition: The array must be type DWORD or SDWORD.
;
; Postcondition: none.
;
; Recieves:
;	[EBP + 16]	= OFFSET tempString
;	[EBP + 12]	= OFFSET strPrint
;	[EBP + 8]	= OFFSET tempArray
;
; Returns: none. 
;--------------------------------------------------------------------------------------------
WriteTempsReverse PROC
	push	EBP
	mov		EBP, ESP
	push	EAX
	push	EBX
	push	ECX
	push	ESI

	; Set up register.
	mov		ESI, [EBP + 8]												; ESI = address of tempArray.	
	mov		ECX, TEMPS_PER_DAY										
	mov		EAX, ECX
	dec		EAX
	mov		EBX, 4
	mul		EBX
	add		ESI, EAX													; ESI = address of last value in tempArray.

	; Print temperature.
_loopArray:
	std
	lodsd
	push	[EBP + 16]
	push	[EBP + 12]
	push	EAX
	call	WriteVal													; call EC2 WriteVal subprocedure.
	mDisplayChar	DELIMITER												
	loop	_loopArray

	; Exit WriteTempsReverse procedure.
	pop		ESI
	pop		ECX
	pop		EBX
	pop		EAX
	pop		EBP
	ret		12
WriteTempsReverse ENDP


;--------------------------------------------------------------------------------------------
; Name: WriteVal
;
; Description: Converts a positive or negative integer value into an ASCII-formatted string 
;	representation. Then prints the string to the terminal.
;	 
; Precondition: none.
;
; Postcondition: none.
;
; Recieves:.
;	[EBP + 16]	= OFFSET tempString
;	[EBP + 12]	= OFFSET strPrint
;	[EBP + 8]	= EAX - integer value.
;
; Returns: 
;	tempString	= String of converted integers.
;	strPrint	= String to print to terminal.	
;--------------------------------------------------------------------------------------------
WriteVal PROC
	LOCAL	negSign: DWORD
	push	EAX
	push	EBX
	push	ECX
	push	EDX
	push	EDI
	push	ESI

	; Set up register to convert integer.
	mov		EDI, [EBP + 16]												; EDI = address of tempString.
	mov		EAX, [EBP + 8]												; EAX = integer value from tempArray.	
	mov		EBX, 10
	mov		ECX, 0
	mov		negSign, 0

	; Handle negative sign.
	cmp		EAX, 0
	jl		_negativeSign
	jmp		_integerLoop

_negativeSign:
	mov		negSign, 1													; Track negative integers.
	neg		EAX

	; Convert integer to ASCII.
_integerLoop:
	xor		EDX, EDX
	div		EBX
	add		EDX, 48

	; Store string.
	mov		[EDI], EDX												
	inc		EDI
	inc		ECX
	cmp		EAX, 0
	jne		_integerLoop

	; Set up register to reverse string.
	mov		ESI, [EBP + 16]
	add		ESI, ECX													
	dec		ESI															; ESI =	address of last value in tempString.
	mov		EDI, [EBP + 12]												; EDI = address of strPrint.

	; Store integer sign.
	cmp		negSign, 1
	je		_negSign
	mov		EAX, 43														; Store positive sign.
	jmp		_addSign
_negSign:
	mov		EAX, 45														; Store negative sign.
_addSign:
	mov		[EDI], EAX
	inc		EDI
	
	; Reverse string.
_reverseLoop:
	std
	lodsb
	cld
	stosb																; Store ASCII characters in strPrint.
	loop	_reverseLoop

	; Print string.
	mDisplayString	[EBP + 12]

	; Exit WriteVal procedure.
	pop		ESI
	pop		EDI
	pop		EDX
	pop		ECX
	pop		EBX
	pop		EAX
	ret		12
WriteVal ENDP


END main

