IDEAL
MODEL small
STACK 100h
DATASEG
	x dw ?
	y dw ?
	; screen width is almost 320
	; screen height is almost 200
	
	head_x dw 120
	head_y dw 120
	
	red db 4
	green db 2
	brown db 6
	color db 2
	
	len dw 6 ; width and height of block
	snake_len dw 1
	
	x_move dw 6
	y_move dw 0
	
	apple_x dw 60
	apple_y dw 60
	
	eat_apple dw 0
	
	snake_body_x dw 1749 dup(?)
	snake_body_y dw 1749 dup(?)

	less_then dw ? ; num for check that the apple will not generate after screen
	
	cnt dw 0
	
	random_num dw ?
	
	Clock equ es:6Ch ; the place where 
	
	part_to_find dw 1
	
	sound_frequency dw ?
	
	num_for_print dw ?
	
CODESEG
proc pixel
	push cx ; save cx for line loop
	
	; draw the pixel
	mov bh,0h
	mov cx, [x]
	mov dx, [y]
	mov al, [color]
	mov ah,0ch
	int 10h
	
	pop cx
	
	ret
endp pixel

proc line
	
	push cx ; save cx for block loop

	mov cx, [len]
	line_loop:		
		inc [x]
		call pixel
	loop line_loop
	mov cx, [len]
	sub [x], cx
	
	pop cx
	
	ret
endp line

proc block
	
	mov cx, [len]
	block_loop:
		inc [y]
		call line
	loop block_loop
	mov cx, [len]
	sub [y], cx
	
	ret
endp block

proc timer
	mov cx, 3
	
	mov ax, 40h
	mov es, ax
	changed:
		mov ax, [Clock]
		not_changed:
			cmp ax, [Clock]
			je not_changed
			loop changed
	
	ret

endp timer


proc draw_snake
	
	; listen to keyboard
	WaitForData:
		mov ah, 1
		int 16h
		;call timer
		jz to_forward

continue:
	mov ah, 0
	int 16h
	
	cmp ah, 1Eh ; press on a
	je a_left

	cmp ah, 20h ; press on d
	je d_right
	
	cmp ah, 11h ; press on s
	je s_down
	
	cmp ah, 1fh ; press on w
	je w_up
	
	cmp ah, 1h ; press on esc
	je esc_out
	
	to_forward:
		jmp forward
	
	a_left:
		cmp [x_move], 6 ; check if go back
		je forward
		
		mov [x_move], -6
		mov [y_move], 0
		
		jmp forward
	
	d_right:
		cmp [x_move], -6 ; check if go back
		je forward

		mov [x_move], 6
		mov [y_move], 0
	
		jmp forward
	
	s_down:
		cmp [y_move], 6 ; check if go back
		je forward

		mov [x_move], 0
		mov [y_move], -6

		jmp forward
	
	w_up:
		cmp [y_move], -6 ; check if go back
		je forward

		mov [x_move], 0
		mov [y_move], 6

		jmp forward
	

	esc_out:
		jmp exit
		
	forward:


		cmp [eat_apple], 1
		je save_tail
		
		tail_change_to_black:
		
		mov ax, [snake_len]
		sub ax, 1
		mov bx, 2
		mul bx
		mov bx, ax
		mov dx, [snake_body_x + bx]
		mov [x], dx
		mov dx, [snake_body_y + bx]
		mov [y], dx
		mov [color], 255
		call block
		jmp skip_eat_apple

		save_tail:
			add [snake_len], 1
			mov [eat_apple], 0
		skip_eat_apple:
		
		mov cx, [snake_len] ; for the loop
		mov ax, cx
		dec ax
		;dec cx
		cmp cx, 1
		je snake_len_is_1
		
		mov bx, 2 ; length of word in the array
		
		jmp body_change
		body_change1:
			dec ax
		
		body_change:
			mov bx, 2
			mov dx, ax
			push dx
			mul bx
			mov bx, ax
			pop ax
			sub bx, 2
			mov dx, [snake_body_x + bx]
			add bx, 2
			mov [snake_body_x + bx], dx
			sub bx, 2
			mov dx, [snake_body_y + bx]
			add bx, 2
			mov [snake_body_y + bx], dx
			dec cx

		cmp cx, 2
		jge body_change1
		
		snake_len_is_1:


		mov ax, [head_x]
		mov [snake_body_x], ax

		mov ax, [head_y]
		mov [snake_body_y], ax


		; forward head
		mov ax, [x_move]
		mov cx, [y_move]
		add [head_x], ax
		add [head_y], cx
		

		mov ax, [head_x]
		mov [x], ax
		mov ax, [head_y]
		mov [y], ax
		
		mov [color], 2 ; green
		call block
		
		snake_func_end:
		
		
	ret

endp draw_snake


proc random

	mov ax, 40h
	mov es, ax
	mov ax, [Clock] ; read timer counter
	mov ah, [byte cs:bx] ; read one byte from memory
	xor al, ah ; xor memory and counter
	and al, 00011111b ; leave result between 0-31
	xor ah, ah
	mov [random_num], ax
	inc bx
	
	ret
	
endp random

proc new_apple_pos
	genrate_position:
		call random
		
		mov dx, [random_num]
		mov ax, 6
		mul dx
		mov [random_num], ax

		
		cmp [part_to_find], 1
		je only_find
		
		mov cx, [snake_len]
		dec cx
		
		

		not_on_snake:
			mov bx, 2
			
			cmp [snake_len], 1
			jne dont_only_find
			
			cmp cx, 0
			je only_find
			
			dont_only_find:
			
			mov ax, cx
			mul bx
			mov bx, ax
			mov ax, [random_num]

			mov dx, [apple_x]
			
			cmp ax, [snake_body_y + bx]
			jne end_check
						
			cmp dx, [snake_body_x + bx]
			je genrate_position
						
			end_check:
			
			
			loop not_on_snake
		
		mov ax, [random_num]
		cmp ax, [head_y]
		jne only_find
		
		mov ax, [apple_x]
		cmp ax, [head_X]
		je genrate_position
		
		only_find:
			
		mov ax, [less_then]
		
		cmp ax, [random_num]
		jl genrate_position
	
	
	ret
endp new_apple_pos


proc apple	
	
	mov [eat_apple], 1
	
	; find apple position
	
	; find x
	
	mov [part_to_find], 1
	mov [less_then], 320
	call new_apple_pos
	mov ax, [random_num]
	mov [apple_x], ax
	mov [x], ax
	
	; find y
	
	mov [part_to_find], 2
	mov [less_then], 200
	call new_apple_pos
	mov ax, [random_num]
	mov [apple_y], ax
	mov [y], ax
	
	mov [color], 4
	
	call block
	
	
	ret
endp apple

proc colission_apple
	mov ax, [head_x]
	cmp ax, [apple_x]
	jne end_func ; other x
	mov ax, [head_y]
	cmp ax, [apple_y]
	jne end_func ; same x and same y so need to generate new apple
	
	generate_new_apple:
		call sound_maker
		call apple
		
	end_func:
	
	ret
endp colission_apple

proc colission
	cmp [head_x], 0
	jl to_exit
	
	cmp [head_X], 314
	jg to_exit
	
	cmp [head_y], 0
	jl to_exit
	
	cmp [head_y], 194
	jg to_exit
	
	jmp not_exit
	
	to_exit:
		call sound_maker
		jmp exit
	
	
	not_exit:
	
	mov cx, [snake_len]
	dec cx

	not_on_snake_1:
		mov bx, 2
		
		cmp cx, 0
		je dont_collision
		
		mov ax, cx
		mul bx
		mov bx, ax
		mov ax, [head_y]

		mov dx, [head_X]
			
		cmp dx, [snake_body_x + bx]
		jne end_check_1
						
		cmp ax, [snake_body_y + bx]
		je to_exit
						
		end_check_1:
			
			
	loop not_on_snake_1
	
	dont_collision:


	ret
endp colission

proc beep_sound
	
	; open speaker code
	in al, 61h
	or al, 00000011b
	out 61h, al
	
	; send const
	mov al, 0B6h
	out 43h, al
	
	; play music
	mov ax, [sound_frequency]
	out 42h, al
	mov al, ah
	out 42h, al
	
	; close the speaker
	
	in al, 61h
	and al, 11111100b
	out 61h, al
	
	ret
	
endp beep_sound

proc sound_maker
	mov [sound_frequency], 1
	mov cx, 400
	sound_by_func:
		add [sound_frequency], cx
		call beep_sound
	loop sound_by_func
	
	ret
	
endp sound_maker

proc print
	mov dl, [byte ptr num_for_print]
	add dl, 48
	mov ah, 2
	int 21h
	
	ret
endp print

proc print_score
	
	mov ax, [snake_len]
	xor cx, cx
	mov bx, 10

	num_for_print_loop:
		cmp ax, 0
		je end_num_for_print_loop
		inc cx
		div bx ; answer in ax, mod (%) in dx
		push dx
		
		jmp num_for_print_loop
	
	end_num_for_print_loop:
		
	print_loop:
		pop dx
		mov [num_for_print], dx
		call print
		
		loop print_loop
	
	ret
endp print_score

start :
	mov ax, @data
	mov ds, ax
	
	;Graphic mode
	mov ax, 13h
	int 10h
	
	; first apple
	
	mov ax, [apple_x]
	mov [x], ax
	mov ax, [apple_y]
	mov [y], ax
	
	mov [color], 4	
	
	call block
	
	; init snake body
	
	mov [snake_body_x], 114
	mov [snake_body_y], 120
	mov [color], 2
	mov [x], 114
	mov [y], 120
	
	call block

	

	game_loop:
		
		call colission_apple
		
		call colission

		call draw_snake
		
		call timer
				
		jmp game_loop
exit:
	; change to text mode
	mov ah, 0
	mov al, 2
	int 10h

	mov [num_for_print], 1
	
	call print
	
	
	mov ax, 4c00h
	int 21h
END start
