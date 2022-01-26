%macro prologue 0
	push rbp
	mov rbp, rsp
%endmacro
%macro epilogue 0
	leave
	ret
%endmacro
%macro pushall 0
	push rax
	push rbx
	push rcx
	push rdx
	push rsi
	push rdi
%endmacro
%macro popall 0
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	pop rax
%endmacro

%define BUFLEN 1<<13	; io template
%define MAXN 1000000

section .bss
	rbuf resb BUFLEN	; io template
	wbuf resb BUFLEN	; io template
	rbufcnt resw 1		; io template
	wbufcnt resw 1		; io template
	n resq 1
	arr resq MAXN+5

section .data

section .text
	global main



main:
	push rbp
	mov rbp, rsp

	;

	call writeall
	xor rax, rax
	leave
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
; call writeall before exit to clear write buffer
; writeall does NOT preserve registers
;
readone:
	push rbp
	mov rbp, rsp
	xor WORD[rbufcnt], 0
	jz ro1_
	test WORD[rbufcnt], BUFLEN
	jz ro2_
	ro1_:
		push rbx
		push rcx
		push rdx
		mov rax, 3 		; read
		mov rbx, 0		; stdin
		mov rcx, rbuf	; char *
		mov rdx, BUFLEN	; size_t
		int 0x80
		and WORD[rbufcnt], 0
		pop rdx
		pop rcx
		pop rbx
	ro2_:
	push rsi
	xor rsi, rsi
	mov si, [rbufcnt]
	mov al, [rbuf + rsi]
	inc WORD[rbufcnt]
	pop rsi
	leave
	ret

readstr: ; rbx <- char *
	push rbp
	mov rbp, rsp
	push rax
	rs1_:
		call readone
		cmp al, 0x20
		jle rs1_
	rs2_:
		mov [rbx], al
		inc rbx
		call readone
		cmp al, 0x20
		jg rs2_
	and BYTE[rbx], 0
	pop rax
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
	cmp al, 0x2D			; '-'
	jg ri2_
		call readone
	ri2_:
		push rbx
		mov rbx, [rsp+8]
		shl QWORD[rsp+8], 3	; *= 8
		shl rbx, 1			; *= 2
		add [rsp+8], rbx	; 8X + 2X = 10X
		and rax, 0xF		; ascii -> int
		add [rsp+8], rax
		pop rbx
		call readone
		cmp al, 0x20
		jg ri2_
	pop rax
	cmp BYTE[rsp], 0x2D		; '-'
	jne ri3_
		neg rax
	ri3_:
	leave
	ret

writeall:
	push rbp
	mov rbp, rsp
	xor rdx, rdx
	mov rax, 4			; write
	mov rbx, 1			; stdout
	mov rcx, wbuf		; char *
	mov dx, [wbufcnt]	; size_t
	int 0x80
	and WORD[wbufcnt], 0
	leave
	ret

writeone: ; bl <- char
	push rbp
	mov rbp, rsp
	test WORD[wbufcnt], BUFLEN
	jz wo_
		push rax
		push rbx
		push rcx
		push rdx
		mov rax, 4		; write
		mov rbx, 1		; stdout
		mov rcx, wbuf	; char *
		mov rdx, BUFLEN	; size_t
		int 0x80
		and WORD[wbufcnt], 0
		pop rdx
		pop rcx
		pop rbx
		pop rax
	wo_:
	push rsi
	xor rsi, rsi
	mov si, [wbufcnt]
	mov [wbuf + rsi], bl
	inc WORD[wbufcnt]
	pop rsi
	leave
	ret

writestr: ; rbx <- char *
	push rbp
	mov rbp, rsp
	push rbx
	ws_:
		mov rbx, [rsp]
		mov bl, [rbx]
		call writeone
		inc QWORD[rsp]
		xor bl, 0
		jnz ws_
	pop rbx
	leave
	ret

writespace:
	push rbp
	mov rbp, rsp
	push rbx
	mov bl, 0x20
	call writeone
	pop rbx
	leave
	ret

writecrlf:
	push rbp
	mov rbp, rsp
	push rbx
	mov bl, 0x0A
	call writeone
	pop rbx
	leave
	ret

writeint: ; rbx <- int
	push rbp
	mov rbp, rsp
	push rbx
	push rax
	push rdx
	push QWORD -1
	mov rax, rbx
	mov rbx, 10
	xor rax, 0
	jns wi1_
		neg rax
	wi1_:
		xor rdx, rdx
		div rbx
		xor rdx, 0x30	; '0'
		push rdx
		xor rax, 0
		jnz wi1_
	cmp QWORD[rbp-8], 0
	jge wi2_
		mov bl, 0x2D	; '-'
		call writeone
	wi2_:
		pop rbx
		xor rbx, 0
		js wi3_
		call writeone
	jmp wi2_
	wi3_:
	pop rdx
	pop rax
	pop rbx
	leave
	ret

; IO template ends here
; ========================
