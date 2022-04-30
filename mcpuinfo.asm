; ======================================
; mcpuinfo.asm
;
; Turning the cpuid3a.asm sample, with tweaks, from the Intel AP-485 manual
; into a usable program for the MS-DOS operating system.
;
; Compile: nasm mcpuinfo.asm -fbin -omcpuinfo.com
; Author: dd86k <dd@dax.moe>
; ======================================

BITS	16	; Base is 16-bit code
CPU	386	; Contains mixed 16+32-bit code
ORG	100h	; Origin of CS:0100

%define	VERSION	'0.1.0'
%define	NL	13,10
%define	ENDSTR	'$'	; MS-DOS string terminator for AH=4Ch

section .text
start:
	mov	si,81h	; Start index of command-line (in PSP)
	call	skip_delim	; Skip to first token
	mov	bx,si	; Save delim position
	mov	di,opt_help	; Help switch string
	mov	cx,opt_helplen	; Help switch string length
repe	cmpsb
	jcxz	cli_help
	mov	si,bx	; Reset to start of token
	mov	di,opt_helpalt	; Alt help switch string
	mov	cx,opt_helpaltlen	; Alt help switch string length
repe	cmpsb
	jcxz	cli_help
	mov	si,bx	; Reset to start of token
	mov	di,opt_version	; Version switch string
	mov	cx,opt_versionlen	; Version switch string length
repe	cmpsb
	jcxz	cli_version
	mov	si,bx	; Reset to start of token
	mov	di,opt_ver	; Ver switch string
	mov	cx,opt_verlen	; Ver switch string length
repe	cmpsb
	jcxz	cli_ver
	jmp	check_8086

; Version string
cli_ver:
	mov	dx,page_ver
	call	print
	jmp exit

; Version page
cli_version:
	mov	dx,page_version
	call	print
	jmp exit

; Help page
cli_help:
	mov	dx,page_help
	call	print
	jmp exit

; Detect i8086, snippet taken out of AP-485.
; The 8086 has FLAGS bits 15:12 always set and cannot be cleared.
; The 8086 also changes the value of SP after pushing.
check_8086:
	pushf		; Push original FLAGS
	pop	ax	; Get FLAGS into AX
	mov	cx,ax	; Save original FLAGS
	and	ax,0fffh	; Clear bits 15:12
	push	ax	; Push new value into stack
	popf		; Set FLAGS from value from stack
	pushf		; Get new FLAGS
	pop	ax	; Save FLAGS value
	and	ax,0f000h	; Keep bits 15:12
	cmp	ax,0f000h	; Anything in FLAGS[15:12]?
	jne	check_286	; If cleared, it's probably an i286
	push	sp	; Not an i286? Check for PUSH/SP diff then
	pop	dx	; Save SP value
	cmp	dx,sp	; If current SP value
	jne	case_8086	; 
	jmp	case_unknown	; 

; Detect i286.
; The i286 has FLAGS bits 15:12 always cleared and cannot be set.
check_286:
	or	cx,0f000h	; Try to set bits 15:12 to saved FLAGS
	push	cx
	popf		; Sets FLAGS from CX
	pushf
	pop	dx	; Get new FLAGS into DX
	and	dx,0f000h	; Clear FLAGS[11:0]
	jz	case_286	; Jump if FLAGS[15:12] is cleared

; Detect i386.
; This checks if we can toggle EFLAGS[AC].
check_386:
	pushfd		; Push original EFLAGS
	pop	eax	; Get ELFAGS
	mov	ecx,eax	; Save EFLAGS
	xor	eax,40000h	; Flip EFLAGS[AC]
	push	eax	; Save new value on stack
	popfd		; Replace EFLAGS
	pushfd		; Get new EFLAGS
	pop	eax	; Store EFLAGS
	xor	eax,ecx	; If can't toggle AC, it is 80386
	jz	case_386
	push	ecx	; Restore EFLAGS
	popfd
	jmp	case_486	; Can toggle AC, it's an 486

; Init and check FPU control word.
check_fpu:
	fninit		; Resets FPU if present
	fnstsw	ax	; Get FPU status word
	cmp	al,0	; Do we have anything?
	jne	exit	; No FPU then

; Check if 8087 by checking bit 15 with FDISI.
; NOTE: Certainly doesn't seem to work with DosBox-X
;check_fpu_cw:
;	fnstcw	[fpucw]	; Get FPU status word
;	mov	ax,fpucw
;	and	ax,103fh	; 
;	cmp	ax,3fh	; 
;	jne	exit	; Failsafe: Incorrect FPU word, no FPU
check_8087:
	and	ax,0xff7f	; Clear other bits
	mov	word [_fpu_cw],ax
	fldcw	[_fpu_cw]	; Load control word into FPU
	fdisi		; 8087-only instruction
	fstcw	[_fpu_cw]	; Get Control Word
	test	word [_fpu_cw],0x80	; Did FDISI do anything?
	je	check_fpu_inf	; FDISI did nothing, go check +INF/-INF
	jmp	case_8087	; FPU: 8087

; Check infinity (-INF/+INF comparison test)
check_fpu_inf:
	fld1		; Push +1.0, this will be st0
	fldz		; Push +0.0, this will be st1
	fdiv		; (fdivp st1,st0) 1.0/0.0 = +INF, then pop, TOP=st0
	fld	st0	; Push st0 value (+INF) again into stack (now st1)
	fchs		; Toggle sign to st0, making st0 -INF
	fcompp		; See if st0/st1 are the same, then pop both
	fstsw	ax	; Get status word
	sahf		; Save AH into low FLAGS to see if infinites matched
	jz	case_287	; <= 80287: +inf == -inf
	jmp	case_387	; >= 80387: +inf != -inf

case_8086:
	mov	dx,str_i8086
	call	print
	jmp	check_fpu
case_286:
	mov	dx,str_i286
	call	print
	jmp	check_fpu
case_386:
	mov	dx,str_i386
	call	print
	jmp	check_fpu
case_486:
	mov	dx,str_i486
	call	print
	jmp	done
case_8087:
	mov	dx,str_fpu87
	call	print
	jmp	done
case_287:
	mov	dx,str_fpu287
	call	print
	jmp	done
case_387:
	mov	dx,str_fpu387
	call	print
	jmp	done
case_unknown:
	mov	dx,str_unknown
	call	print
	jmp	done

; MS-DOS output string
; Params: DX = String pointer
print:	mov	ah,9
	int	21h
	ret

; Done, print newline and exit
done:	mov	dx,str_newln
	call	print

; Exit program (MS-DOS)
exit:	mov	ah,4ch
	int	21h

; Sets zero flag if character a delimiter
; Params:	AL = Character value
; Returns:	FLAGS[ZF] is set if true
test_delim:
	cmp	al,32	; Space
	jz	delim
	cmp	al,44	; Comma
	jz	delim
	cmp	al,9	; Hardware tab
	jz	delim
	cmp	al,59	; Semi-colon
	jz	delim
	cmp	al,61	; Equal sign
	jz	delim
	cmp	al,13	; Carriage return, failsafe
delim:	ret

; Skip over leading delimiters
; Params: SI = Starting source index
skip_delim:
	cld		; Force direction (increments SI)
cont:	lodsb		; Get character as DS:SI
	call	test_delim
	jz	cont	; If delim, continue
	dec	si	; Non-delim found, index is behind
end:	ret

;
; Data section
;

section .data
	opt_version	db	'--version'
	opt_versionlen	equ	$-opt_version
	opt_ver	db	'--ver'
	opt_verlen	equ	$-opt_ver
	opt_help	db	'--help'
	opt_helplen	equ	$-opt_help
	opt_helpalt	db	'/?'
	opt_helpaltlen	equ	$-opt_helpalt
	; DOS strings
	page_version	db	'mcpuinfo v',VERSION,' (built: ',__DATE__,' ',__TIME__,')',NL,'$'
	page_ver	db	VERSION,NL,'$'
	page_help	db	\
		'Pre-Pentium processor/co-processor information utility.',NL,\
		'Usage:',NL,\
		' MCPUINFO [OPTION]',NL,\
		NL,\
		'OPTIONS',NL,\
		' --version    Show version page and quit',NL,\
		' --ver        Print version string and quit',NL,\
		' --help, /?   Show this help page and quit',NL,ENDSTR
	str_newln	db	NL,'$'	; \r\n
	str_i8086	db	'8086',ENDSTR
	str_i286	db	'80286',ENDSTR
	str_i386	db	'80386',ENDSTR
	str_i486	db	'80486',ENDSTR
	str_fpu87	db	'+8087',ENDSTR
	str_fpu287	db	'+80287',ENDSTR
	str_fpu387	db	'+80387',ENDSTR
	str_unknown	db	'unknown',ENDSTR

;
; "Stack" section
;

section .bss
	_fpu_cw	resw	1