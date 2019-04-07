extends KinematicBody2D

var type
var grid

#prevents sleep spam
var sleepDelay = 1000 #1 second
var sleepTime = 0

#keeps track of the time of day
var time = 1 #1 morning, 2 afternoon, 3 evening, 4 night

#signal functions
signal sleep()
signal hammer(pos, orientation)
signal seeds(pos)
signal hoe(pos, orienation)
signal sickle(pos, orientation)
signal sickle_circle(pos)

#for animation purposes
var lastAnimation = "down" #for what animation was last played
var facingDirection = "down" #for what direction the player is currently facing
var animationCommit = false #for forcing an animation to play through once it starts

#for basic 2D movement
const MAX_SPEED = 250
var speed = 0
var direction = Vector2()
var velocity = Vector2()
var target_pos = Vector2()
var target_direction = Vector2()
var is_moving = false

func _ready():
	grid = get_parent()
	type = grid.PLAYER
	set_physics_process(true)

func _physics_process(delta):
	direction = Vector2()
	
	if not animationCommit: #if the playing is currently doing an animation, they cannot move
		if Input.is_action_pressed("ui_up"):
			direction.y = -1
		elif Input.is_action_pressed("ui_down"):
			direction.y = 1
		if Input.is_action_pressed("ui_right"):
			direction.x = 1
		elif Input.is_action_pressed("ui_left"):
			direction.x = -1
		
	#sleep
	if Input.is_action_pressed("E") and OS.get_ticks_msec() > sleepTime + sleepDelay:
		emit_signal("sleep")
		sleepTime = OS.get_ticks_msec()
		
	#change time
	if Input.is_action_pressed("K") and OS.get_ticks_msec() > sleepTime + sleepDelay:
		sleepTime = OS.get_ticks_msec()
		if time == 1:
			find_node("Morning").hide()
			find_node("Afternoon").show()
			time += 1
		elif time == 2:
			find_node("Afternoon").hide()
			find_node("Evening").show()
			time += 1
		elif time == 3:
			find_node("Evening").hide()
			find_node("Night").show()
			time += 1
		elif time == 4:
			find_node("Night").hide()
			find_node("Morning").show()
			time = 1
		
	#hammer time
	if Input.is_action_pressed("ui_accept"):
		animationCommit = true
		if facingDirection == "left" or facingDirection == "right":
			lastAnimation = "hammer left"
		elif facingDirection == "down":
			lastAnimation = "hammer down"
		elif facingDirection == "up":
			lastAnimation = "hammer up"
		
	#throw seeds
	if Input.is_action_pressed("T"):
		animationCommit = true
		lastAnimation = "seeds"
		
	#hoe
	if Input.is_action_pressed("H"):
		animationCommit = true
		if facingDirection == "left" or facingDirection == "right":
			lastAnimation = "hoe left"
		elif facingDirection == "down":
			lastAnimation = "hoe down"
		elif facingDirection == "up":
			lastAnimation = "hoe up"
			
	#sickle
	if Input.is_action_pressed("P"):
		animationCommit = true
		if facingDirection == "left" or facingDirection == "right":
			lastAnimation = "sickle left"
		elif facingDirection == "down":
			lastAnimation = "sickle down"
		elif facingDirection == "up":
			lastAnimation = "sickle up"
			
	#sickle circle
	if Input.is_action_pressed("O"):
		animationCommit = true
		lastAnimation = "sickle circle"
		
	if direction != Vector2():
		speed = MAX_SPEED
	else:
		speed = 0
	
	#the player was standing still but has pressed to move to another location
	if not is_moving and direction != Vector2():
		target_direction = direction
		if grid.is_cell_vacant(position, target_direction):
			target_pos = grid.update_child_pos(self)
			is_moving = true
				
			#animate the player's running
			if direction.x == 1 and lastAnimation == "right": #for diagonal animation
				$Sprite.flip_h = true
				$Sprite.play("Walk Left")
				lastAnimation = "right"
			elif direction.x == -1 and lastAnimation == "left":
				$Sprite.flip_h = false
				$Sprite.play("Walk Left")
				lastAnimation = "left"
			elif direction.y == -1 and lastAnimation == "up":
				$Sprite.play("Walk Up")
				lastAnimation = "up"
			elif direction.y == 1 and lastAnimation == "down":
				$Sprite.play("Walk Down")
				lastAnimation = "down"
			else: #for single direction animation
				if direction.x == 1:
					$Sprite.flip_h = true
					$Sprite.play("Walk Left")
					lastAnimation = "right"
					facingDirection = "right"
				elif direction.x == -1:
					$Sprite.flip_h = false
					$Sprite.play("Walk Left")
					lastAnimation = "left"
					facingDirection = "left"
				elif direction.y == -1:
					$Sprite.play("Walk Up")
					lastAnimation = "up"
					facingDirection = "up"
				elif direction.y == 1:
					$Sprite.play("Walk Down")
					lastAnimation = "down"
					facingDirection = "down"
			
	elif is_moving:
		speed = MAX_SPEED
		velocity = speed * target_direction * delta
		
		var distance_to_target = Vector2(abs(target_pos.x - position.x), abs(target_pos.y - position.y))
		
		if abs(velocity.x) > distance_to_target.x:
			velocity.x = distance_to_target.x * target_direction.x
			is_moving = false
		if abs(velocity.y) > distance_to_target.y:
			velocity.y = distance_to_target.y * target_direction.y
			is_moving = false
		
		move_and_collide(velocity)
		
	elif not is_moving:
		
		#play sprite animations
		if lastAnimation == "up":
			$Sprite.play("Idle Up")
		elif lastAnimation == "down":
			$Sprite.play("Idle Down")
		elif lastAnimation == "left" or lastAnimation == "right":
			$Sprite.play("Idle Left")
		elif lastAnimation == "hammer up":
			$Sprite.play("Hammer Up")
		elif lastAnimation == "hammer down":
			$Sprite.play("Hammer Down")
		elif lastAnimation == "hammer left":
			$Sprite.play("Hammer Left")
		elif lastAnimation == "seeds":
			$Sprite.play("Seeds")
		elif lastAnimation == "hoe up":
			$Sprite.play("Hoe Up")
		elif lastAnimation == "hoe down":
			$Sprite.play("Hoe Down")
		elif lastAnimation == "hoe left":
			$Sprite.play("Hoe Left")
		elif lastAnimation == "sickle up":
			$Sprite.play("Sickle Up")
		elif lastAnimation == "sickle down":
			$Sprite.play("Sickle Down")
		elif lastAnimation == "sickle left":
			$Sprite.play("Sickle Left")
		elif lastAnimation == "sickle circle":
			$Sprite.play("Sickle Circle")
	
	#track the hammer animation
	if lastAnimation == "hammer left":
		if facingDirection == "right":
			play_moving_animation(1, 0, 13, "hammer")
		else:
			play_moving_animation(-1, 0, 13, "hammer")
	elif lastAnimation == "hammer up":
		play_moving_animation(0, -1, 13, "hammer")
	elif lastAnimation == "hammer down":
		play_moving_animation(0, 1, 13, "hammer")
		
	#track the seed animation
	elif lastAnimation == "seeds":
		if $Sprite.get_frame() == 3:
			emit_signal("seeds", position)
			animationCommit = false
			facingDirection = "down"
			
	#track the hoe animation
	elif lastAnimation == "hoe left":
		if facingDirection == "right":
			play_moving_animation(1, 0, 12, "hoe")
		else:
			play_moving_animation(-1, 0, 12, "hoe")
	elif lastAnimation == "hoe up":
		play_moving_animation(0, -1, 12, "hoe")
	elif lastAnimation == "hoe down":
		play_moving_animation(0, 1, 12, "hoe")
		
	#track the sickle animation
	elif lastAnimation == "sickle left":
		if facingDirection == "right":
			play_moving_animation(1, 0, 12, "sickle")
		else:
			play_moving_animation(-1, 0, 12, "sickle")
	elif lastAnimation == "sickle up":
		play_moving_animation(0, -1, 12, "sickle")
	elif lastAnimation == "sickle down":
		play_moving_animation(0, 1, 12, "sickle")
		
	#track the sickle circle animation
	elif lastAnimation == "sickle circle":
		if $Sprite.get_frame() == 1:
			$Sprite.set_scale(Vector2(1.075, 1.075))
		elif $Sprite.get_frame() == 2:
			$Sprite.set_scale(Vector2(1.15, 1.15))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_scale(Vector2(1.075, 1.075))
			emit_signal("sickle_circle", position)
		elif $Sprite.get_frame() == 4:
			$Sprite.set_scale(Vector2(1, 1))
			animationCommit = false
		
func play_moving_animation(x_multiplier, y_multiplier, frame_count, action):
	if $Sprite.get_frame() == frame_count-2:
		$Sprite.set_offset(Vector2($Sprite.get_frame() * x_multiplier, $Sprite.get_frame() * y_multiplier))
	elif $Sprite.get_frame() == frame_count-1:
		$Sprite.set_offset(Vector2($Sprite.get_frame()/2 * x_multiplier, $Sprite.get_frame()/2 * y_multiplier))
	elif $Sprite.get_frame() == frame_count:
		$Sprite.set_offset(Vector2()) #0, reset animation
		animationCommit = false
	else:
		$Sprite.set_offset(Vector2($Sprite.get_frame() * 2 * x_multiplier, $Sprite.get_frame() * 2 * y_multiplier))
	
	#signal to change the tile
	if ($Sprite.get_frame() == 9 && action == "hammer"):
		emit_signal("hammer", position, facingDirection)
	elif ($Sprite.get_frame() == 9 && action == "hoe"):
		emit_signal("hoe", position, facingDirection)
	elif ($Sprite.get_frame() == 9 && action == "sickle"):
		emit_signal("sickle", position, facingDirection)