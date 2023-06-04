#####################################################################
#
# CSCB58 Winter 2023 Assembly Final Project
# University of Toronto, Scarborough
#
# Student: Zhiyu Pan, 1007624894, panzhiy5, chloezhiyu.pan@mail.utoronto.ca
#
# Bitmap Display Configuration:
# - Unit width in pixels: 4 (update this as needed)
# - Unit height in pixels: 4 (update this as needed)
# - Display width in pixels: 512 (update this as needed)
# - Display height in pixels: 256 (update this as needed)
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestones have been reached in this submission?
# all
#
# Which approved features have been implemented for milestone 3?
# (See the assignment handout for the list of additional features)
# 1. health display
# 2. double jump
# 3. moving platform
# 4. shoot enemies
# 5. enemise shoot back
#
# Link to video demonstration for final submission:
# - https://play.library.utoronto.ca/watch/629bedd99c7d1e88f0ff64f818deadc0
#
# Are you OK with us sharing the video with people outside course staff?
# - yes
#
# Any additional information that the TA needs to know:
# - I have a bug that i cannot solve, sometimes the player will fail standing on the platform, and it will just go through it.
# But sometimes it works. It seems very difficult to jump on one platform, but I am sure it is feasible.
# I really tried :( 
#####################################################################
.eqv BACKGROUND_COLOR	0xffffff  #color white
.eqv BASE_ADDRESS 	0x10008000
.eqv CANVAS_WIDTH 	128
.eqv CANVAS_HEIGHT 	64
.eqv BLACK 		0x000000
.eqv YELLOW		0xffc107
.eqv RED 		0xed1c24
.eqv GREEN		0x9e9d24
.eqv BLUE0		0x385e72
.eqv BLUE1		0x6aabd2
.eqv BLUE2		0xb7cfdc
.eqv BLUE3		0xd9e4ec
.eqv BEAR_BLOOD		8


.data
	str1:.asciiz "you won!!\n"
	str3:.asciiz "you lose!!\n"
	str2:.asciiz "I am here!\n"
	spancer: .space 36000 
	
	# indicate each platform is rising or falling
	platform_state: .word 0, 0, 0
	
	# indicate which platform is standing
	# 0 represent not standing
	# 4 represent standing on the ground
	player_standing_state: .word 0 
	
	# 1 represent cannot go left
	# 2 represent cannot go right
	platform_block: .word 0
	
	heart_count: .word 3
	
	player_bullet: .word 0 0 0 0 0 0 0 0 0 0  
	
	bear_bullet: .word 0 0 0 0 0 0
	
	bear_blood: .word BEAR_BLOOD
	
	double_jump: .word 0
	
	# when equals 1, indicate platform will not update in current loop
	loop_count: .word 0

.text
	
.globl main

main: 
	j starting

		
starting:
	li $t1, 0
	# initilize data values
	la $t0, loop_count
	sw $t1, 0($t0)
	
	la $t0, platform_state
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	
	la $t0, bear_bullet
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	
	la $t0, player_bullet
	sw $t1, 0($t0)
	sw $t1, 4($t0)
	sw $t1, 8($t0)
	sw $t1, 12($t0)
	sw $t1, 16($t0)
	sw $t1, 20($t0)
	sw $t1, 24($t0)
	sw $t1, 28($t0)
	sw $t1, 32($t0)
	sw $t1, 36($t0)
	
	li $t1, BEAR_BLOOD
	la $t0, bear_blood
	sw $t1, 0($t0)
	
	li $t1, 3
	la $t0, heart_count
	sw $t1, 0($t0)

	# draw initial positions of players and platforms
	addi $s0, $zero, BASE_ADDRESS 
	addi $s0, $s0, 5120
	addi $s1, $s0, 2048
	addi $s2, $s1, 7828
	addi $s3, $s2, 5780
	addi $s0, $s1, -6144	
	
	jal draw_background
	jal draw_bear
	jal draw_player
	jal draw_hearts	
	
	starting_loop:
		li $t9, 0xffff0000		# check keyboard
		lw $t8, 0($t9)
		beq $t8, 1, loop1
		li $v0, 32
		addi $a0, $zero, 100
		syscall
		j starting_loop

loop1:
	li $v0, 32
	addi $a0, $zero, 80
	syscall
	
	jal update_player_bullets
	jal update_bear_bullets
	
	jal player_platform # update platform/ground and player collision state
	
	jal check_platform_block
	
	jal standing_check # else check if player is standing on platform or not
	jal check_key
	jal update_platforms
	jal update_loop_count
	
	j loop2

loop2:
	li $v0, 32
	addi $a0, $zero, 80
	syscall
	
	jal update_player_bullets
	
	jal check_squeez
	jal check_key
	
	jal update_loop_count
	j loop3
	
loop3:
	li $v0, 32
	addi $a0, $zero, 80
	syscall
	
	jal update_player_bullets
	
	jal check_squeez
	jal check_key
	
	jal update_loop_count
	j loop1
	
	
	
update_loop_count:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra

	la $t0, loop_count
	lw $t1, 0($t0)
	beq $t1, 100, new_loop
	
	addi $t1, $t1, 1
	sw $t1, 0($t0)
	
	lw $ra, 0($sp) # pop $ra
	addi $sp, $sp, 4
	jr $ra
	
	
	new_loop:
		jal add_new_bear_bullet
		la $t0, loop_count
		li $t1, 0
		sw $t1, 0($t0)
		
		lw $ra, 0($sp) # pop $ra
		addi $sp, $sp, 4
		jr $ra
	
		

check_platform_block:
	sub $t1, $s0, $s1
	sub $t2, $s0, $s2
	sub $t3, $s0, $s3
	
	li $t0, 1616
	li $t4, 1488
	
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right

	addi $t0, $t0, -512
	addi $t4, $t4, -512
	
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	addi $t0, $t0, -512
	addi $t4, $t4, -512
	beq $t1, $t0, cannot_left
	beq $t2, $t0, cannot_left
	beq $t2, $t4, cannot_right
	beq $t3, $t4, cannot_right
	
	li $t2, 0
	j return_platform_block
	
	cannot_left:
		li $t2, 1 
		j return_platform_block
		
	cannot_right: 
		li $t2, 2
		j return_platform_block
		
	return_platform_block:
		la $t1, platform_block
		sw $t2, 0($t1) # update state
		jr $ra
		
					
check_squeez:
# check if the platform will squeez the player
	
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra
	
	sub $t0, $s0, BASE_ADDRESS
	
	ble $t0, -1024, squeezing
	
	blt $t0, 22016, return_check_squeez

	li $t1,512
	div $t0,$t1
	mfhi $t0
    	
    	blt $t0, 80, check_first
    	
    	sge $t1, $t0, 104
    	sle $t2, $t0, 224
    	and $t1, $t1, $t2
    	
    	beq $t1, 1, check_second
    	
    	bge $t0, 252, check_third
    	
    	j return_check_squeez
    	
    	check_first:
    		sub $t1, $s1, BASE_ADDRESS
		bge $t1, 20480, squeezing
		j return_check_squeez
		
	check_second:
    		sub $t1, $s2, BASE_ADDRESS
		bge $t1, 20480, squeezing
		j return_check_squeez
		
	check_third:
    		sub $t1, $s3, BASE_ADDRESS
		bge $t1, 20480, squeezing
		j return_check_squeez
    	
    	squeezing:
		jal erase_hearts
		jal erase
		addi $s0, $zero, 22100
		addi $s0, $s0, BASE_ADDRESS
		jal draw_player
		j return_check_squeez
    	
	return_check_squeez:
		lw $ra, 0($sp) # pop $ra
		addi $sp, $sp, 4
		jr $ra 


standing_check:	 # get player-platform collision state
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra

	la $t1, player_standing_state # $t1 holds the address of player state
	lw $t2, 0($t1) # load state
	beqz $t2, gravity # if player is not standing on platform, then gravity is pulling
	
	# else, player is standing on the platform 
	j standing	


gravity:
	jal erase
	sub $t0, $s0, BASE_ADDRESS
	bge $t0, 21504, gravity_else
	addi $s0, $s0, 512
	j standing_check_return
	
	gravity_else:
		addi $s0, $s0, 512
		j standing_check_return
			
standing:
	la $t1, player_standing_state # $t1 holds the address of player state
	lw $t2, 0($t1) # load which platform is standing on 
	
	beq $t2, 4, standing_check_return # if standing on the ground, check key

	la $t1, platform_state 
	addi $t2, $t2, -1
	sll $t2, $t2, 2 # get offset
	add $t1, $t1, $t2
	
	
	lw $t2, 0($t1) # get the state of the standing platform
	beqz $t2, falling # if the platform is falling, 
	beq $t2, 1, rising
	j standing_check_return

	rising:
		jal erase
		addi $s0, $s0, -512
		j standing_check_return
	
	falling:
		jal erase
		addi $s0, $s0, 512
		j standing_check_return

								
standing_check_return:
	lw $ra, 0($sp) # pop $ra
	addi $sp, $sp, 4
	jr $ra
	
			
check_key:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra

	li $t9, 0xffff0000		# check keyboard
	lw $t8, 0($t9)
	beq $t8, 1, key_pressed
	jal draw_player
	j check_key_return
	
key_pressed:
	lw $t4, 4($t9)	# checks which key is pressed
	
	beq $t4, 119, wPressed
	# if w is not pressed
	
	la $t3, double_jump # load double jump state
	li $t1, 0
	sw $t1, 0($t3) # modify double jump state
	
	# then check other keys
	beq $t4, 100, dPressed
	beq $t4, 97, aPressed
	beq $t4, 32, spacePressed
	beq $t4, 112, starting # q pressed
	j check_key_return
	
	dPressed:
		jal erase
		sub $t0, $s0, BASE_ADDRESS 
		li $t1,512
		div $t0,$t1
		mfhi $t0
		beq $t0, 352, draw_newplayer
		
		la $t1, platform_block
		lw $t2, 0($t1)
		beq $t2, 2, draw_newplayer
		
		addi $s0, $s0, 4
		j draw_newplayer
	
	
	aPressed:
		jal erase
		
		sub $t0, $s0, BASE_ADDRESS 
		li $t1,512
		div $t0,$t1
		mfhi $t0
		beq $t0, 0, draw_newplayer
		
		la $t1, platform_block
		lw $t2, 0($t1)
		beq $t2, 1, draw_newplayer
		
		addi $s0, $s0, -4
		j draw_newplayer

	wPressed:
		jal erase
		la $t1, player_standing_state # load player state
		lw $t2, 0($t1) 
		la $t3, double_jump # load double jump state
		lw $t4, 0($t3) 
		
		beq $t4, 1, double_jumping
		
		bnez $t2, jump # else if player is standing, jump 
		
		j draw_newplayer # else cannot jump
		
		double_jumping:
			li $t4, 0
			sw $t4, 0($t3) # update double jump state
			addi $s0, $s0, -3072
			j draw_newplayer
		
		jump:
			li $t4, 1
			sw $t4, 0($t3) # update double jump state
			addi $s0, $s0, -5120
			j draw_newplayer
		
	spacePressed:
		jal add_new_player_bullet
		jal erase
		j draw_newplayer

	draw_newplayer:
		jal draw_player
		j check_key_return
		
check_key_return:
	lw $ra, 0($sp) # pop $ra
	addi $sp, $sp, 4
	jr $ra
	
		
update_platforms:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra

	la $a1, platform_state # get platform state address 
	
	lw $a2, 0($a1) # load first state
	
	addi $sp, $sp, -4
	sw $s1, 0($sp) # push location of platform
	addi $sp, $sp, -4
	sw $a2, 0($sp) # push state of platform
	jal move_platform
	lw $a2, 0($sp) # pop new state of platform
	addi $sp, $sp, 4
	
	sw $a2, 0($a1) # update state
	lw $s1, 0($sp) # pop new location of platform
	addi $sp, $sp, 4
	
	lw $a2, 4($a1) # load second state
	addi $sp, $sp, -4
	sw $s2, 0($sp) # push location of platform
	addi $sp, $sp, -4
	sw $a2, 0($sp) # push state of platform
	jal move_platform
	lw $a2, 0($sp) # pop new state of platform
	sw $a2, 4($a1) # update state
	addi $sp, $sp, 4
	lw $s2, 0($sp) # pop new location of platform
	addi $sp, $sp, 4
	
	lw $a2, 8($a1) # load second state
	addi $sp, $sp, -4
	sw $s3, 0($sp) # push location of platform
	addi $sp, $sp, -4
	sw $a2, 0($sp) # push state of platform
	jal move_platform
	lw $a2, 0($sp) # pop new state of platform
	sw $a2, 8($a1) # update state
	addi $sp, $sp, 4
	lw $s3, 0($sp) # pop new location of platform
	addi $sp, $sp, 4
	
	lw $ra, 0($sp) # pop $ra
	addi $sp, $sp, 4
	jr $ra


# check if player stand on the platform	or on the ground
player_platform:
	
	# check if player is standing on the ground
	add $t3, $zero, 4
	sub $t0, $s0, BASE_ADDRESS
	bge $t0, 22016, return_playerstate
	j check_platform1
	
	check_platform1:
		add $t3, $zero, 1 # check first platform
		sub $t0, $s1, $s0
		ble $t0, 6076, check_platform2
		bge $t0, 6148, check_platform2
		j return_playerstate
	
	check_platform2:
		add $t3, $zero, 2 # check second platform
		sub $t0, $s2, $s0
		ble $t0, 6076, check_platform3
		bge $t0, 6180, check_platform3
		j return_playerstate
		
	check_platform3:
		add $t3, $zero, 3 # check second platform
		sub $t0, $s3, $s0
		ble $t0, 6084, not_standing
		bge $t0, 6180, not_standing
		j return_playerstate
		
	not_standing:
		add $t3, $zero, 0 # check second platform
		j return_playerstate
	
	return_playerstate:
		la $t1, player_standing_state #  $t1 holds the address of player state
		sw $t3, 0($t1)
		jr $ra

add_new_bear_bullet:
	la $a1, bear_bullet # get bullets array
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra
	
	search_space_bear:
		lw $a2, 0($a1) # load array 
		beq $a2, -1, found_space_bear
		beq $a2, 0, found_space_bear
		addi $a1, $a1, 4 # if not found, check next element
		j search_space_bear
		
	found_space_bear:
		sub $t0, $s0, BASE_ADDRESS 
		li $t1,512
		div $t0,$t1
		mflo $t0
		
		mul $t0, $t0, 512
		add $t0, $t0, BASE_ADDRESS 
		addi $t0, $t0, -140
		addi $t0, $t0, 1024
		
		addi $sp, $sp, -4
		sw $t0, 0($sp) # push new location 
		jal draw_bear_bullet # draw new bullet
		sw $t0, 0($a1)
		
		lw $ra, 0($sp) # pop $ra
		addi $sp, $sp, 4
		jr $ra

add_new_player_bullet:
	la $a1, player_bullet # get bullets array
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra
	
	search_space:
		lw $a2, 0($a1) # load array 
		beq $a2, -1, found_space
		beq $a2, 0, found_space
		addi $a1, $a1, 4 # if not found, check next element
		j search_space
		
	found_space:
		addi $t1, $s0, 2100
		addi $sp, $sp, -4
		sw $t1, 0($sp) # push new location 
		jal draw_player_bullet # draw new bullet
		sw $t1, 0($a1)
		
		lw $ra, 0($sp) # pop $ra
		addi $sp, $sp, 4
		jr $ra

			
update_bear_bullets:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra
	
	la $a1, bear_bullet # get bullets array
	
	update_bear_bullets_loop:
		lw $a2, 0($a1) # load first state
		beqz $a2, break_update_bear_bullets
		beq $a2, -1, skip_bear_bullet
		
		
		addi $sp, $sp, -4
		sw $a2, 0($sp) # push current location 
		jal erase_bear_bullet
		
		sub $t4, $a2, $s0
		
		
		addi $a2, $a2, -4 # set new location
		sub $t0, $a2, $s0
		beq $t0, -2008, hit_player
		beq $t0, -1496, hit_player
		beq $t0, -984, hit_player
		beq $t0, -472, hit_player
		beq $t0, 40, hit_player
		beq $t0, 552, hit_player
		beq $t0, 1064, hit_player
		beq $t0, 1576, hit_player
		beq $t0, 2088, hit_player
		beq $t0, 2600, hit_player
		beq $t0, 3112, hit_player
		beq $t0, 3624, hit_player
		beq $t0, 4136, hit_player
		beq $t0, 4648, hit_player
		
		sub $t0, $a2, BASE_ADDRESS
		li $t1,512
		div $t0,$t1
		mfhi $t0
		beq $t0, 4, bear_bullet_gone
		
		addi $sp, $sp, -4
		sw $a2, 0($sp) # push new location 
		jal draw_bear_bullet # draw new bullet
		sw $a2, 0($a1) # update bullet array
		addi $a1, $a1, 4
		j update_bear_bullets_loop
	
	bear_bullet_gone:
		li $a2, -1
		sw $a2, 0($a1) # update bullet array
		addi $a1, $a1, 4
		j update_bear_bullets_loop
			
	hit_player:
		li $a2, -1
		sw $a2, 0($a1) # update bullet array
		addi $a1, $a1, 4
		
		jal erase_hearts
		
		j update_bear_bullets_loop
		
	skip_bear_bullet:
		addi $a1, $a1, 4
		j update_bear_bullets_loop
		
	break_update_bear_bullets:
		lw $ra, 0($sp) # pop $ra
		addi $sp, $sp, 4
		jr $ra	
				


	
			
						
update_player_bullets:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra
	
	la $a1, player_bullet # get bullets array
	
	update_player_bullets_loop:
		lw $a2, 0($a1) # load first state
		beqz $a2, break_update_player_bullets
		beq $a2, -1, skip_bullet
		addi $sp, $sp, -4
		sw $a2, 0($sp) # push current location 
		jal erase_player_bullet
		
		sub $t0, $a2, BASE_ADDRESS 
		li $t1,512
		div $t0,$t1
		mfhi $t0
		bge $t0, 380, hit
		
		addi $a2, $a2, 4 # set new location
		addi $sp, $sp, -4
		sw $a2, 0($sp) # push new location 
		jal draw_player_bullet # draw new bullet
		sw $a2, 0($a1) # update bullet array
		addi $a1, $a1, 4
		j update_player_bullets_loop
		
	hit:	
		jal got_hit
		addi $a2, $zero, -1
		sw $a2, 0($a1) # update bullet array
		addi $a1, $a1, 4
		j update_player_bullets_loop
		
	skip_bullet:
		addi $a1, $a1, 4
		j update_player_bullets_loop
		
	break_update_player_bullets:
		lw $ra, 0($sp) # pop $ra
		addi $sp, $sp, 4
		jr $ra	
				


got_hit:
	la $t7, bear_blood
	lw $t6, 0($t7) # get current blood
	beq $t6, 1, winning
	addi $t6, $t6, -1
	sw $t6, 0($t7) # update
	jr $ra
	

winning:
	# Print prompt 
	li $v0, 4
	la $a0, str1
	syscall
	
	j exit
	


# takes the current location and the state of the platform
# return the update location and the state
# if state = 0, moving down
# if state = 1, moving up
# if state = 2, at high position
# if state = 3, at low position	
move_platform:
	lw $t1, 0($sp) # pop current state of platform
	addi $sp, $sp, 4
	lw $t0, 0($sp) # pop current location of platform
	addi $sp, $sp, 4
	
	addi $t2, $zero, BASE_ADDRESS
	addi $t2, $t2, 512 # set upper bound 
	addi $t3, $t2, 25084	# set lower bound
	
	
	
	# check the old state of platform
	beq $t1, $zero, move_down
	beq $t1, 1, move_up
	beq $t1, 2, stay_high
	beq $t1, 3, stay_low
	
	
	move_down:
	
		addi $sp, $sp, -4
		sw $ra, 0($sp) # store $ra
		
		addi $sp, $sp, -4
		sw $t0, 0($sp) # push current location of platform
		
		jal erase_platform # erase 
		
		addi $t0, $t0, 512 # update new location 
		
		bgt $t0, $t3, low_position # if updated location is too low
		j draw_new_platform	
			
		low_position:
			addi $t1, $zero, 3 # modify following state to stay low
			j draw_new_platform
		
	move_up:
		
		addi $sp, $sp, -4
		sw $ra, 0($sp) # store $ra
		
		addi $sp, $sp, -4
		addi $t4, $t0, 1536
		sw $t4, 0($sp) # push location for the last line
		
		jal erase_platform # erase it
		
		addi $t0, $t0, -512 # update new location 
		
		blt $t0, $t2, high_position # if updated location is too high	
		j draw_new_platform
			
		high_position:
			addi $t1, $zero, 2 # modify following state to stay high
			j draw_new_platform

	
	stay_high:
		addi $t1, $zero, 0 # modify following state to 0
		j return_platform
			
		
	stay_low:
		addi $t1, $zero, 1 # modify following state to 1
		j return_platform
	
		
	draw_new_platform:
		addi $sp, $sp, -4
		sw $t0, 0($sp) # push new location of platform
		
		jal draw_platform
		
		lw $ra, 0($sp)
		addi $sp, $sp, 4 #restore $ra
		
		j return_platform
		
	return_platform:
		addi $sp, $sp, -4
		sw $t0, 0($sp) # push new location of platform
		
		addi $sp, $sp, -4
		sw $t1, 0($sp) # push new state of platform
		
		jr $ra
	


draw_hearts:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra
	
	addi $t0, $zero, BASE_ADDRESS 
	addi $t0, $t0, 28676
	
	addi $sp, $sp, -4
	sw $t0, 0($sp) # push location of platform
	jal draw_heart
	
	addi $t0, $t0, 40
	
	addi $sp, $sp, -4
	sw $t0, 0($sp) # push location of platform
	jal draw_heart
	
	addi $t0, $t0, 40
	
	addi $sp, $sp, -4
	sw $t0, 0($sp) # push location of platform
	jal draw_heart
	
	lw $ra, 0($sp) # pop $ra
	addi $sp, $sp, 4
	
	jr $ra

erase_hearts:
	addi $sp, $sp, -4
	sw $ra, 0($sp) # save $ra

	la $t1, heart_count # $t1 holds the address of hear count
	lw $t2, 0($t1) # load how many lives player has
	
	addi $t0, $zero, BASE_ADDRESS 
	addi $t0, $t0, 28676
	
	addi $t2, $t2, -1
	sw $t2, 0($t1) # update lives
	
	beqz $t2, lose
	
	addi $t3, $zero, 40
	mult $t2, $t3
	mflo $t3
	
	addu $t0, $t0, $t3
	
	addi $sp, $sp, -4
	sw $t0, 0($sp) # push location of platform
	jal erase_heart
	
	lw $ra, 0($sp) # pop $ra
	addi $sp, $sp, 4
	
	jr $ra

lose: 
	addi $t0, $zero, BASE_ADDRESS 
	addi $t0, $t0, 28676
	 	
	addi $sp, $sp, -4
	sw $t0, 0($sp) # push location of platform
	jal erase_heart

	# Print prompt 
	li $v0, 4
	la $a0, str3
	syscall
	
	j exit


# takes	the platform location 
draw_platform:
	lw $t7, 0($sp) # pop current location of platform
	addi $sp, $sp, 4
	
	li $t6, BLUE0
	li $t5, BLUE1
		
	sw $t6, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t6, 28($t7)
	sw $t6, 32($t7)
	sw $t6, 36($t7)
	sw $t6, 40($t7)
	sw $t6, 44($t7)
	sw $t6, 48($t7)
	sw $t6, 52($t7)
	sw $t6, 56($t7)
	sw $t6, 60($t7)
	sw $t6, 64($t7)
	sw $t6, 68($t7)
	sw $t6, 72($t7)
	sw $t6, 76($t7)
	
	addi $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t5, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t5, 16($t7)
	sw $t5, 20($t7)
	sw $t5, 24($t7)
	sw $t5, 28($t7)
	sw $t5, 32($t7)
	sw $t5, 36($t7)
	sw $t5, 40($t7)
	sw $t5, 44($t7)
	sw $t5, 48($t7)
	sw $t5, 52($t7)
	sw $t5, 56($t7)
	sw $t5, 60($t7)
	sw $t5, 64($t7)
	sw $t5, 68($t7)
	sw $t5, 72($t7)
	sw $t5, 76($t7)
	
	addi $t7, $t7, 512
	li $t5, BLUE2
	
	sw $t5, 0($t7)
	sw $t5, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t5, 16($t7)
	sw $t5, 20($t7)
	sw $t5, 24($t7)
	sw $t5, 28($t7)
	sw $t5, 32($t7)
	sw $t5, 36($t7)
	sw $t5, 40($t7)
	sw $t5, 44($t7)
	sw $t5, 48($t7)
	sw $t5, 52($t7)
	sw $t5, 56($t7)
	sw $t5, 60($t7)
	sw $t5, 64($t7)
	sw $t5, 68($t7)
	sw $t5, 72($t7)
	sw $t5, 76($t7)
	
	addi $t7, $t7, 512
	li $t5, BLUE3
	
	sw $t5, 0($t7)
	sw $t5, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t5, 16($t7)
	sw $t5, 20($t7)
	sw $t5, 24($t7)
	sw $t5, 28($t7)
	sw $t5, 32($t7)
	sw $t5, 36($t7)
	sw $t5, 40($t7)
	sw $t5, 44($t7)
	sw $t5, 48($t7)
	sw $t5, 52($t7)
	sw $t5, 56($t7)
	sw $t5, 60($t7)
	sw $t5, 64($t7)
	sw $t5, 68($t7)
	sw $t5, 72($t7)
	sw $t5, 76($t7)
	
	addi $t7, $t7, -1536
	
	jr $ra
		

erase_platform:
	lw $t7, 0($sp) # pop current location of platform
	addi $sp, $sp, 4
	
	li $t6, BACKGROUND_COLOR
			
	sw $t6, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t6, 28($t7)
	sw $t6, 32($t7)
	sw $t6, 36($t7)
	sw $t6, 40($t7)
	sw $t6, 44($t7)
	sw $t6, 48($t7)
	sw $t6, 52($t7)
	sw $t6, 56($t7)
	sw $t6, 60($t7)
	sw $t6, 64($t7)
	sw $t6, 68($t7)
	sw $t6, 72($t7)
	sw $t6, 76($t7)
	jr $ra

	
draw_player_bullet:
	lw $t7, 0($sp) # pop current location of the bullet
	addi $sp, $sp, 4
			
	li $t6, YELLOW
	li $t5, RED
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t5, 4($t7)
	sw $t6, 8($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	add $t7, $t7, 512
	
	jr $ra
	
draw_bear_bullet:
	lw $t7, 0($sp) # pop current location of the bullet
	addi $sp, $sp, 4
			
	li $t6, YELLOW
	li $t5, RED
	
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 0($t7)
	sw $t5, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	
	jr $ra
	
erase_player_bullet:
	lw $t7, 0($sp) # pop current location of the bullet
	addi $sp, $sp, 4
			
	li $t6, BACKGROUND_COLOR
	li $t5, BACKGROUND_COLOR
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t5, 4($t7)
	sw $t6, 8($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	add $t7, $t7, 512
	
	jr $ra

erase_bear_bullet:
	lw $t7, 0($sp) # pop current location of the bullet
	addi $sp, $sp, 4
			
	li $t6, BACKGROUND_COLOR
	li $t5, BACKGROUND_COLOR
	
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 0($t7)
	sw $t5, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 12($t7)
	sw $t6, 16($t7)
	add $t7, $t7, 512
	
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	
	jr $ra
	
			
									
draw_heart:
	lw $t7, 0($sp) # pop targeted location of the heart
	addi $sp, $sp, 4
		
	li $t6, BACKGROUND_COLOR
	li $t5, BLUE0
	
	sw $t5, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 20($t7)
	sw $t5, 24($t7)
	add $t7, $t7, 512

	sw $t5, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t5, 12($t7)
	sw $t5, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t5, 28($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t5, 28($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t5, 28($t7)
	add $t7, $t7, 512
	
	sw $t5, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t5, 24($t7)
	add $t7, $t7, 512
	
	
	sw $t5, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t5, 20($t7)
	add $t7, $t7, 512
	

	sw $t5, 12($t7)
	sw $t5, 16($t7)
	add $t7, $t7, 512

	jr $ra

erase_heart:
	lw $t7, 0($sp) # pop location of the targeted heart
	addi $sp, $sp, 4
		
	li $t6, BLUE1
	li $t5, BLUE1
	
	sw $t5, 4($t7)
	sw $t5, 8($t7)
	sw $t5, 20($t7)
	sw $t5, 24($t7)
	add $t7, $t7, 512

	sw $t5, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t5, 12($t7)
	sw $t5, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t5, 28($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t5, 28($t7)
	add $t7, $t7, 512
	
	sw $t5, 0($t7)
	sw $t6, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t6, 24($t7)
	sw $t5, 28($t7)
	add $t7, $t7, 512
	
	sw $t5, 4($t7)
	sw $t6, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t6, 20($t7)
	sw $t5, 24($t7)
	add $t7, $t7, 512
	
	
	sw $t5, 8($t7)
	sw $t6, 12($t7)
	sw $t6, 16($t7)
	sw $t5, 20($t7)
	add $t7, $t7, 512
	

	sw $t5, 12($t7)
	sw $t5, 16($t7)
	add $t7, $t7, 512

	jr $ra


# assume the start location of player stored in $s0
draw_player:	
	#load colours
	li $t0, BLACK
	li $t1, GREEN
	li $t2, YELLOW
	
	sw $t0, 16($s0)
	sw $t0, 20($s0)
	sw $t0, 24($s0)
	sw $t0, 28($s0)
	add $s0, $s0, 512
	sw $t0, 12($s0)
	sw $t0, 16($s0)
	sw $t0, 20($s0)
	sw $t0, 24($s0)
	sw $t0, 28($s0)
	sw $t0, 32($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 12($s0)
	sw $t0, 32($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 16($s0)
	sw $t0, 28($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 16($s0)
	sw $t0, 28($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t2, 20($s0)
	sw $t2, 24($s0)
	sw $t0, 36($s0)
	sw $t0, 40($s0)
	add $s0, $s0, 512
	sw $t0, 0($s0)
	sw $t0, 4($s0)
	sw $t0, 40($s0)
	sw $t0, 44($s0)
	add $s0, $s0, 512	
	sw $t0, 0($s0)
	sw $t0, 4($s0)
	sw $t0, 40($s0)
	sw $t0, 44($s0)
	add $s0, $s0, 512
	sw $t0, 0($s0)
	sw $t0, 4($s0)
	sw $t0, 40($s0)
	sw $t0, 44($s0)
	add $s0, $s0, 512
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 36($s0)
	sw $t0, 40($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t2, 12($s0) 
	sw $t1, 16($s0)
	sw $t0, 20($s0)
	sw $t0, 24($s0)
	sw $t1, 28($s0)
	sw $t2, 32($s0) 
	
	add $s0, $s0, -5632
	
	jr $ra

# erase player
erase:
	# load colours
	li $t0, BACKGROUND_COLOR
	
	sw $t0, 16($s0)
	sw $t0, 20($s0)
	sw $t0, 24($s0)
	sw $t0, 28($s0)
	add $s0, $s0, 512
	sw $t0, 12($s0)
	sw $t0, 16($s0) 
	sw $t0, 20($s0)
	sw $t0, 24($s0)
	sw $t0, 28($s0)
	sw $t0, 32($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 12($s0)
	sw $t0, 32($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 16($s0)
	sw $t0, 28($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 16($s0)
	sw $t0, 28($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 20($s0)
	sw $t0, 24($s0)
	sw $t0, 36($s0)
	sw $t0, 40($s0)
	add $s0, $s0, 512
	sw $t0, 0($s0)
	sw $t0, 4($s0)
	sw $t0, 40($s0)
	sw $t0, 44($s0)
	add $s0, $s0, 512
	sw $t0, 0($s0)
	sw $t0, 4($s0)
	sw $t0, 40($s0)
	sw $t0, 44($s0)
	add $s0, $s0, 512
	sw $t0, 0($s0)
	sw $t0, 4($s0)
	sw $t0, 40($s0)
	sw $t0, 44($s0)
	add $s0, $s0, 512
	sw $t0, 4($s0)
	sw $t0, 8($s0)
	sw $t0, 36($s0)
	sw $t0, 40($s0)
	add $s0, $s0, 512
	sw $t0, 8($s0)
	sw $t0, 36($s0)
	add $s0, $s0, 512
	sw $t0, 12($s0)
	sw $t0, 16($s0)
	sw $t0, 20($s0)
	sw $t0, 24($s0)
	sw $t0, 28($s0)
	sw $t0, 32($s0) 
	
	add $s0, $s0, -5632
	jr $ra

draw_background:
	li $t5, BACKGROUND_COLOR
	li $t2, CANVAS_WIDTH
	li $t3, CANVAS_HEIGHT
	mult $t3, $t2 			# CANVAS_WIDTH * CANVAS_HEIGHT 
	mflo $t2
	li $t3, 4
	mult $t2,$t3 			# CANVAS_WIDTH * CANVAS_HEIGHT * 4
	mflo $t3
	
	addi $t2, $zero, BASE_ADDRESS 	# t2 = address
	addi $t3, $t3, BASE_ADDRESS 	# t3 = address + CANVAS_WIDTH * CANVAS_HEIGHT * 4
	
	drawbackground_loop:
		beq $t2, $t3, drawbackground_end
		sw $t5, 0($t2)
		addi $t2, $t2, 4
		j drawbackground_loop
	
	drawbackground_end:
		jr $ra

draw_bear:
	# draw bear and colored floor
	li $t0, BLACK # load color black

	addi $t2, $zero, BASE_ADDRESS
	addi $t2, $t2, 5120
	addi $t2, $t2, 408

	sw $t0, 40($t2)
	sw $t0, 44($t2)
	sw $t0, 80($t2)
	sw $t0, 84($t2)
	addi $t2, $t2, 512
	
	sw $t0, 36($t2)
	sw $t0, 48($t2)
	sw $t0, 56($t2)
	sw $t0, 60($t2)
	sw $t0, 64($t2)
	sw $t0, 76($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 36($t2)
	sw $t0, 48($t2)
	sw $t0, 52($t2)
	sw $t0, 68($t2)
	sw $t0, 72($t2)
	sw $t0, 76($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 40($t2)
	sw $t0, 44($t2)
	sw $t0, 84($t2)
	addi $t2, $t2, 512
	
	sw $t0, 36($t2)
	sw $t0, 84($t2)
	addi $t2, $t2, 512
	
	sw $t0, 36($t2)
	sw $t0, 48($t2)
	sw $t0, 64($t2)
	sw $t0, 84($t2)
	addi $t2, $t2, 512
	
	sw $t0, 32($t2)
	sw $t0, 48($t2)
	sw $t0, 64($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 32($t2)
	sw $t0, 48($t2)
	sw $t0, 64($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 20($t2)
	sw $t0, 24($t2)
	sw $t0, 28($t2)
	sw $t0, 32($t2)
	sw $t0, 36($t2)
	sw $t0, 40($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 28($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 20($t2)
	sw $t0, 24($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 20($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 20($t2)
	sw $t0, 24($t2)
	sw $t0, 44($t2)
	sw $t0, 48($t2)
	sw $t0, 88($t2)
	addi $t2, $t2, 512
	
	sw $t0, 28($t2)
	sw $t0, 32($t2)
	sw $t0, 36($t2)
	sw $t0, 40($t2)
	sw $t0, 92($t2)
	addi $t2, $t2, 512
	
	sw $t0, 32($t2)
	sw $t0, 92($t2)
	addi $t2, $t2, 512
	
	sw $t0, 32($t2)
	sw $t0, 92($t2)
	addi $t2, $t2, 512
	
	sw $t0, 28($t2)
	sw $t0, 92($t2)
	addi $t2, $t2, 512
	
	sw $t0, 28($t2)
	sw $t0, 92($t2)
	addi $t2, $t2, 512
	
	sw $t0, 24($t2)
	sw $t0, 96($t2)
	addi $t2, $t2, 512
	
	sw $t0, 24($t2)
	sw $t0, 96($t2)
	addi $t2, $t2, 512
	
	sw $t0, 20($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 20($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 12($t2)
	sw $t0, 68($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 12($t2)
	sw $t0, 72($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 12($t2)
	sw $t0, 72($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 8($t2)
	sw $t0, 76($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 8($t2)
	sw $t0, 76($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
		
	sw $t0, 8($t2)
	sw $t0, 76($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 4($t2)
	sw $t0, 76($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 4($t2)
	sw $t0, 76($t2)
	addi $t2, $t2, 512
	
	sw $t0, 4($t2)
	sw $t0, 76($t2)
	addi $t2, $t2, 512
		
	sw $t0, 4($t2)
	sw $t0, 76($t2)
	addi $t2, $t2, 512
	
	sw $t0, 4($t2)
	sw $t0, 80($t2)
	addi $t2, $t2, 512
	
	sw $t0, 8($t2)
	sw $t0, 80($t2)
	addi $t2, $t2, 512
	
	sw $t0, 8($t2)
	sw $t0, 80($t2)
	addi $t2, $t2, 512
	
	sw $t0, 8($t2)
	sw $t0, 80($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 12($t2)
	sw $t0, 68($t2)
	sw $t0, 84($t2)
	sw $t0, 88($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 20($t2)
	sw $t0, 24($t2)
	sw $t0, 28($t2)
	sw $t0, 56($t2)
	sw $t0, 60($t2)
	sw $t0, 64($t2)
	sw $t0, 92($t2)
	sw $t0, 96($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 32($t2)
	sw $t0, 36($t2)
	sw $t0, 40($t2)
	sw $t0, 44($t2)
	sw $t0, 48($t2)
	sw $t0, 52($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 44($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 16($t2)
	sw $t0, 20($t2)
	sw $t0, 24($t2)
	sw $t0, 28($t2)
	sw $t0, 32($t2)
	sw $t0, 44($t2)
	sw $t0, 48($t2)
	sw $t0, 52($t2)
	sw $t0, 56($t2)
	sw $t0, 60($t2)
	sw $t0, 64($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 12($t2)
	sw $t0, 40($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 512
	
	sw $t0, 12($t2)
	sw $t0, 16($t2)
	sw $t0, 20($t2)
	sw $t0, 24($t2)
	sw $t0, 28($t2)
	sw $t0, 32($t2)
	sw $t0, 36($t2)
	sw $t0, 40($t2)
	sw $t0, 44($t2)
	sw $t0, 48($t2)
	sw $t0, 52($t2)
	sw $t0, 56($t2)
	sw $t0, 60($t2)
	sw $t0, 64($t2)
	sw $t0, 68($t2)
	sw $t0, 72($t2)
	sw $t0, 76($t2)
	sw $t0, 80($t2)
	sw $t0, 84($t2)
	sw $t0, 88($t2)
	sw $t0, 92($t2)
	sw $t0, 96($t2)
	sw $t0, 100($t2)
	addi $t2, $t2, 104
	
	addi $t3, $t2, 4608
	li $t0, BLUE1 # load color blue
	
	floor_loop:
		beq $t2, $t3, floor_end
		sw $t0, 0($t2)
		addi $t2, $t2, 4
		j floor_loop
	
	floor_end:
		jr $ra

	jr $ra

			
exit:
	li $v0, 10 # terminate the program gracefully
	syscall
        
