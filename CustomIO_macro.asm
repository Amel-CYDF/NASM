; ========================
; IO template starts here
;
; should have:
;
; section .bss
;	rbuf resb BUFLEN
;	wbuf resb BUFLEN
;	rbufcnt resd 1
;	wbufcnt resd 1
;
; call writeall before exit to clear buffer
;
%define BUFLEN 1<<20
%macro readone 2	; %1: rbuf, %2: rbufcnt
	xor DWORD[%2], 0
	jz %%ro1_
	test DWORD[%2], BUFLEN
	jz %%ro2_
	%%ro1_:
		mov rax, 3 		; read
		mov rbx, 0		; stdin
		mov rcx, %1		; char *
		mov rdx, BUFLEN	; size_t
		int 0x80
		mov DWORD[%2], 0
	%%ro2_:
	xor rsi, rsi
	mov esi, DWORD[%2]
	mov al, [rbuf + rsi]
	inc DWORD[%2]
%endmacro
%macro readstr 2	; rbx <- char *
	push rbx
	%%rs1_:
		readone %1, %2
		cmp al, 0x20
		jle %%rs1_
	%%rs2_:
		pop rbx
		mov BYTE[rbx], al
		inc rbx
		push rbx
		readone %1, %2
		cmp al, 0x20
		jg %%rs2_
	pop rbx
	mov BYTE[rbx], 0
%endmacro
%macro readint 2	; rax <- int
	%%ri1_:
		readone %1, %2
		cmp al, 0x20
		jle %%ri1_
	push rax
	push QWORD 0
	cmp al, 0x2D		; '-'
	jg %%ri2_
		readone %1, %2
	%%ri2_:
		pop rbx
		mov rdx, rbx
		shl rbx, 3		; *=8
		shl rdx, 1		; *= 2
		add rbx, rdx	; 8X + 2X = 10X
		and rax, 0xF	; ascii -> int
		add rbx, rax
		push rbx
		readone %1, %2
		cmp al, 0x20
		jg %%ri2_
	pop rax
	pop rbx
	cmp bl, 0x2D		; '-'
	jne %%ri3_
		not rax
		inc rax
	%%ri3_:
%endmacro
%macro writeall 2 	; %1: wbuf, %2: wbufcnt
	xor rdx, rdx
	mov rax, 4		; write
	mov rbx, 1		; stdout
	mov rcx, %1		; char *
	mov edx, DWORD[%2]	; size_t
	int 0x80
	mov DWORD[%2], 0
%endmacro
%macro writeone 2 	; %1: wbuf, %2: wbufcnt
	push rbx
	test DWORD[%2], BUFLEN
	jz %%wo_
		mov rax, 4		; write
		mov rbx, 1		; stdout
		mov rcx, %1		; char *
		mov rdx, BUFLEN	; size_t
		int 0x80
		mov DWORD[%2], 0
	%%wo_:
	xor rsi, rsi
	mov esi, DWORD[%2]
	pop rbx
	mov [%1 + rsi], bl
	inc DWORD[%2]
%endmacro
%macro writestr 2	; rbx <- char *, %1: wbuf, %2: wbufcnt
	%%ws_:
		push rbx
		mov bl, [rbx]
		writeone %1, %2
		pop rbx
		inc rbx
		xor BYTE[rbx], 0
	jnz %%ws_
%endmacro
%macro writeint 2	; rbx <- int, %1: wbuf, %2: wbufcnt
	push QWORD -1
	mov rax, rbx
	mov rbx, 10
	xor cl, cl
	xor rax, 0
	jns %%wi1_
		xor cl, 1
		neg rax
	%%wi1_:
		xor rdx, rdx
		div rbx
		xor rdx, 0x30	; '0'
		push rdx
		xor rax, 0
		jnz %%wi1_
	test cl, 1
	jz %%wi2_
		mov bl, 0x2D	; '-'
		writeone %1, %2
	%%wi2_:
		pop rbx
		xor rbx, 0
		js %%wi3_
		writeone %1, %2
	jmp %%wi2_
	%%wi3_:
%endmacro
;
; IO template ends here
; ========================


section .bss
	rbuf resb BUFLEN	; io template
	wbuf resb BUFLEN	; io template
	rbufcnt resd 1		; io template
	wbufcnt resd 1		; io template

section .data


section .text
	global main


main:
	push rbp
	mov rbp, rsp

	;

	writeall wbuf, wbufcnt
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
