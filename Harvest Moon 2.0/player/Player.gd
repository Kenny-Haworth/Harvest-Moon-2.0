extends KinematicBody2D

var type
var Farm

#prevents sleep spam
var sleepDelay = 500 #.5 second
var sleepTime = 0

#prevents time of day spam
var changeTimeDelay = 30000 #timeChangeCycle - changeTimeDelay(s) == how long the shader is held for at full opacity strength
var timeChangeCycle = 15 #30 seconds
var changeTime = 0
var timeChange = true #true auto-changes time of day, false requires manual changing with the button K

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
onready var Rain = get_node("Rain")

#for controlling the inventory
var inventoryOpen = false
var closeInventoryDelay = 250 #.25 seconds, the amount of time until an action can be taken after closing the inventory (or the inventory can be re-opened again)
var inventoryCloseTime = -500 #negative by default for inventory closed
onready var Inventory = get_node("Camera2D/Inventory")

#for picking up crops
var crop_number
var holdingItem = false #for tracking if the player is holding an item
onready var Eggplant = get_node("PickCrops/Eggplant")
onready var Strawberry = get_node("PickCrops/Strawberry")
onready var Turnip = get_node("PickCrops/Turnip")

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
	Farm = get_parent()
	type = Farm.PLAYER
	set_physics_process(true)
	
#for controlling the inventory
func _input(event):
	#open the inventory if it is closed
	if event.is_action_pressed("I") and not inventoryOpen:
		inventoryOpen = true
	#close the inventory if it is open and the player has selected an item
	if event.is_action_pressed("ui_accept") and inventoryOpen:
		inventoryOpen = false
		inventoryCloseTime = OS.get_ticks_msec()

func _physics_process(delta):
	
	#show the inventory
	if inventoryOpen or OS.get_ticks_msec() < inventoryCloseTime + closeInventoryDelay:
		if inventoryOpen:
			Inventory._open_inventory() #shows the inventory
		return #forces the method to end here, and none of the other code below is executed
	
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
		
	#Weather and day change keys
	if Input.is_action_pressed("K"):
		$UI/VBoxContainer/Date/Weather.set_weather("sun")
	if Input.is_action_pressed("O"):
		$UI/VBoxContainer/Date/Weather.set_weather("cloud")
	if Input.is_action_pressed("P"):
		$UI/VBoxContainer/Date/Layout/Time.set_new_day()
		$UI/VBoxContainer/Date/Layout/Day.set_new_day()
	if Input.is_action_pressed("N"):
		$UI/VBoxContainer/Date/Layout/Season.set_season("Spring")
	if Input.is_action_pressed("H"):
		$UI/VBoxContainer/Date/Layout/Season.set_season("Summer")
		
	#player has pressed to perform an action based on equipped item
	if Input.is_action_pressed("ui_accept"):
		#resource consumption
		$UI/VBoxContainer/CanvasLayer/Energy.use_energy()

		#hammer
		if Inventory.activeItem == 2:
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "hammer left"
			elif facingDirection == "down":
				lastAnimation = "hammer down"
			elif facingDirection == "up":
				lastAnimation = "hammer up"
				
		#throw seeds
		elif Inventory.activeItem >= 5:
			animationCommit = true
			lastAnimation = "seeds"
			
		#hoe
		elif Inventory.activeItem == 1:
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "hoe left"
			elif facingDirection == "down":
				lastAnimation = "hoe down"
			elif facingDirection == "up":
				lastAnimation = "hoe up"
			
		#sickle
		elif Inventory.activeItem == 0:
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "sickle left"
			elif facingDirection == "down":
				lastAnimation = "sickle down"
			elif facingDirection == "up":
				lastAnimation = "sickle up"
				
		#axe
		elif Inventory.activeItem == 3:
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "axe left"
			elif facingDirection == "down":
				lastAnimation = "axe down"
			elif facingDirection == "up":
				lastAnimation = "axe up"
				
		#watering can:
		elif Inventory.activeItem == 4:
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "water left"
			elif facingDirection == "down":
				lastAnimation = "water down"
			elif facingDirection == "up":
				lastAnimation = "water up"
			
	#special action
	if Input.is_action_pressed("R"):
		#watering can circle
		if Inventory.activeItem == 4:
			animationCommit = true
			lastAnimation = "water circle"
			
		#sickle circle
		elif Inventory.activeItem == 0:
			animationCommit = true
			lastAnimation = "sickle circle"
			
	#to ensure the crop the player is holding is in the correct position
	if holdingItem:
		set_crop_offset()
		
	#pickup/drop item
	if Input.is_action_pressed("Q"):
		
		#the player wants to pick up an item
		if not holdingItem and animationCommit == false:
			
			#check if a crop is fully grown and ready for harvest on this square
			crop_number = Farm.check_square_for_harvest(position, facingDirection)
			
			#check to make sure a crop ready for harvest
			#otherwise, don't do anything
			if crop_number != -1:
				holdingItem = true
				if facingDirection == "left" or facingDirection == "right":
					lastAnimation = "pickup left"
				elif facingDirection == "down":
					lastAnimation = "pickup down"
				elif facingDirection == "up":
					lastAnimation = "pickup up"
				animationCommit = true
		
		#the player wants to drop their item
		elif holdingItem and animationCommit == false:
			
			#check to make sure the crop the player is holding can be dropped on this square
			#otherwise, don't do anything
			if (Farm.check_square_for_drop(position, facingDirection)):
				holdingItem = false
				if facingDirection == "left" or facingDirection == "right":
					lastAnimation = "drop left"
				elif facingDirection == "down":
					lastAnimation = "drop down"
				elif facingDirection == "up":
					lastAnimation = "drop up"
				animationCommit = true
		
	if direction != Vector2():
		speed = MAX_SPEED
	else:
		speed = 0
	
	#the player was standing still but has pressed to move to another location
	if not is_moving and direction != Vector2():
		target_direction = direction
		if Farm.is_cell_vacant(position, target_direction):
			target_pos = Farm.update_child_pos(self)
			is_moving = true
				
			#animate the player's running
			if direction.x == 1 and lastAnimation == "right": #for diagonal animation
				$Sprite.flip_h = true
				if not holdingItem:
					$Sprite.play("Walk Left")
				else:
					$Sprite.play("Hold Walk Left")
				lastAnimation = "right"
			elif direction.x == -1 and lastAnimation == "left":
				$Sprite.flip_h = false
				if not holdingItem:
					$Sprite.play("Walk Left")
				else:
					$Sprite.play("Hold Walk Left")
				lastAnimation = "left"
			elif direction.y == -1 and lastAnimation == "up":
				if not holdingItem:
					$Sprite.play("Walk Up")
				else:
					$Sprite.play("Hold Walk Up")
				lastAnimation = "up"
			elif direction.y == 1 and lastAnimation == "down":
				if not holdingItem:
					$Sprite.play("Walk Down")
				else:
					$Sprite.play("Hold Walk Down")
				lastAnimation = "down"
			else: #for single direction animation
				if direction.x == 1:
					$Sprite.flip_h = true
					if not holdingItem:
						$Sprite.play("Walk Left")
					else:
						$Sprite.play("Hold Walk Left")
					lastAnimation = "right"
					facingDirection = "right"
				elif direction.x == -1:
					$Sprite.flip_h = false
					if not holdingItem:
						$Sprite.play("Walk Left")
					else:
						$Sprite.play("Hold Walk Left")
					lastAnimation = "left"
					facingDirection = "left"
				elif direction.y == -1:
					$Sprite.flip_h = false
					if not holdingItem:
						$Sprite.play("Walk Up")
					else:
						$Sprite.play("Hold Walk Up")
					lastAnimation = "up"
					facingDirection = "up"
				elif direction.y == 1:
					$Sprite.flip_h = false
					if not holdingItem:
						$Sprite.play("Walk Down")
					else:
						$Sprite.play("Hold Walk Down")
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
			if not holdingItem:
				$Sprite.play("Idle Up")
			else:
				$Sprite.play("Hold Idle Up")
		elif lastAnimation == "down":
			if not holdingItem:
				$Sprite.play("Idle Down")
			else:
				$Sprite.play("Hold Idle Down")
		elif lastAnimation == "left" or lastAnimation == "right":
			if not holdingItem:
				$Sprite.play("Idle Left")
			else:
				$Sprite.play("Hold Idle Left")
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
		elif lastAnimation == "pickup up":
			$Sprite.play("Pickup Up")
		elif lastAnimation == "pickup down":
			$Sprite.play("Pickup Down")
		elif lastAnimation == "pickup left":
			$Sprite.play("Pickup Left")
		elif lastAnimation == "drop up":
			$Sprite.play("Drop Up")
		elif lastAnimation == "drop down":
			$Sprite.play("Drop Down")
		elif lastAnimation == "drop left":
			$Sprite.play("Drop Left")
	
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
			#spread turnip seeds
			if Inventory.activeItem == 5:
				emit_signal("seeds", position, 0)
			#spread strawberry seeds
			elif Inventory.activeItem == 6:
				emit_signal("seeds", position, 30)
			#spread eggplant seeds
			elif Inventory.activeItem == 7:
				emit_signal("seeds", position, 12)
				
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
		
	#track the pickup animation
	elif lastAnimation == "pickup left":
		if facingDirection == "right":
			play_moving_animation_pickup(1, 0)
		else:
			play_moving_animation_pickup(-1, 0)
	elif lastAnimation == "pickup up":
		play_moving_animation_pickup(0, -1)
	elif lastAnimation == "pickup down":
		play_moving_animation_pickup(0, 1)
		
	#track the drop animation
	elif lastAnimation == "drop left":
		if facingDirection == "right":
			play_moving_animation_drop(1, 0)
		else:
			play_moving_animation_drop(-1, 0)
	elif lastAnimation == "drop up":
		play_moving_animation_drop(0, -1)
	elif lastAnimation == "drop down":
		play_moving_animation_drop(0, 1)
		
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
		
func play_moving_animation_pickup(x_multiplier, y_multiplier):
	
	#the player is picking up an eggplant
	if crop_number == 17:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Eggplant.set_offset(Vector2(10 * x_multiplier + 1, 10 * y_multiplier + -7))
			Eggplant.show()
			Farm.harvest_crop(position, facingDirection)
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			set_crop_offset()
			animationCommit = false
			
	#the player is picking up a strawberry
	elif crop_number == 35:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Strawberry.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier + -7))
			Strawberry.show()
			Farm.harvest_crop(position, facingDirection)
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			set_crop_offset()
			animationCommit = false
		
	#the player is picking up a turnip
	elif crop_number == 5:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Turnip.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier + -7))
			Turnip.show()
			Farm.harvest_crop(position, facingDirection)
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			set_crop_offset()
			animationCommit = false
		
func play_moving_animation_drop(x_multiplier, y_multiplier):
	
	#the player is dropping an eggpplant
	if crop_number == 17:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Eggplant.set_offset(Vector2(10 * x_multiplier + 1, 10 * y_multiplier + -7))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Eggplant.hide()
			Farm.drop_crop(position, facingDirection, crop_number)
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			animationCommit = false
			
	#the player is dropping a strawberry
	elif crop_number == 35:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Strawberry.set_offset(Vector2(10 * x_multiplier + 1, 10 * y_multiplier + -7))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Strawberry.hide()
			Farm.drop_crop(position, facingDirection, crop_number)
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			animationCommit = false
			
	#the player is dropping a turnip
	elif crop_number == 5:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Turnip.set_offset(Vector2(10 * x_multiplier + 1, 10 * y_multiplier + -7))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Turnip.hide()
			Farm.drop_crop(position, facingDirection, crop_number)
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			animationCommit = false

#sets the crop's offset depending on the direction the player is facing and what crop they have in their hand
func set_crop_offset():
	
	#show the crop behind the player if they are facing up
	if facingDirection == "up":
		get_node("PickCrops").show_behind_parent = true
	else:
		get_node("PickCrops").show_behind_parent = false
	
	#the player is holding an eggpplant
	if crop_number == 17:
		if facingDirection == "right":
			Eggplant.set_offset(Vector2(7, -7))
		elif facingDirection == "left":
			Eggplant.set_offset(Vector2(-7, -7))
		elif facingDirection == "up":
			Eggplant.set_offset(Vector2(1, -16))
		elif facingDirection == "down":
			Eggplant.set_offset(Vector2(1, -7))
			
	#the player is holding a strawberry
	elif crop_number == 35:
		if facingDirection == "right":
			Strawberry.set_offset(Vector2(4, -7))
		elif facingDirection == "left":
			Strawberry.set_offset(Vector2(-5, -7))
		elif facingDirection == "up":
			Strawberry.set_offset(Vector2(0, -15))
		elif facingDirection == "down":
			Strawberry.set_offset(Vector2(0, -7))
			
	#the player is holding a turnip
	elif crop_number == 5:
		if facingDirection == "right":
			Turnip.set_offset(Vector2(4, -8))
		elif facingDirection == "left":
			Turnip.set_offset(Vector2(-5, -8))
		elif facingDirection == "up":
			Turnip.set_offset(Vector2(0, -13))
		elif facingDirection == "down":
			Turnip.set_offset(Vector2(0, -8))
		
func play_water_circle_animation():
	$Sprite.flip_h = false
	if $Sprite.get_frame() == 5:
		$Sprite.set_offset(Vector2(0, 5))
		emit_signal("water", position, "down")
	elif $Sprite.get_frame() == 6:
		$Sprite.set_offset(Vector2(-5, 5))
	elif $Sprite.get_frame() == 7:
		$Sprite.set_offset(Vector2(-10, 10))
		emit_signal("water", Vector2(position.x-Farm.tile_size.x, position.y), "down")
	elif $Sprite.get_frame() == 8:
		$Sprite.set_offset(Vector2(-5, 0))
	elif $Sprite.get_frame() == 9:
		$Sprite.set_offset(Vector2(-10, 0))
		emit_signal("water", position, "left")
	elif $Sprite.get_frame() == 10:
		$Sprite.set_offset(Vector2(-5, -5))
		emit_signal("water", Vector2(position.x-Farm.tile_size.x, position.y), "up")
	elif $Sprite.get_frame() == 11:
		$Sprite.set_offset(Vector2(0, -5))
	elif $Sprite.get_frame() == 12:
		$Sprite.set_offset(Vector2(0, -10))
		emit_signal("water", position, "up")
	elif $Sprite.get_frame() == 13:
		$Sprite.set_offset(Vector2(5, -5))
		emit_signal("water", Vector2(position.x, position.y-Farm.tile_size.x), "right")
	elif $Sprite.get_frame() == 14:
		$Sprite.set_offset(Vector2(5, 0))
	elif $Sprite.get_frame() == 15:
		$Sprite.set_offset(Vector2(10, 0))
		emit_signal("water", position, "right")
	elif $Sprite.get_frame() == 16:
		$Sprite.set_offset(Vector2(5, 5))
	elif $Sprite.get_frame() == 17:
		$Sprite.set_offset(Vector2(10, 10))
		emit_signal("water", Vector2(position.x, position.y+Farm.tile_size.x), "right")
	elif $Sprite.get_frame() == 18:
		$Sprite.set_offset(Vector2(0, 5))
		emit_signal("water", Vector2(position.x, position.y-Farm.tile_size.x), "down")
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
		Rain.set_one_shot(true)
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
		#TODO: call a method to water tilled tiles if the player is on the farm and it is raining
		Rain.set_one_shot(false)
		Rain.set_emitting(true)
		time = 1