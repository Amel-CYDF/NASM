%define BUFLEN 1<<13		; io template

section .bss
	rbuf resb BUFLEN	; io template
	wbuf resb BUFLEN	; io template
	rbufcnt resw 1		; io template
	wbufcnt resw 1		; io template

section .data


section .text
	global main


main:
	push rbp
	mov rbp, rsp

	;

	call writeall
	pop rbp
	xor rax, rax
	ret

func_end:
	leave
	ret

exit_:
	xor rbx, rbx
	mov rax, 1
	int 0x80

; ========================
; IO template starts here
;
; should have:
;
;	%define BUFLEN 2048 ;any 2^n
; section .bss
;	rbuf resb BUFLEN
;	wbuf resb BUFLEN
;	rbufcnt resw 1
;	wbufcnt resw 1
;
; call writeall before exit to clear buffer
;
readone:
	push rbp
	mov rbp, rsp
	xor WORD[rbufcnt], 0
	jz ro1_
	test WORD[rbufcnt], BUFLEN
	jz ro2_
	ro1_:
		mov rax, 3 		; read
		mov rbx, 0		; stdin
		mov rcx, rbuf	; char *
		mov rdx, BUFLEN	; size_t
		int 0x80
		mov WORD[rbufcnt], 0
	ro2_:
	xor rsi, rsi
	mov si, [rbufcnt]
	mov al, [rbuf + rsi]
	inc WORD[rbufcnt]
	leave
	ret

readstr: ; rbx <- char *
	push rbp
	mov rbp, rsp
	push rbx
	rs1_:
		call readone
		cmp al, 0x20
		jle rs1_
	rs2_:
		pop rbx
		mov BYTE[rbx], al
		inc rbx
		push rbx
		call readone
		cmp al, 0x20
		jg rs2_
	pop rbx
	mov BYTE[rbx], 0
	leave
	ret

readint: ; return rax
	push rbp
	mov rbp, rsp
	ri1_:
		call readone
		cmp al, 0x20
		jle ri1_
	push rax
	push QWORD 0
	cmp al, 0x2D		; '-'
	jg ri2_
		call readone
	ri2_:
		pop rbx
		mov rdx, rbx
		shl rbx, 3		; *=8
		shl rdx, 1		; *= 2
		add rbx, rdx	; 8X + 2X = 10X
		and rax, 0xF	; ascii -> int
		add rbx, rax
		push rbx
		call readone
		cmp al, 0x20
		jg ri2_
	pop rax
	pop rbx
	cmp bl, 0x2D		; '-'
	jne ri3_
		not rax
		inc rax
	ri3_:
	leave
	ret

writeall:
	push rbp
	mov rbp, rsp
	xor rdx, rdx
	mov rax, 4		; write
	mov rbx, 1		; stdout
	mov rcx, wbuf	; char *
	mov dx, WORD[wbufcnt]	; size_t
	int 0x80
	mov WORD[wbufcnt], 0
	leave
	ret

writeone: ; rbx <- char
	push rbp
	mov rbp, rsp
	push rbx
	test WORD[wbufcnt], BUFLEN
	jz wo_
		mov rax, 4		; write
		mov rbx, 1		; stdout
		mov rcx, wbuf	; char *
		mov rdx, BUFLEN	; size_t
		int 0x80
		mov WORD[wbufcnt], 0
	wo_:
	xor rsi, rsi
	mov si, [wbufcnt]
	pop rbx
	mov [wbuf + rsi], bl
	inc WORD[wbufcnt]
	leave
	ret

writestr: ; rbx <- char *
	push rbp
	mov rbp, rsp
	ws_:
		push rbx
		mov bl, [rbx]
		call writeone
		pop rbx
		inc rbx
		xor BYTE[rbx], 0
		jnz ws_
	leave
	ret

writeint: ; rbx <- int
	push rbp
	mov rbp, rsp
	push QWORD -1
	mov rax, rbx
	mov rbx, 10
	xor cl, cl
	xor rax, 0
	jns wi1_
		xor cl, 1
		not rax
		inc rax
	wi1_:
		xor rdx, rdx
		div rbx
		xor rdx, 0x30	; '0'
		push rdx
		xor rax, 0
		jnz wi1_
	test cl, 1
	jz wi2_
		mov bl, 0x2D	; '-'
		call writeone
	wi2_:
		pop rbx
		xor rbx, 0
		js wi3_
		call writeone
	jmp wi2_
	wi3_:
	leave
	ret

; IO template ends here
; ========================
