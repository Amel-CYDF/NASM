; boj.kr/1927
section .bss
	n: resq 1
	m: resq 1
	siz: resq 1
	heap: resq 100005

section .data
	f1: db '%d', 0
	f2: db '%d',10, 0
	f3: db '%d ', 0
	f4: db 10, 0

section .text
	global main
	extern scanf
	extern printf


func_end:
	leave
	ret

heap_push:
	push rbp
	mov rbp, rsp

	inc QWORD[siz]
	mov rsi, [siz]
	mov [heap + rsi*8], rbx

	pushL1:
		cmp rsi, 1
		je func_end

		mov rax, rsi
		xor rdx, rdx
		mov rdi, 2
		div rdi
		mov rdi, rax

		mov rax, [heap + rsi*8]
		cmp rax, [heap + rdi*8]
		jge func_end

		mov rbx, [heap + rdi*8]
		mov [heap + rdi*8], rax
		mov [heap + rsi*8], rbx

		mov rsi, rdi
	jmp pushL1

heap_pop:
	push rbp
	mov rbp, rsp

	cmp QWORD[siz], 0
	je func_end

	mov rsi, [siz]
	mov rax, [heap + rsi*8]
	mov [heap + 8], rax
	dec QWORD[siz]
	
	mov rsi, 1
	popL1:
		mov rdi, rsi
		imul rdi, 2
		cmp rdi, [siz]
		jg func_end

		mov rax, [heap + rdi*8]

		inc rdi
		cmp rdi, [siz]
		jg popL2

		cmp rax, [heap + rdi*8]
		jle popL2
			mov rax, [heap + rdi*8]
			inc rdi
		popL2:
		dec rdi

		cmp rax, [heap + rsi*8]
		jge func_end

		mov rbx, [heap + rsi*8]
		mov [heap + rdi*8], rbx
		mov [heap + rsi*8], rax

		mov rsi, rdi
	jmp popL1

heap_top:
	push rbp
	mov rbp, rsp

	xor rax, rax
	cmp QWORD[siz], 0
	je func_end
	mov rax, [heap + 8]
	jmp func_end


myprint:
	push rbp
	mov rbp, rsp

	mov rdi, f2
	mov rsi, rbx
	call printf

	leave
	ret

main:
	push rbp
	mov rbp, rsp

	mov rdi, f1
	mov rsi, n
	call scanf

	mov rcx, [n]
	push rcx
	L1:
		push rcx

		mov rdi, f1
		mov rsi, n
		call scanf

		cmp QWORD[n], 0
		je L2
			mov rbx, [n]
			call heap_push
		jmp L1end
		L2:
			call heap_top
			mov rdi, f2
			mov rsi, rax
			call printf
			call heap_pop
		L1end:
		pop rcx
	loop L1
	pop rcx

	pop rbp
	xor rax, rax
	ret