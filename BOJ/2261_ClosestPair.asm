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
%define MAXN 100000

section .bss
	rbuf resb BUFLEN	; io template
	wbuf resb BUFLEN	; io template
	rbufcnt resw 1		; io template
	wbufcnt resw 1		; io template
	prr resq MAXN+5
	arr resq 2*MAXN+5
	n resq 1
	vector resq MAXN+5
	vecsiz resq 1

section .data
	ans dq 0xffff_ffff
	rnd dq 1234

section .text
	global main


rng:
	push rbp
	mov rbp, rsp

	mov rax, [rnd]
	imul rax, 8497039
	add rax, 6485302
	xor rdx, rdx
	push rbx
	mov rbx, 1_000_000_007
	div rbx
	pop rbx
	mov [rnd], rdx
	mov rax, rdx

	leave
	ret

mycmp:	; al <- 1 if *rbx < *rdx
	push rbp
	mov rbp, rsp

	push rcx
	xor al, al
	mov rcx, [rbx]
	cmp rcx, [rdx]
	je cmp1_
		jg cmpend_
		xor al, 1
		jmp cmpend_
	cmp1_:
	mov rcx, [rbx+8]
	cmp rcx, [rdx+8]
	jge cmpend_
	xor al, 1

	cmpend_:
	pop rcx
	leave
	ret

qsort:	; [First, Second)
	push rbp
	mov rbp, rsp

	mov rbx, [rbp+16]
	sub rbx, [rbp+24]
	jz qend_

	call rng
	xor rdx, rdx
	div rbx			; rdx <- pivot

	mov rsi, [rbp+24]
	shl rsi, 3
	mov rbx, [prr + rsi]
	xchg rbx, [prr + rsi + rdx*8]
	mov [prr + rsi], rbx	; First element <- pivot

	shr rsi, 3
	mov rdi, [rbp+16]
	dec rdi
	qL_:
		cmp rsi, rdi
		je qLend_
		mov rdx, [prr + rdi*8]
		xchg rbx, rdx
		call mycmp
		xchg rbx, rdx
		xor al, 0
		jnz q2_
			dec rdi
			cmp rsi, rdi
			je qLend_
		q2_:
		push rax
		mov rdx, [prr + rsi*8]
		call mycmp
		xor al, 0
		jnz q1_
			inc rsi
			jmp qL_
		q1_:
		pop rax
		xor al, 0
		jz qL_
		mov rax, [prr + rsi*8]
		xchg rax, [prr + rdi*8]
		mov [prr + rsi*8], rax
		jmp qL_
	qLend_:
	mov rdx, [prr + rsi*8]
	call mycmp
	xor al, 0
	jz qmov_
		dec rsi
	qmov_:
	xchg rbx, [prr + rsi*8]
	mov rdi, [rbp+24]
	xchg rbx, [prr + rdi*8]

	push rdi
	push rsi
	call qsort
	pop rdi
	pop rsi

	inc rdi
	push rdi
	push QWORD[rbp+16]
	call qsort

	qend_:

	leave
	ret

vec_push:
	prologue
	push rsi
	mov rsi, [vecsiz]
	mov [vector+rsi*8], rbx
	inc QWORD[vecsiz]
	pop rsi
	epilogue

vec_clear:
	prologue
	and QWORD[vecsiz], 0
	epilogue

distance:	; *rbx, *rdx
	prologue
	mov rax, [rbx]
	sub rax, [rdx]
	imul eax, eax

	push rcx
	mov rcx, [rbx+8]
	sub rcx, [rdx+8]
	imul ecx, ecx

	add rax, rcx
	pop rcx
	epilogue

mycmp_y:	; ax <- 1 if *rbx < *rdx
	prologue
	push rcx
	xor ax, ax
	mov rcx, [rbx+8]
	cmp rcx, [rdx+8]
	je cmp1_y
		jg cmpend_y
		xor ax, 1
		jmp cmpend_y
	cmp1_y:
	mov rcx, [rbx]
	cmp rcx, [rdx]
	jge cmpend_y
	xor ax, 1

	cmpend_y:
	pop rcx
	epilogue

updans:
	prologue
	push rax
	call distance

	cmp rax, [ans]
	jge ua_
	mov [ans], rax
	ua_:
	pop rax
	epilogue

closest:
	prologue

	mov rax, [rbp+16]
	add rax, [rbp+24]
	shr rax, 1
	cmp rax, [rbp+24]
	je func_end

	push QWORD[prr+rax*8]	; mid *
	push QWORD[rbp+24]
	push rax
	call closest
	pop rax
	mov [rsp], rax
	push QWORD[rbp+16]
	call closest
	add rsp, 8
	pop rbx

	pop rsi
	mov rax, [rsi]	; rax <- mid x, rbx <- mid #

	mov rcx, rbx
	C0:
		mov rsi, [prr+rcx*8]
		mov rdx, [rsi]
		sub rdx, rax
		imul edx, edx
		cmp rdx, [ans]
		jge C0end
			push rbx
			mov rbx, rsi
			call vec_push
			pop rbx
		C0end:
		inc rcx
		cmp rcx, [rbp+16]
		jl C0

	push rbx
	push QWORD 0
	mov rcx, [rbp+24]
	C1:
		mov rdx, rax
		mov rsi, [prr+rcx*8]
		sub rdx, [rsi]
		imul edx, edx	; (x ~ midx)^2
		cmp rdx, [ans]
		jge C1end
		mov rdx, [rsi+8]
		; rdx <- y, rcx <- now lf #

		C2:
			mov rbx, [rsp]
			cmp rbx, [vecsiz]
				je C2end
			mov rdi, [vector+rbx*8]
			mov rbx, [rdi+8]
			sub rbx, rdx
				jns C2end
			imul ebx, ebx
			cmp rbx, [ans]
			jl C2end
			inc QWORD[rsp]
			jmp C2
		C2end:
		push QWORD[rsp]
		C3:
			mov rdi, [rsp]
			cmp rdi, [vecsiz]
				je C3end
			mov rdi, [vector+rdi*8]
			mov rbx, [rdi+8]
			sub rbx, rdx
			imul ebx, ebx
			cmp rbx, [ans]
			jge C3end

			push rdx
			mov rbx, rsi
			mov rdx, rdi
			call updans
			pop rdx

			inc QWORD[rsp]
			jmp C3
		C3end:
		add rsp, 8
		C1end:
		inc rcx
		cmp rcx, [rbp-8]
		jl C1
	add rsp, 8
	call vec_clear
	
	push QWORD[rbp+16]	; 2
	push QWORD 0		; 3

	mov rbx, [rbp+16]
	sub rbx, [rbp+24]
	shl rbx, 3
	sub rsp, rbx	; arr[siz]

	mov rax, [rbp+24]
	mov rcx, [rbp-8]
	C4:
		xor dl, dl
		cmp rax, [rbp-8]
		jne C4_
			xor dl, 1
		C4_:
		cmp rcx, [rbp-16]
		jne C4_0
			xor dl, 2
		C4_0:
		cmp dl, 3
		je C4end
		test dl, 1
		jnz C4_2
		test dl, 2
		jnz C4_1
		mov rbx, [prr+rax*8]
		mov rdx, [prr+rcx*8]
			push rax
			call mycmp_y
			mov bx, ax
			pop rax
		xor bx, 0
		jz C4_2

		C4_1:
			mov rsi, rax
			inc rax
			jmp C4_3
		C4_2:
			mov rsi, rcx
			inc rcx
		C4_3:
		mov rbx, [prr+rsi*8]
		mov rdi, [rbp-24]
		mov [rsp+rdi*8], rbx
		inc QWORD[rbp-24]

		jmp C4
	C4end:

	mov rcx, [rbp-24]
	lea rsi, [rsp]
	mov rbx, [rbp+24]
	lea rdi, [prr+rbx*8]
	cld
	rep movsq

	epilogue

main:
	push rbp
	mov rbp, rsp

	call readint
	mov [n], rax
	xor rsi, rsi
	mov rdi, prr
	L1:
		shl rsi, 4
			lea rbx, [arr+rsi]
			mov [rdi], rbx
			add rdi, 8
		call readint
		mov [arr+rsi], rax
		call readint
		mov [arr+rsi+8], rax
		shr rsi, 4
		inc rsi
		cmp rsi, [n]
		jl L1

	push QWORD 0
	push QWORD[n]
	call qsort
	call closest

	mov rbx, [ans]
	call writeint
	call writecrlf

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
	xor rsi, rsi
	mov si, [wbufcnt]
	mov [wbuf + rsi], bl
	inc WORD[wbufcnt]
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
