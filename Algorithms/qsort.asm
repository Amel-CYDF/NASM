section .data
	rnd dq 1234

section .text

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

mycmp:	; al <- 1 if rbx < rdx
	push rbp
	mov rbp, rsp

	xor al, al
	cmp rbx, rdx
	jge cmpend_
	xor al, 1

	cmpend_:
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
	mov rbx, [arr + rsi]
	xchg rbx, [arr + rsi + rdx*8]
	mov [arr + rsi], rbx	; First element <- pivot

	shr rsi, 3
	mov rdi, [rbp+16]
	dec rdi
	qL_:
		cmp rsi, rdi
		je qLend_
		mov rdx, [arr + rdi*8]
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
		mov rdx, [arr + rsi*8]
		call mycmp
		xor al, 0
		jnz q1_
			inc rsi
			jmp qL_
		q1_:
		pop rax
		xor al, 0
		jz qL_
		mov rax, [arr + rsi*8]
		xchg rax, [arr + rdi*8]
		mov [arr + rsi*8], rax
		jmp qL_
	qLend_:
	mov rdx, [arr + rsi*8]
	call mycmp
	xor al, 0
	jz qmov_
		dec rsi
	qmov_:
	xchg rbx, [arr + rsi*8]
	mov rdi, [rbp+24]
	xchg rbx, [arr + rdi*8]

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
