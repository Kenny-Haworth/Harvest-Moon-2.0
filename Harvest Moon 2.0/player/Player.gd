extends KinematicBody2D

var type
var Zone #The zone the player is currently in (Farm, House, etc.)
var Game #the main Game node

#prevents sleep spam
const sleepDelay = 500 #.5 second
var sleepTime = 0

#prevents time of day spam
const changeTimeDelay = 30000 #(msec) 30 seconds, timeChangeCycle - changeTimeDelay(s) == how long the shader is held for at full opacity strength
const timeChangeCycle = 15 #(seconds) 15 seconds
var changeTime = 0
var timeChange = true #true auto-changes time of day, false requires manual changing with the button K

#keeps track of the time of day
var time = 3 #1 morning, 2 afternoon, 3 evening, 4 night

#for tweening shaders for time of day
onready var Shaders = get_node("Shaders")
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
const closeInventoryDelay = 250 #.25 seconds, the amount of time until an action can be taken after closing the inventory
var inventoryCloseTime = -250 #negative closeInventoryDelay by default for inventory closed
onready var Inventory = get_node("Camera2D/Inventory")

#for picking up crops
var crop_number
var holdingItem = false #for tracking if the player is holding an item
onready var pickCrops = get_node("PickCrops")
onready var Eggplant = get_node("PickCrops/Eggplant")
onready var Strawberry = get_node("PickCrops/Strawberry")
onready var Turnip = get_node("PickCrops/Turnip")

#for holding an action key for a certain amount of time
var holdTimeDelay = 1000 #must be holding the action key for a whole second before releasing for a power move
var holdTime
var powerHold = false

#declares the base offset of crops depending on what crop the player is holding and the direction the player is facing
const EggplantRight = Vector2(7, -7)
const EggplantLeft = Vector2(-7, -7)
const EggplantUp = Vector2(1, -16)
const EggplantDown = Vector2(1, -7)
const StrawberryRight = Vector2(4, -7)
const StrawberryLeft = Vector2(-5, -7)
const StrawberryUp = Vector2(0, -15)
const StrawberryDown = Vector2(0, -7)
const TurnipRight = Vector2(4, -8)
const TurnipLeft = Vector2(-5, -8)
const TurnipUp = Vector2(0, -13)
const TurnipDown = Vector2(0, -8)

#for animation purposes
var lastAnimation = "down" #for what animation was last played
var facingDirection = "down" #for what direction the player is currently facing
var animationCommit = false #for forcing an animation to play through once it starts

var teleport = false #for disabling the player when teleporting to a different area

#for basic 2D movement
const MAX_SPEED = 250
var speed = 0
var direction = Vector2()
var velocity = Vector2()
var target_pos = Vector2()
var target_direction = Vector2()
var is_moving = false

#called when the player is loaded in for the first time (only called once)
func _ready():
	Zone = get_parent()
	Game = Zone.get_parent()
	type = Zone.PLAYER
	set_physics_process(true)

#gets the new parent since the player has spawned in a different area now
func readyAgain():
	Zone = get_parent()
	type = Zone.PLAYER
	set_physics_process(true)

#this method is only called when the user presses a button
#it is not called each frame, and so should only be used for input logic
func _input(event):
	
	#open the inventory if it is closed, the player is not moving, and the player is not performing an animation
	if event.is_action_pressed("Tab") and not inventoryOpen and speed == 0 and not animationCommit:
		inventoryOpen = true
		
		#if the player is holding a crop, hide it so it doesn't show in front of the inventory
		if holdingItem:
			if crop_number == 5:
				Turnip.hide()
			elif crop_number == 35:
				Strawberry.hide()
			elif crop_number == 17:
				Eggplant.hide()
	
	#close the inventory if it is open and the player has selected an item
	if event.is_action_pressed("ui_accept") and inventoryOpen:
		inventoryOpen = false
		inventoryCloseTime = OS.get_ticks_msec()
		
		#if the player was holding a crop, show it now that the inventory is closed
		if holdingItem:
			if crop_number == 5:
				Turnip.show()
			elif crop_number == 35:
				Strawberry.show()
			elif crop_number == 17:
				Eggplant.show()

#this method is called each frame (60 times in a second, 60fps)
#button events should be handled by _input(event), which is only called once a button is pressed
#game logic that must be calculated each frame belongs here
func _physics_process(delta):
	
	#allows the player to teleport to a different area as soon as they are finished moving to the next square
	if Zone.teleport(position):
		teleport = true
	
	if teleport and not is_moving:
		teleport = false
		if Zone.name == "Farm": #if you're at your farm, you're going to your house
			Game.farm_to_house()
		elif Zone.name == "House": #if you're at your house, you're going to your farm
			Game.house_to_farm()
	
	#show the inventory
	if inventoryOpen or OS.get_ticks_msec() < inventoryCloseTime + closeInventoryDelay:
		if inventoryOpen:
			Inventory._open_inventory() #shows the inventory
			
		return #forces the method to end here, and none of the other code below is executed
	
	#sleep
	if Input.is_action_pressed("E") and OS.get_ticks_msec() > sleepTime + sleepDelay:
		Zone.sleep()
		sleepTime = OS.get_ticks_msec()
	
	#change time
	if (timeChange and OS.get_ticks_msec() > changeTime + changeTimeDelay) or (Input.is_action_pressed("K") and  OS.get_ticks_msec() > changeTime + changeTimeDelay):
		changeTime = OS.get_ticks_msec()
		changeTime()
	
	#player has pressed to perform an action based on equipped item
	#they are also not holding an item or currently performing an animation
	#their parent is also the farm, since they cannot perform an action while not on the farm
	if (Input.is_action_pressed("ui_accept") and not holdingItem and not animationCommit and Zone.name == "Farm") or (powerHold):
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
		
		#axe
		elif Inventory.activeItem == 3:
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "axe left"
			elif facingDirection == "down":
				lastAnimation = "axe down"
			elif facingDirection == "up":
				lastAnimation = "axe up"
		
		#sickle
		elif Inventory.activeItem == 0:
			if not powerHold:
				powerHold = true
				animationCommit = true
				holdTime = OS.get_ticks_msec()
				if facingDirection == "left" or facingDirection == "right":
					lastAnimation = "sickle left"
				elif facingDirection == "down":
					lastAnimation = "sickle down"
				elif facingDirection == "up":
					lastAnimation = "sickle up"
			elif not Input.is_action_pressed("ui_accept"): #the player has released the button
				powerHold = false
				if OS.get_ticks_msec() - holdTime >= holdTimeDelay: #the player was holding the button for more than 1 second, perform a super move
					lastAnimation = "sickle circle"
			elif $Sprite.get_frame() == 7: #powerHold is true, player is still holding the button
				$Sprite.set_frame(6)
		
		#watering can:
		elif Inventory.activeItem == 4:
			if not powerHold:
				powerHold = true
				animationCommit = true
				holdTime = OS.get_ticks_msec()
				if facingDirection == "left" or facingDirection == "right":
					lastAnimation = "water left"
				elif facingDirection == "down":
					lastAnimation = "water down"
				elif facingDirection == "up":
					lastAnimation = "water up"
			elif not Input.is_action_pressed("ui_accept"): #the player has released the button
				powerHold = false
				if OS.get_ticks_msec() - holdTime >= holdTimeDelay: #the player was holding the button for more than 1 second, perform a super move
					lastAnimation = "water circle"
			elif $Sprite.get_frame() == 7: #powerHold is true, player is still holding the button
				$Sprite.set_frame(6)
		
#	#special action; player cannot be holding an item or performing an animation, and they must be on the farm
#	if Input.is_action_pressed("R") and not holdingItem and not animationCommit and Zone.name == "Farm":
#		#watering can circle
#		if Inventory.activeItem == 4:
#			animationCommit = true
#			lastAnimation = "water circle"
#
#		#sickle circle
#		elif Inventory.activeItem == 0:
#			animationCommit = true
#			lastAnimation = "sickle circle"
	
	#to ensure the crop the player is holding is in the correct position
	if holdingItem:
		set_crop_offset()
		if Input.is_action_pressed("B"): #the player wants to store an item they are holding in their backpack
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "store left"
			elif facingDirection == "down":
				lastAnimation = "store down"
			elif facingDirection == "up":
				lastAnimation = "store up"
	
	#pickup/drop item, only allow if the player isn't moving to stop duplicate crop glitches, and the player must be on the farm
	if Input.is_action_pressed("Q") and speed == 0 and Zone.name == "Farm":
		
		#the player wants to pick up an item
		if not holdingItem and animationCommit == false:
			
			#check if a crop is fully grown and ready for harvest on this square
			crop_number = Zone.check_square_for_harvest(position, facingDirection)

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
			if (Zone.check_square_for_drop(position, facingDirection)):
				holdingItem = false
				if facingDirection == "left" or facingDirection == "right":
					lastAnimation = "drop left"
				elif facingDirection == "down":
					lastAnimation = "drop down"
				elif facingDirection == "up":
					lastAnimation = "drop up"
				animationCommit = true
	
	direction = Vector2()
	
	if not animationCommit: #if the playing is currently doing an animation, they cannot move
		if Input.is_action_pressed("ui_up") or Input.is_action_pressed("W"):
			direction.y = -1
		elif Input.is_action_pressed("ui_down") or Input.is_action_pressed("S"):
			direction.y = 1
		if Input.is_action_pressed("ui_right") or Input.is_action_pressed("D"):
			direction.x = 1
		elif Input.is_action_pressed("ui_left") or Input.is_action_pressed("A"):
			direction.x = -1
	
	if direction != Vector2():
		speed = MAX_SPEED
	else:
		speed = 0
	
	#the player was standing still but has pressed to move to another location
	if not is_moving and direction != Vector2():
		target_direction = direction
		if Zone.is_cell_vacant(position, target_direction):
			target_pos = Zone.update_child_pos(self)
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
		elif lastAnimation == "axe up":
			$Sprite.play("Axe Up")
		elif lastAnimation == "axe down":
			$Sprite.play("Axe Down")
		elif lastAnimation == "axe left":
			$Sprite.play("Axe Left")
		elif lastAnimation == "sickle up":
			$Sprite.play("Sickle Up")
		elif lastAnimation == "sickle down":
			$Sprite.play("Sickle Down")
		elif lastAnimation == "sickle left":
			$Sprite.play("Sickle Left")
		elif lastAnimation == "sickle circle":
			$Sprite.play("Sickle Circle")
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
		elif lastAnimation == "store up":
			$Sprite.play("Store Up")
		elif lastAnimation == "store down":
			$Sprite.play("Store Down")
		elif lastAnimation == "store left":
			$Sprite.play("Store Left")
	
	#track the hammer animation
	if lastAnimation == "hammer left":
		if facingDirection == "right":
			play_animation(1, 0, 13, "hammer")
		else:
			play_animation(-1, 0, 13, "hammer")
	elif lastAnimation == "hammer up":
		play_animation(0, -1, 13, "hammer")
	elif lastAnimation == "hammer down":
		play_animation(0, 1, 13, "hammer")
	
	#track the seed animation
	elif lastAnimation == "seeds":
		if $Sprite.get_frame() == 3:
			#spread turnip seeds
			if Inventory.activeItem == 5:
				Zone.spread_seeds(position, 0)
			#spread strawberry seeds
			elif Inventory.activeItem == 6:
				Zone.spread_seeds(position, 30)
			#spread eggplant seeds
			elif Inventory.activeItem == 7:
				Zone.spread_seeds(position, 12)
				
			animationCommit = false
			facingDirection = "down"
	
	#track the hoe animation
	elif lastAnimation == "hoe left":
		if facingDirection == "right":
			play_animation(1, 0, 12, "hoe")
		else:
			play_animation(-1, 0, 12, "hoe")
	elif lastAnimation == "hoe up":
		play_animation(0, -1, 12, "hoe")
	elif lastAnimation == "hoe down":
		play_animation(0, 1, 12, "hoe")
	
	#track the axe animation
	elif lastAnimation == "axe left":
		if facingDirection == "right":
			play_animation(1, 0, 13, "axe")
		else:
			play_animation(-1, 0, 13, "axe")
	elif lastAnimation == "axe up":
		play_animation(0, -1, 13, "axe")
	elif lastAnimation == "axe down":
		play_animation(0, 1, 13, "axe")
	
	#track the sickle animation
	elif lastAnimation == "sickle left":
		if facingDirection == "right":
			play_animation(1, 0, 12, "sickle")
		else:
			play_animation(-1, 0, 12, "sickle")
	elif lastAnimation == "sickle up":
		play_animation(0, -1, 12, "sickle")
	elif lastAnimation == "sickle down":
		play_animation(0, 1, 12, "sickle")
	
	#track the sickle circle animation
	elif lastAnimation == "sickle circle":
		if $Sprite.get_frame() == 1:
			$Sprite.set_scale(Vector2(1.075, 1.075))
		elif $Sprite.get_frame() == 2:
			$Sprite.set_scale(Vector2(1.15, 1.15))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_scale(Vector2(1.075, 1.075))
			Zone.swing_sickle_circle(position)
		elif $Sprite.get_frame() == 4:
			$Sprite.set_scale(Vector2(1, 1))
			animationCommit = false
			facingDirection = "down"
	
	#track the water animation
	elif lastAnimation == "water left":
		if facingDirection == "right":
			play_animation_water(1, 0)
		else:
			play_animation_water(-1, 0)
	elif lastAnimation == "water up":
		play_animation_water(0, -1)
	elif lastAnimation == "water down":
		play_animation_water(0, 1)
	
	#track the water circle animation
	elif lastAnimation == "water circle":
		play_animation_water_circle()
	
	#track the pickup animation
	elif lastAnimation == "pickup left":
		if facingDirection == "right":
			play_animation_pickup(1, 0)
		else:
			play_animation_pickup(-1, 0)
	elif lastAnimation == "pickup up":
		play_animation_pickup(0, -1)
	elif lastAnimation == "pickup down":
		play_animation_pickup(0, 1)
	
	#track the drop animation
	elif lastAnimation == "drop left":
		if facingDirection == "right":
			play_animation_drop(1, 0)
		else:
			play_animation_drop(-1, 0)
	elif lastAnimation == "drop up":
		play_animation_drop(0, -1)
	elif lastAnimation == "drop down":
		play_animation_drop(0, 1)
	
	#track the storing animation
	if lastAnimation == "store left":
		if facingDirection == "right":
			play_animation_store(1, 0)
		else:
			play_animation_store(-1, 0)
	elif lastAnimation == "store up":
		play_animation_store(0, -1)
	elif lastAnimation == "store down":
		play_animation_store(0, 1)

#plays an animation in the requested direction for the hammer, hoe, axe, and sickle
#this allows the player to move towards another square before bouncing back to her own when performing an action
func play_animation(x_multiplier, y_multiplier, frame_count, action):
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
		Zone.smash_hammer(position, facingDirection)
	elif ($Sprite.get_frame() == 9 && action == "hoe"):
		Zone.swing_hoe(position, facingDirection)
	elif ($Sprite.get_frame() == 9 && action == "axe"):
		Zone.swing_axe(position, facingDirection)
	elif ($Sprite.get_frame() == 9 && action == "sickle"):
		Zone.swing_sickle(position, facingDirection)

func play_animation_water(x_multiplier, y_multiplier):
	if $Sprite.get_frame() == 22:
		$Sprite.set_offset(Vector2()) #0, reset animation
		animationCommit = false
	elif $Sprite.get_frame() == 21:
		$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
	elif $Sprite.get_frame() <= 10:
		$Sprite.set_offset(Vector2($Sprite.get_frame() * 2 * x_multiplier, $Sprite.get_frame() * 2 * y_multiplier))
	
	#signal to change the tile
	if ($Sprite.get_frame() == 17):
		Zone.water_square(position, facingDirection)

func play_animation_water_circle():
	$Sprite.flip_h = false
	if $Sprite.get_frame() == 5:
		$Sprite.set_offset(Vector2(0, 5))
		Zone.water_square(position, "down")
	elif $Sprite.get_frame() == 6:
		$Sprite.set_offset(Vector2(-5, 5))
	elif $Sprite.get_frame() == 7:
		$Sprite.set_offset(Vector2(-10, 10))
		Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "down")
	elif $Sprite.get_frame() == 8:
		$Sprite.set_offset(Vector2(-5, 0))
	elif $Sprite.get_frame() == 9:
		$Sprite.set_offset(Vector2(-10, 0))
		Zone.water_square(position, "left")
	elif $Sprite.get_frame() == 10:
		$Sprite.set_offset(Vector2(-5, -5))
		Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "up")
	elif $Sprite.get_frame() == 11:
		$Sprite.set_offset(Vector2(0, -5))
	elif $Sprite.get_frame() == 12:
		$Sprite.set_offset(Vector2(0, -10))
		Zone.water_square(position, "up")
	elif $Sprite.get_frame() == 13:
		$Sprite.set_offset(Vector2(5, -5))
		Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "right")
	elif $Sprite.get_frame() == 14:
		$Sprite.set_offset(Vector2(5, 0))
	elif $Sprite.get_frame() == 15:
		$Sprite.set_offset(Vector2(10, 0))
		Zone.water_square(position, "right")
	elif $Sprite.get_frame() == 16:
		$Sprite.set_offset(Vector2(5, 5))
	elif $Sprite.get_frame() == 17:
		$Sprite.set_offset(Vector2(10, 10))
		Zone.water_square(Vector2(position.x, position.y+Zone.tile_size.x), "right")
	elif $Sprite.get_frame() == 18:
		$Sprite.set_offset(Vector2(0, 5))
		Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "down")
	elif $Sprite.get_frame() == 19:
		$Sprite.set_offset(Vector2())
	elif $Sprite.get_frame() == 20:
		animationCommit = false
		facingDirection = "down"

func play_animation_pickup(x_multiplier, y_multiplier):
	
	#the player is picking up an eggplant
	if crop_number == 17:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Eggplant.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Eggplant.set_scale(Vector2(.8, .8))
			Eggplant.show()
			Zone.harvest_crop(position, facingDirection)
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
			Strawberry.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Strawberry.set_scale(Vector2(.9, .9))
			Strawberry.show()
			Zone.harvest_crop(position, facingDirection)
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
			Turnip.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Turnip.set_scale(Vector2(1, 1))
			Turnip.show()
			Zone.harvest_crop(position, facingDirection)
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			set_crop_offset()
			animationCommit = false

func play_animation_drop(x_multiplier, y_multiplier):
	
	#the player is dropping an eggpplant
	if crop_number == 17:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Eggplant.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Eggplant.hide()
			Zone.drop_crop(position, facingDirection, crop_number)
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			animationCommit = false
	
	#the player is dropping a strawberry
	elif crop_number == 35:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Strawberry.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Strawberry.hide()
			Zone.drop_crop(position, facingDirection, crop_number)
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			animationCommit = false
	
	#the player is dropping a turnip
	elif crop_number == 5:
		if $Sprite.get_frame() == 0:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
			Turnip.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
		elif $Sprite.get_frame() == 1:
			$Sprite.set_offset(Vector2(20 * x_multiplier, 20 * y_multiplier))
			Turnip.hide()
			Zone.drop_crop(position, facingDirection, crop_number)
		elif $Sprite.get_frame() == 2:
			$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
		elif $Sprite.get_frame() == 3:
			$Sprite.set_offset(Vector2())
			animationCommit = false

#stores an item in the player's backpack
func play_animation_store(x_multiplier, y_multiplier):
	
	var baseOffset = Vector2()
	
	#player is storing an eggplant
	if crop_number == 17:
		#find the base offset
		if facingDirection == "left":
			baseOffset = EggplantLeft
		elif facingDirection == "right":
			baseOffset = EggplantRight
		elif facingDirection == "down":
			baseOffset = EggplantDown
		elif facingDirection == "up":
			baseOffset = EggplantUp
		
		if facingDirection == "left" or facingDirection == "right":
			if $Sprite.get_frame() == 0:
				Eggplant.set_offset(Vector2(x_multiplier * -6 + baseOffset.x, -5 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Eggplant.set_offset(Vector2(x_multiplier * -11 + baseOffset.x, 0 + baseOffset.y))
				Eggplant.set_scale(Vector2(0.6, 0.6))
			elif $Sprite.get_frame() == 2:
				Eggplant.set_offset(Vector2(x_multiplier * -17 + baseOffset.x, 5 + baseOffset.y))
				Eggplant.set_scale(Vector2(0.5, 0.5))
			elif $Sprite.get_frame() == 3: #reset Sprite
				Eggplant.hide()
				animationCommit = false
				holdingItem = false
		elif facingDirection == "up":
			if $Sprite.get_frame() == 0:
				Eggplant.set_offset(Vector2(baseOffset.x, y_multiplier * 3 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Eggplant.set_offset(Vector2(baseOffset.x, y_multiplier * -5 + baseOffset.y))
				pickCrops.show_behind_parent = false
			elif $Sprite.get_frame() == 2:
				Eggplant.set_offset(Vector2(baseOffset.x, y_multiplier * -15 + baseOffset.y))
				Eggplant.set_scale(Vector2(0.6, 0.6))
				pickCrops.show_behind_parent = false
			elif $Sprite.get_frame() == 3: #reset Sprite
				Eggplant.hide()
				animationCommit = false
				holdingItem = false
		elif facingDirection == "down":
			if $Sprite.get_frame() == 0:
				Eggplant.set_offset(Vector2(baseOffset.x, y_multiplier * -5 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Eggplant.set_offset(Vector2(baseOffset.x, y_multiplier * -10 + baseOffset.y))
				pickCrops.show_behind_parent = true
			elif $Sprite.get_frame() == 2:
				Eggplant.set_offset(Vector2(baseOffset.x, y_multiplier * -7 + baseOffset.y))
				pickCrops.show_behind_parent = true
			elif $Sprite.get_frame() == 3: #reset Sprite
				Eggplant.hide()
				animationCommit = false
				holdingItem = false
	
	#player is storing a strawberry
	elif crop_number == 35:
		
		#find the base offset
		if facingDirection == "left":
			baseOffset = StrawberryLeft
		elif facingDirection == "right":
			baseOffset = StrawberryRight
		elif facingDirection == "down":
			baseOffset = StrawberryDown
		elif facingDirection == "up":
			baseOffset = StrawberryUp
		
		if facingDirection == "left" or facingDirection == "right":
			if $Sprite.get_frame() == 0:
				Strawberry.set_offset(Vector2(x_multiplier * -6 + baseOffset.x, -5 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Strawberry.set_offset(Vector2(x_multiplier * -11 + baseOffset.x, 0 + baseOffset.y))
				Strawberry.set_scale(Vector2(0.7, 0.7))
			elif $Sprite.get_frame() == 2:
				Strawberry.set_offset(Vector2(x_multiplier * -17 + baseOffset.x, 5 + baseOffset.y))
				Strawberry.set_scale(Vector2(0.6, 0.6))
			elif $Sprite.get_frame() == 3: #reset Sprite
				Strawberry.hide()
				animationCommit = false
				holdingItem = false
		elif facingDirection == "up":
			if $Sprite.get_frame() == 0:
				Strawberry.set_offset(Vector2(baseOffset.x, y_multiplier * 3 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Strawberry.set_offset(Vector2(baseOffset.x, y_multiplier * -5 + baseOffset.y))
				pickCrops.show_behind_parent = false
			elif $Sprite.get_frame() == 2:
				Strawberry.set_offset(Vector2(baseOffset.x, y_multiplier * -15 + baseOffset.y))
				Strawberry.set_scale(Vector2(0.7, 0.7))
				pickCrops.show_behind_parent = false
			elif $Sprite.get_frame() == 3: #reset Sprite
				Strawberry.hide()
				animationCommit = false
				holdingItem = false
		elif facingDirection == "down":
			if $Sprite.get_frame() == 0:
				Strawberry.set_offset(Vector2(baseOffset.x, y_multiplier * -5 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Strawberry.set_offset(Vector2(baseOffset.x, y_multiplier * -10 + baseOffset.y))
				pickCrops.show_behind_parent = true
			elif $Sprite.get_frame() == 2:
				Strawberry.set_offset(Vector2(baseOffset.x, y_multiplier * -7 + baseOffset.y))
				pickCrops.show_behind_parent = true
			elif $Sprite.get_frame() == 3: #reset Sprite
				Strawberry.hide()
				animationCommit = false
				holdingItem = false
	
	#player is storing a turnip
	elif crop_number == 5:
		
		#find the base offset
		if facingDirection == "left":
			baseOffset = TurnipLeft
		elif facingDirection == "right":
			baseOffset = TurnipRight
		elif facingDirection == "down":
			baseOffset = TurnipDown
		elif facingDirection == "up":
			baseOffset = TurnipUp
		
		if facingDirection == "left" or facingDirection == "right":
			if $Sprite.get_frame() == 0:
				Turnip.set_offset(Vector2(x_multiplier * -6 + baseOffset.x, -5 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Turnip.set_offset(Vector2(x_multiplier * -11 + baseOffset.x, 0 + baseOffset.y))
				Turnip.set_scale(Vector2(0.8, 0.8))
			elif $Sprite.get_frame() == 2:
				Turnip.set_offset(Vector2(x_multiplier * -17 + baseOffset.x, 5 + baseOffset.y))
				Turnip.set_scale(Vector2(0.7, 0.7))
			elif $Sprite.get_frame() == 3: #reset Sprite
				Turnip.hide()
				animationCommit = false
				holdingItem = false
		elif facingDirection == "up":
			if $Sprite.get_frame() == 0:
				Turnip.set_offset(Vector2(baseOffset.x, y_multiplier * 3 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Turnip.set_offset(Vector2(baseOffset.x, y_multiplier * -5 + baseOffset.y))
				pickCrops.show_behind_parent = false
			elif $Sprite.get_frame() == 2:
				Turnip.set_offset(Vector2(baseOffset.x, y_multiplier * -15 + baseOffset.y))
				Turnip.set_scale(Vector2(0.8, 0.8))
				pickCrops.show_behind_parent = false
			elif $Sprite.get_frame() == 3: #reset Sprite
				Turnip.hide()
				animationCommit = false
				holdingItem = false
		elif facingDirection == "down":
			if $Sprite.get_frame() == 0:
				Turnip.set_offset(Vector2(baseOffset.x, y_multiplier * -5 + baseOffset.y))
			elif $Sprite.get_frame() == 1:
				Turnip.set_offset(Vector2(baseOffset.x, y_multiplier * -10 + baseOffset.y))
				pickCrops.show_behind_parent = true
			elif $Sprite.get_frame() == 2:
				Turnip.set_offset(Vector2(baseOffset.x, y_multiplier * -7 + baseOffset.y))
				pickCrops.show_behind_parent = true
			elif $Sprite.get_frame() == 3: #reset Sprite
				Turnip.hide()
				animationCommit = false
				holdingItem = false

#sets the crop's offset depending on the direction the player is facing and what crop they have in their hand
func set_crop_offset():
	
	#show the crop behind the player if they are facing up
	if facingDirection == "up":
		pickCrops.show_behind_parent = true
	else:
		pickCrops.show_behind_parent = false
	
	#the player is holding an eggpplant
	if crop_number == 17:
		if facingDirection == "right":
			Eggplant.set_offset(EggplantRight)
		elif facingDirection == "left":
			Eggplant.set_offset(EggplantLeft)
		elif facingDirection == "up":
			Eggplant.set_offset(EggplantUp)
		elif facingDirection == "down":
			Eggplant.set_offset(EggplantDown)
	
	#the player is holding a strawberry
	elif crop_number == 35:
		if facingDirection == "right":
			Strawberry.set_offset(StrawberryRight)
		elif facingDirection == "left":
			Strawberry.set_offset(StrawberryLeft)
		elif facingDirection == "up":
			Strawberry.set_offset(StrawberryUp)
		elif facingDirection == "down":
			Strawberry.set_offset(StrawberryDown)
	
	#the player is holding a turnip
	elif crop_number == 5:
		if facingDirection == "right":
			Turnip.set_offset(TurnipRight)
		elif facingDirection == "left":
			Turnip.set_offset(TurnipLeft)
		elif facingDirection == "up":
			Turnip.set_offset(TurnipUp)
		elif facingDirection == "down":
			Turnip.set_offset(TurnipDown)

func changeTime():
	if time == 1: #morning
		TweenNightOut.interpolate_property(get_node("Shaders/Night"), "modulate", Color(0.39,0.43,0.43,.67), Color(0.39,0.43,0.43,0), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_IN)
		TweenNightOut.start() #fade out the night
		TweenMorningIn.interpolate_property(get_node("Shaders/Morning"), "modulate", Color(0.67,0.67,0.67,0), Color(0.67,0.67,0.67,.35), timeChangeCycle, Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenMorningIn.start() #fade in the morning
		
		#rain starts in the morning and lasts all day
		var rainChance = randi()%4 + 1 #1-4
		if rainChance == 1: #25% chance of rain
			if not Rain.emitting: #if it is already raining, don't change anything. Otherwise toggle the rain
				Rain.set_one_shot(false)
				Rain.set_emitting(true)
			Game.get_node("Farm").simulate_rain() #water tilled squares for rain
		else: #turns the rain off
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
		time = 1

#enables shaders and weather if they were disabled or disables them if they were enabled (for indoor vs. outdoor settings)
func toggle_tweeners():
	if Shaders.visible:
		Shaders.visible = false
		Rain.visible = false
	else:
		Shaders.visible = true
		Rain.visible = true