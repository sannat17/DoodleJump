#####################################################################
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#####################################################################
.data
	displayAddress: .word 0x10008000
	bufferAddress: .word 0x10090000
	entity_cache: .word 
	skyblue: .word 0x87ceeb
	limegreen: .word 0xc7ea46
	yellow: .word 0xffd400
	black: .word 0x000000
.text
	lw $s0, bufferAddress # $s0 stores base address for display
	addi $s1, $s0, 4096 # $s1 stores the last address value for display.
	
start_screen: 	
		jal bgPaint
	
		addi $a1, $s0, 256
		jal MakePlatform
		addi $a1, $s0, 2000
		jal MakePlatform
		addi $a1, $s0, 3000
		jal MakePlatform
	
		addi $a1, $s1, -64
		jal MakeDoodle
		
		jal loadBuffer

wait_to_start:	
		lw $t8, 0xffff0000
		beq $t8, 1, start_if_s
		j wait_to_start
		
start_if_s:	
		lw $t7, 0xffff0004
		beq $t7, 115, start_game

start_game:	
		li $v0, 10 # terminate the program gracefully
		syscall

		
# --------
# -------- Functions --------
# --------

# --- Load Buffer ---
loadBuffer:	lw $t0, bufferAddress # Set $t0 as base address for the buffer and will be used as increment
		addi $t1, $t0, 4096 # Set $t1 as the last address of the buffer
		lw $t3, displayAddress # Set $t3 as base of DisplayAddress, to be incremented with $t0
		
loadBufferLoop:	beq $t0, $t1, end_loadBufferLoop
		lw $t7, ($t0)
		lw $t8, ($t3)
		bne $t7, $t8, load_BufferToScreen
		addi $t0, $t0, 4
		addi $t3, $t3, 4
		j loadBufferLoop
		
load_BufferToScreen:
		sw $t7, ($t3)
		addi $t0, $t0, 4
		add $t3, $t3, 4
		j loadBufferLoop
		
end_loadBufferLoop:
		jr $ra
		

# --- Background painter function ---
bgPaint:	lw $t0, skyblue # $t0 stores the sky blue color
		addi $t1, $s0, 0 # $t1 is the loop variable which will start as the base address of the buffer

bgPaintLoop:	beq $t1, $s1, end_bgPaintLoop # Loop ends when $t0 == $t2 which is the last address value for display
		sw $t0, 0($t1) # Paint the pixel at memory address of loop variable $t1 with skyblue color value from $t0
		addi $t1, $t1, 4 # Increment $t1 by 4 (the spacing of the memory addresses for each display pixel)
		j bgPaintLoop
		
end_bgPaintLoop:
		jr $ra

# --- Platform maker function ---
#  - Input $a1 the left-most address from where to start building the platform
MakePlatform:	lw $t0, limegreen # $t0 stores the limegreen color
		sw $t0, ($a1)
		sw $t0, 4($a1)
		sw $t0, 8($a1)
		sw $t0, 12($a1)
		sw $t0, 16($a1)
		sw $t0, 20($a1)
		sw $t0, 24($a1)
		sw $t0, 28($a1)
		jr $ra
		
# --- Doodle maker function ---
#  - Input $a1 the location of the base from where to draw the doodle
MakeDoodle:	lw $t0, yellow # $t0 stores yellow color for the doodle
		sw $t0, ($a1) #middle leg
		sw $t0, -8($a1) # left leg
		sw $t0, 8($a1) # right leg
		
		#Body base
		sw $t0, -128($a1)
		sw $t0, -132($a1)
		sw $t0, -136($a1)	
		sw $t0, -124($a1)
		sw $t0, -120($a1)
		
		#Body trunk
		lw $t1, black # Store black color into $t1
		sw $t1, -256($a1)
		sw $t0, -260($a1)
		sw $t0, -252($a1)
		
		#Body top
		sw $t0, -384($a1)
		sw $t0, -380($a1)
		sw $t0, -388($a1)
		sw $t0, -392($a1)		
		
		jr $ra
		
# --- Move up ---
#  - Input $a0 the current location of the doodle
#  - Return $v0 the updated location of the doodle
moveUp:		addi $v0, $a0, -128

# --- Move down ---
#  - Input $a0 the current location of the doodle
#  - Return $v0 the updated location of the doodle
moveDown:	addi $v0, $a0, 128

# --- Bounce ---
#  - 
bounce:		# Move up 12 "blocks"

		
