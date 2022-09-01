%macro prologue 0
	push rbp
	mov rbp, rsp
%endmacro
%macro epilogue 0
	leave
	ret
%endmacro
%macro exit_ 0
	call writeall
	xor rbx, rbx
	mov rax, 1
	int 0x80
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
	m resq 1
	arr resq MAXN+5
	segtree resq 1<<21 	; for segment tree
	lazy resq 1<<21		; lazy for segment tree
	segsiz resq 1			; size of segment tree

section .data

section .text
	global main


seginit:	; rbx <- arr, rcx <- size N
	prologue
	mov QWORD[segsiz], 1
	L_seginit:
		shl QWORD[segsiz], 1
		cmp QWORD[segsiz], rcx
		jl L_seginit
	push rsi
	push rdi
	push rcx
	mov rcx, [segsiz]
	lea rdi, [segtree + rcx*8]
	xor rax, rax
	CLD
	rep stosq
	mov rcx, [segsiz]
	shl rcx, 1
	mov rdi, lazy
	CLD
	rep stosq
	pop rcx
	mov rsi, rbx
	mov rdi, [segsiz]
	lea rdi, [segtree + rdi*8]
	CLD
	rep movsq
	mov rcx, [segsiz]
	dec rcx
	L_seginit_2:
		shl rcx, 1
		mov rbx, [segtree + rcx*8]
		add rbx, [segtree + rcx*8 + 8]
		mov [segtree + rcx*4], rbx
		shr rcx, 1
	loop L_seginit_2
	pop rdi
	pop rsi
	epilogue

prop:		; rbx <- pos, rcx <- size
	prologue
	mov rax, [lazy + rbx*8]
	xor rax, 0
	jz prop_end
	test rcx, 1
	jnz prop_nochild
	shl rbx, 1
	add [lazy + rbx*8], rax
	add [lazy + rbx*8+8], rax
	shr rbx, 1
	prop_nochild:
	imul rax, rcx
	add [segtree + rbx*8], rax
	mov QWORD[lazy + rbx*8], 0
	prop_end:
	epilogue

msegupd:	; now: rbx [rcx, rdx], target [r8, r9], val r10
	prologue
	sub rcx, rdx
	neg rcx
	inc rcx
	call prop
	dec rcx
	neg rcx
	add rcx, rdx
	cmp rdx, r8
	jl msegupd_end
	cmp r9, rcx
	jl msegupd_end
	cmp r8, rcx
	jg msegupd_go
	cmp rdx, r9
	jg msegupd_go
	add [lazy + rbx*8], r10
	sub rcx, rdx
	neg rcx
	inc rcx
	call prop
	epilogue
	msegupd_go:
	shl rbx, 1
	push rbx
	push rdx
	add rdx, rcx
	shr rdx, 1
	push rdx
	call msegupd
	pop rcx
	inc rcx
	pop rdx
	mov rbx, [rsp]
	inc rbx
	call msegupd
	pop rbx
	mov rax, [segtree + rbx*8]
	add rax, [segtree + rbx*8+8]
	mov [segtree + rbx*4], rax
	msegupd_end:
	epilogue

segupd:		; target [rbx, rcx], val rdx
	prologue
	mov r8, rbx
	mov r9, rcx
	mov r10, rdx
	mov rbx, 1
	xor rcx, rcx
	mov rdx, [segsiz]
	dec rdx
	call msegupd
	epilogue

msegquery:	; now: rbx [rcx, rdx], target [r8, r9], 0-index
	prologue
	cmp rdx, r8
	jl msegquery_end1
	cmp r9, rcx
	jge msegquery_end2
	msegquery_end1:
	xor rax, rax
	epilogue
	msegquery_end2:
	sub rcx, rdx
	neg rcx
	inc rcx
	call prop
	dec rcx
	neg rcx
	add rcx, rdx
	cmp r8, rcx
	jg msegquery_go
	cmp rdx, r9
	jg msegquery_go
	mov rax, [segtree + rbx*8]
	epilogue
	msegquery_go:
	push rdx
	add rdx, rcx
	shr rdx, 1
	push rdx
	shl rbx, 1
	push rbx
	call msegquery
	pop rbx
	inc rbx
	pop rcx
	inc rcx
	pop rdx
	push rax
	call msegquery
	add rax, [rsp]
	add rsp, 8
	epilogue

segquery:	; taget [rbx, rcx]
	prologue
	mov r8, rbx
	mov r9, rcx
	mov rbx, 1
	xor rcx, rcx
	mov rdx, [segsiz]
	dec rdx
	call msegquery
	epilogue

main:
	push rbp
	mov rbp, rsp

	call readint
	mov [n], rax
	call readint
	mov [m], rax
	call readint
	add [m], rax

	mov rcx, [n]
	mov rsi, arr
	L1:
		call readint
		mov [rsi], rax
		add rsi, 8
	loop L1

	mov rbx, arr
	mov rcx, [n]
	call seginit

	mov rcx, [m]
	L2:
		push rcx
		call readint
		xor al, 2
		jz L2_sum
			call readint
			mov rbx, rax
			call readint
			mov rcx, rax
			call readint
			mov rdx, rax
			dec rbx
			dec rcx
			call segupd
			jmp L2_fin
		L2_sum:
			call readint
			mov rbx, rax
			call readint
			mov rcx, rax
			dec rbx
			dec rcx
			call segquery
			mov rbx, rax
			call writeint
			call writecrlf
		L2_fin:
		pop rcx
	loop L2

	call writeall
	xor rax, rax
	leave
	ret

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
