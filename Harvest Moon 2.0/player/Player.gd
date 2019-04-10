extends KinematicBody2D

var type
var grid

#prevents sleep spam
var sleepDelay = 500 #.5 second
var sleepTime = 0

#prevents time of day spam
var changeTimeDelay = 2500 #2.5 seconds, the difference between these numbers is how long the day scene is held for
var timeChangeCycle = 2 #2 seconds
var changeTime = 0
var timeChange = false #true auto-changes time of day, false requires manual changing with the button K

#keeps track of the time of day
var time = 3 #1 morning, 2 afternoon, 3 evening, 4 night

#for tweening shaders for time of day
onready var TweenMorningIn = get_node("Shaders/Morning/TweenMorningIn")
onready var TweenMorningOut = get_node("Shaders/Morning/TweenMorningOut")
onready var TweenAfternoonIn = get_node("Shaders/Afternoon/TweenAfternoonIn")
onready var TweenAfternoonOut = get_node("Shaders/Afternoon/TweenAfternoonOut")
onready var TweenEveningIn = get_node("Shaders/Evening/TweenEveningIn")
onready var TweenEveningOut = get_node("Shaders/Evening/TweenEveningOut")
onready var TweenNightIn = get_node("Shaders/Night/TweenNightIn")
onready var TweenNightOut = get_node("Shaders/Night/TweenNightOut")

#for weather
onready var Rain = get_node("Rain").get_process_material()
var startingRainVelocity

#signal functions
signal sleep()
signal hammer(pos, orientation)
signal seeds(pos)
signal hoe(pos, orienation)
signal sickle(pos, orientation)
signal sickle_circle(pos)
signal axe(pos, orientation)
signal water(pos, orientation)

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
	startingRainVelocity = Rain.initial_velocity

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
	if (timeChange and OS.get_ticks_msec() > changeTime + changeTimeDelay) or (Input.is_action_pressed("K") and  OS.get_ticks_msec() > changeTime + changeTimeDelay):
		changeTime = OS.get_ticks_msec()
		changeTime()
		
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
		
	#axe
	if Input.is_action_pressed("X"):
		animationCommit = true
		if facingDirection == "left" or facingDirection == "right":
			lastAnimation = "axe left"
		elif facingDirection == "down":
			lastAnimation = "axe down"
		elif facingDirection == "up":
			lastAnimation = "axe up"
			
	#watering can
	if Input.is_action_pressed("I"):
		animationCommit = true
		if facingDirection == "left" or facingDirection == "right":
			lastAnimation = "water left"
		elif facingDirection == "down":
			lastAnimation = "water down"
		elif facingDirection == "up":
			lastAnimation = "water up"
			
	#watering can circle
	if Input.is_action_pressed("U"):
		animationCommit = true
		lastAnimation = "water circle"
		
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
					$Sprite.flip_h = false
					$Sprite.play("Walk Up")
					lastAnimation = "up"
					facingDirection = "up"
				elif direction.y == 1:
					$Sprite.flip_h = false
					$Sprite.play("Walk Down")
					lastAnimation = "down"
					facingDirection = "down"
			
	elif is_moving:
		speed = MAX_SPEED
		velocity = speed * target_direction * delta
		Rain.initial_velocity = startingRainVelocity + MAX_SPEED
		
		var distance_to_target = Vector2(abs(target_pos.x - position.x), abs(target_pos.y - position.y))
		
		if abs(velocity.x) > distance_to_target.x:
			velocity.x = distance_to_target.x * target_direction.x
			is_moving = false
			Rain.initial_velocity = startingRainVelocity
		if abs(velocity.y) > distance_to_target.y:
			velocity.y = distance_to_target.y * target_direction.y
			is_moving = false
			Rain.initial_velocity = startingRainVelocity
		
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
		elif lastAnimation == "axe up":
			$Sprite.play("Axe Up")
		elif lastAnimation == "axe down":
			$Sprite.play("Axe Down")
		elif lastAnimation == "axe left":
			$Sprite.play("Axe Left")
		elif lastAnimation == "water up":
			$Sprite.play("Water Up")
		elif lastAnimation == "water down":
			$Sprite.play("Water Down")
		elif lastAnimation == "water left":
			$Sprite.play("Water Left")
		elif lastAnimation == "water circle":
			$Sprite.play("Water Circle")
	
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
			
	#track the axe animation
	elif lastAnimation == "axe left":
		if facingDirection == "right":
			play_moving_animation(1, 0, 13, "axe")
		else:
			play_moving_animation(-1, 0, 13, "axe")
	elif lastAnimation == "axe up":
		play_moving_animation(0, -1, 13, "axe")
	elif lastAnimation == "axe down":
		play_moving_animation(0, 1, 13, "axe")
		
	#track the water animation
	elif lastAnimation == "water left":
		if facingDirection == "right":
			play_moving_animation_watering(1, 0)
		else:
			play_moving_animation_watering(-1, 0)
	elif lastAnimation == "water up":
		play_moving_animation_watering(0, -1)
	elif lastAnimation == "water down":
		play_moving_animation_watering(0, 1)
		
	#track the water circle animation
	elif lastAnimation == "water circle":
		play_water_circle_animation()
		
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
	elif ($Sprite.get_frame() == 9 && action == "axe"):
		emit_signal("axe", position, facingDirection)
		
func play_moving_animation_watering(x_multiplier, y_multiplier):
	if $Sprite.get_frame() == 22:
		$Sprite.set_offset(Vector2()) #0, reset animation
		animationCommit = false
	elif $Sprite.get_frame() == 21:
		$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
	elif $Sprite.get_frame() <= 10:
		$Sprite.set_offset(Vector2($Sprite.get_frame() * 2 * x_multiplier, $Sprite.get_frame() * 2 * y_multiplier))
	
	#signal to change the tile
	if ($Sprite.get_frame() == 17):
		emit_signal("water", position, facingDirection)
		
func play_water_circle_animation():
	if $Sprite.get_frame() == 5:
		$Sprite.set_offset(Vector2(0, 5))
		emit_signal("water", position, "down")
	elif $Sprite.get_frame() == 6:
		$Sprite.set_offset(Vector2(-5, 5))
	elif $Sprite.get_frame() == 7:
		$Sprite.set_offset(Vector2(-10, 10))
		emit_signal("water", Vector2(position.x-grid.tile_size.x, position.y), "down")
	elif $Sprite.get_frame() == 8:
		$Sprite.set_offset(Vector2(-5, 0))
	elif $Sprite.get_frame() == 9:
		$Sprite.set_offset(Vector2(-10, 0))
		emit_signal("water", position, "left")
	elif $Sprite.get_frame() == 10:
		$Sprite.set_offset(Vector2(-5, -5))
		emit_signal("water", Vector2(position.x-grid.tile_size.x, position.y), "up")
	elif $Sprite.get_frame() == 11:
		$Sprite.set_offset(Vector2(0, -5))
	elif $Sprite.get_frame() == 12:
		$Sprite.set_offset(Vector2(0, -10))
		emit_signal("water", position, "up")
	elif $Sprite.get_frame() == 13:
		$Sprite.set_offset(Vector2(5, -5))
		emit_signal("water", Vector2(position.x, position.y-grid.tile_size.x), "right")
	elif $Sprite.get_frame() == 14:
		$Sprite.set_offset(Vector2(5, 0))
	elif $Sprite.get_frame() == 15:
		$Sprite.set_offset(Vector2(10, 0))
		emit_signal("water", position, "right")
	elif $Sprite.get_frame() == 16:
		$Sprite.set_offset(Vector2(5, 5))
	elif $Sprite.get_frame() == 17:
		$Sprite.set_offset(Vector2(10, 10))
		emit_signal("water", Vector2(position.x, position.y+grid.tile_size.x), "right")
	elif $Sprite.get_frame() == 18:
		$Sprite.set_offset(Vector2(0, 5))
		emit_signal("water", Vector2(position.x, position.y-grid.tile_size.x), "down")
	elif $Sprite.get_frame() == 19:
		$Sprite.set_offset(Vector2())
	elif $Sprite.get_frame() == 20:
		animationCommit = false
		
func changeTime():
	if time == 1: #morning
		TweenNightOut.interpolate_property(get_node("Shaders/Night"), "modulate", Color(0.39,0.43,0.43,.67), Color(0.39,0.43,0.43,0), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenNightOut.start() #fade out the night
		TweenMorningIn.interpolate_property(get_node("Shaders/Morning"), "modulate", Color(0.67,0.67,0.67,0), Color(0.67,0.67,0.67,.35), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenMorningIn.start() #fade in the morning
		time += 1
	elif time == 2: #afternoon
		TweenMorningOut.interpolate_property(get_node("Shaders/Morning"), "modulate", Color(0.67,0.67,0.67,.35), Color(0.67,0.67,0.67,0), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenMorningOut.start() #fade out the morning
		TweenAfternoonIn.interpolate_property(get_node("Shaders/Afternoon"), "modulate", Color(1,1,1,0), Color(1,1,1,1), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenAfternoonIn.start() #fade in the afternoon
		time += 1
	elif time == 3: #evening
		TweenAfternoonOut.interpolate_property(get_node("Shaders/Afternoon"), "modulate", Color(1,1,1,1), Color(1,1,1,0), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenAfternoonOut.start() #fade out the afternoon
		TweenEveningIn.interpolate_property(get_node("Shaders/Evening"), "modulate", Color(1,1,1,0), Color(1,1,1,.25), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenEveningIn.start() #fade in the evening
		time += 1
	elif time == 4: #night
		TweenEveningOut.interpolate_property(get_node("Shaders/Evening"), "modulate", Color(1,1,1,.25), Color(1,1,1,0), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenEveningOut.start() #fade out the evening
		TweenNightIn.interpolate_property(get_node("Shaders/Night"), "modulate", Color(0.39,0.43,0.43,0), Color(0.39,0.43,0.43,.67), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenNightIn.start() #fade in the night
		time = 1