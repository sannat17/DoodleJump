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
	entity_cache: .word 0x10070000
	skyblue: .word 0x87ceeb
	limegreen: .word 0xc7ea46
	yellow: .word 0xffd400
	black: .word 0x000000
.text
	lw $s0, bufferAddress # $s0 stores base address for the buffer
	addi $s1, $s0, 4096 # $s1 stores the last address value for buffer
	
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

# === Create buffer using information from cache ===
cache_to_buffer:
		lw $t0, entity_cache # Set $t0 to base address of the entity cache
		lw $t1, bufferAddress # Set $t1 as the base address of the buffer cache
		addi $t2, $t0, 4096 # $t3 will be the loop termination value of the increment
		
	# First paint the background by calling bgPaint
		subi $sp, $sp, 4	# Move Stack pointer to prepare for push
		sw $sp, ($ra)		# ... Push return address of current function $ra onto the stack
		jal bgPaint
		sw $ra, ($sp)		# Pop our stored return address from top of stack and assign it to $ra
		addi $sp, $sp, 4	# Move the stack pointer $sp to reflect the pop	
	
	#Now load entities from entity_cache
	
	# How to read cache values:
	#  0: Background (empty)
	#  1: Doodle base (middle leg)
	#  2: Platform
	#  3: Platform AND doodle base
cache_tb_loop:	beq $t0, $t2, end_ctb_loop
		lw $t3, ($t0) # Set $t3 to be the entity value stored in cache (a platform, doodle, etc.)
		beq $t3, 0, bg_ctb
		beq $t3, 1, doodle_ctb
		beq $t3, 2, platform_ctb
		beq $t3, 3, doodle_ctb
ctb_loop_cont:	addi $t0, $t0, 4
		addi $t1, $t1, 4
		j cache_tb_loop

bg_ctb:		j ctb_loop_cont
		
doodle_ctb:	move $a1, $t1		# Set argument for MakeDoodle function as $t1 which is where the ...
					# ... doodle's base should be in the buffer
		subi $sp, $sp, 4	# Move Stack pointer to prepare for push
		sw $sp, ($ra)		# ... Push return address of current function $ra onto the stack
		jal MakeDoodle
		sw $ra, ($sp)		# Pop our stored return address from top of stack and assign it to $ra
		addi $sp, $sp, 4	# Move the stack pointer $sp to reflect the pop	
		j ctb_loop_cont
		
platform_ctb:	sw $t4, limegreen
		sw $t4, ($t1)
		j ctb_loop_cont

end_ctb_loop:	jr $ra

# === Load Buffer ===
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
		

# === Background painter function ===
#  - Note: This paints the background in the buffer and not the main display
bgPaint:	lw $t0, skyblue # $t0 stores the sky blue color
		addi $t1, $s0, 0 # $t1 is the loop variable which will start as the base address of the buffer

bgPaintLoop:	beq $t1, $s1, end_bgPaintLoop # Loop ends when $t0 == $t2 which is the last address value for display
		sw $t0, 0($t1) # Paint the pixel at memory address of loop variable $t1 with skyblue color value from $t0
		addi $t1, $t1, 4 # Increment $t1 by 4 (the spacing of the memory addresses for each display pixel)
		j bgPaintLoop
		
end_bgPaintLoop:
		jr $ra

# === Platform maker function ===
#  - Input $a1 the left-most address from where to start building the platform
#  - Platform is made into entity cache by storing it's location values as 2
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
		
# === Doodle maker function ===
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
		
# === Move up ===
#  - Input $a0 the current location of the doodle
#  - Return $v0 the updated location of the doodle (moved up)
moveUplw 	$t0, ($a0) # Store into $t0 the cache value at $a0 which is 1 or 3 if the doodle exists there
		subi $t0, $t0, 1 # Subtracting 1 from the cache value tells us if there should be bg or platform when doodle moves
		sw $t0, ($a0) # Store what should be at $a0 in cache when doodle moves
		
		lw $t0, -128($a0) # Load the value from cache right above the doodle's current location at $a0
		addi $t0, $t0, 1 # Add 1 to that value to show now there should be a doodle or doodle + platform
		sw $t0, -128($a0) # Store this updated value to reflect existence of doodle right above current location
		
		addi $v0, $a0, -128 # Return in $v0 what the new location of the doodle should be (moved up)
		jr $ra

# === Move down ===
#  - Input $a0 the current location of the doodle
#  - Return $v0 the updated location of the doodle (moved down)
moveDown:	lw $t0, ($a0) # Store into $t0 the cache value at $a0 which is 1 or 3 if the doodle exists there
		subi $t0, $t0, 1 # Subtracting 1 from the cache value tells us if there should be bg or platform when doodle moves
		sw $t0, ($a0) # Store what should be at $a0 in cache when doodle moves
		
		lw $t0, 128($a0) # Load the value from cache right under the doodle's current location at $a0
		addi $t0, $t0, 1 # Add 1 to that value to show now there should be a doodle or doodle + platform
		sw $t0, 128($a0) # Store this updated value to reflect existence of doodle right below current location
		
		addi $v0, $a0, 128 # Return in $v0 what the new location of the doodle should be (moved down)
		jr $ra


# === Bounce ===
#  - Input $a0 as the current location of the doodle (in cache)
#  - This function will update the location in cache, move the cache to buffer and load the new buffer to screen
#  - Output $v1 as the updated location of the dooodle in cache
bounce:		

		
