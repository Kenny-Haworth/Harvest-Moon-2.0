extends KinematicBody2D

var Zone #The zone the player is currently in (Farm or House)

#prevents sleep spam
const sleepDelay = 8000 #8 seconds
var sleepTime = -8000

#the main Game node
onready var Game = get_node("/root/Game") 

#to control sounds
onready var SoundManager = get_node("/root/Game/Sound")

#for adding crops to the inventory, preventing the player from moving when the inventory is open
#and getting the currently equipped item
onready var Inventory = get_node("UI/Inventory")

#for handling the player's energy
onready var EnergyBar = get_node("UI/Energy Bar")

#for disabling the player when they are using the shop
onready var ShopMenu = get_node("/root/Game/Menus/Shop Menu")

#for picking up crops
var crop_number
var holdingItem = false #for tracking if the player is holding an item
onready var pickCrops = get_node("PickCrops")
onready var Eggplant = get_node("PickCrops/Eggplant")
onready var Strawberry = get_node("PickCrops/Strawberry")
onready var Turnip = get_node("PickCrops/Turnip")

#for holding the action key for power moves
const holdTimeDelay = 480 #must be holding the action key for a 480 milliseconds before releasing for a charge move. This is 6 frames/12.5 fps = .48 seconds
var holdTime
var powerHold = false

#a variable for controlling several control logic flow sections TODO rephrase this
var do_it_once = false

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
var direction = Vector2() #TODO do these need to be initialized to empty vectors?
var velocity = Vector2()
var target_pos = Vector2()
var target_direction = Vector2()
var is_moving = false

#for walking sound
var stepLeft = true
var stepRight = false
const stepDelay = 250 #.25 seconds
var stepTime = -250 #negative stepTime by default for not taking a step

#for connecting the signal to tell the player when to sleep
func _ready():
	get_node("UI/Dashboard/TimeManager").connect("sleep", self, "_force_sleep")

#called when the Player node enters the scene and every time it is reparented
func _enter_tree():
	Zone = get_parent()
	Game = Zone.get_parent()
	set_physics_process(true)

#disables the player and forces them to sleep
func _force_sleep():
	if OS.get_ticks_msec() > sleepTime + sleepDelay:
		$Sprite.set_offset(Vector2()) #reset animation if the player was in the middle of performing an action
		animationCommit = true #play the pass out animation
		powerHold = false #stop any power moves the player is charging
		lastAnimation = "pass out"
		sleepTime = OS.get_ticks_msec() #prevent sleep spam
		if Zone.name == "Farm": #player is on the farm
			SoundManager.stop_music("farm") #TODO see if you can move to game
		else: #player is in the house
			SoundManager.stop_music("house")
		SoundManager.play_music("forceSleep") #TODO see if you can move to game
		do_it_once = false

#this method is called each frame (60 times in a second, 60fps)
#button events should be handled by _input(event), which is only called once a button is pressed
#game logic that must be calculated each frame belongs here
func _physics_process(delta):
	
	#disable all player functions when the player is in the shop menu, but keep the game running
	if ShopMenu.visible:
		return
	
	#TODO teleporting does not need to be in physics process, it can be moved to when the player moves
	#allows the player to teleport to a different area as soon as they are finished moving to the next square
	if Zone.teleport(position):
		teleport = true
	
	if teleport and not is_moving:
		teleport = false
		
		if Zone.name == "Farm" and position == Vector2(624,-16):
			Game.farm_to_town()
		elif Zone.name == "Farm":
			Game.farm_to_house()
		elif Zone.name == "House":
			Game.house_to_farm()
		elif Zone.name == "Town":
			Game.town_to_farm()
	
	#player has pressed to perform an action based on equipped item
	#they are also not holding an item or currently performing an animation, and they still have energy to use their tools
	#their parent is also the farm, since they cannot perform an action while not on the farm
	if (Input.is_action_pressed("ui_accept") and not holdingItem and not animationCommit and Zone.name == "Farm" and EnergyBar.has_energy()) or (powerHold):
		if Inventory.is_equipped("Hammer"):
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "hammer left"
			elif facingDirection == "down":
				lastAnimation = "hammer down"
			elif facingDirection == "up":
				lastAnimation = "hammer up"
		
		#spread seeds
		elif Inventory.is_equipped("StrawberrySeeds") or Inventory.is_equipped("TurnipSeeds") or Inventory.is_equipped("EggplantSeeds"):
			animationCommit = true
			lastAnimation = "seeds"
		
		elif Inventory.is_equipped("Hoe"):
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "hoe left"
			elif facingDirection == "down":
				lastAnimation = "hoe down"
			elif facingDirection == "up":
				lastAnimation = "hoe up"
		
		elif Inventory.is_equipped("Axe"):
			animationCommit = true
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "axe left"
			elif facingDirection == "down":
				lastAnimation = "axe down"
			elif facingDirection == "up":
				lastAnimation = "axe up"
		
		elif Inventory.is_equipped("Sickle"):
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
		elif Inventory.is_equipped("Watering Can"):
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
					if facingDirection == "left":
						lastAnimation = "water circle left"
					elif facingDirection == "right":
						lastAnimation = "water circle right"
					elif facingDirection == "down":
						lastAnimation = "water circle down"
					elif facingDirection == "up":
						lastAnimation = "water circle up"
			elif $Sprite.get_frame() == 7: #powerHold is true, player is still holding the button
				$Sprite.set_frame(6)
	
	#to ensure the crop the player is holding is in the correct position
	if holdingItem:
		set_crop_offset()
		
		#the player wants to store an item they are holding in their backpack and they are not performing an animation
		if Input.is_action_pressed("B") and animationCommit == false:
			animationCommit = true
			do_it_once = false
			if facingDirection == "left" or facingDirection == "right":
				lastAnimation = "store left"
			elif facingDirection == "down":
				lastAnimation = "store down"
			elif facingDirection == "up":
				lastAnimation = "store up"
	
	#pickup/drop item, only allow if the player isn't moving to stop duplicate crop glitches, the player must be on the farm
	if Input.is_action_pressed("Q") and !is_moving and Zone.name == "Farm":
		
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
	
	#sleep if standing next to the bed and the player is not moving TODO not the best logic... this should be in house and SIGNAL to player, only checked on _input DUH press E
	if Input.is_action_pressed("E") and Zone.name == "House" and Zone.can_sleep(position) and !is_moving and OS.get_ticks_msec() > sleepTime + sleepDelay:
		self.position = Vector2(7*32, 2.25*32) #move the player into the bed
		animationCommit = true #play the pass out animation
		lastAnimation = "pass out"
		sleepTime = OS.get_ticks_msec() #prevent sleep spam
		SoundManager.stop_music("house")
		SoundManager.play_music("forceSleep") #TODO see if you can move to game
		do_it_once = false
	
	direction = Vector2()
	
	if not animationCommit: #if the playing is currently doing an animation, they cannot move or turn
		if Input.is_action_pressed("ui_up"):
			direction.y = -1
		elif Input.is_action_pressed("ui_down"):
			direction.y = 1
		#if the player is holding shift, they are swapping between items in their inventory, not trying to move
		if Input.is_action_pressed("ui_right") and not Input.is_action_pressed("shift_right_arrow"):
			direction.x = 1
		elif Input.is_action_pressed("ui_left") and not Input.is_action_pressed("shift_left_arrow"):
			direction.x = -1
	
	if direction != Vector2():
		speed = MAX_SPEED
	else:
		speed = 0
		if not animationCommit: #only rotate the player if they are standing still and not performing an action
			if Input.is_action_pressed("W"):
				lastAnimation = "up"
				facingDirection = "up"
			elif Input.is_action_pressed("S"):
				lastAnimation = "down"
				facingDirection = "down"
			elif Input.is_action_pressed("D"):
				$Sprite.flip_h = true
				lastAnimation = "right"
				facingDirection = "right"
			elif Input.is_action_pressed("A"):
				$Sprite.flip_h = false
				lastAnimation = "left"
				facingDirection = "left"
	
	#the player was standing still but has pressed to move to another location
	#only allow the player to move if the inventory is not open
	if not is_moving and direction != Vector2() and not Inventory.visible:
		target_direction = direction
		if Zone.is_cell_vacant(position, target_direction):
			target_pos = Zone.update_child_pos(self)
			is_moving = true
			
			#animate the player's running. If she is running down or up and then chooses to additionally run left or right, animate up or down
			if direction.y == -1 and (direction.x == 1 or direction.x == -1) and lastAnimation == "up":
				$Sprite.flip_h = false
				if not holdingItem:
					$Sprite.play("Walk Up")
				else:
					$Sprite.play("Hold Walk Up")
				lastAnimation = "up"
				facingDirection = "up"
			elif direction.y == 1 and (direction.x == 1 or direction.x == -1) and lastAnimation == "down":
				$Sprite.flip_h = false
				if not holdingItem:
					$Sprite.play("Walk Down")
				else:
					$Sprite.play("Hold Walk Down")
				lastAnimation = "down"
				facingDirection = "down"
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
		#play the sound for walking, with a set delay between steps
		if stepLeft and not SoundManager.is_playing("rightFoot") and OS.get_ticks_msec() >= stepDelay + stepTime:
			SoundManager.play_effect("leftFoot")
			stepRight = true
			stepLeft = false
			stepTime = OS.get_ticks_msec()
		elif stepRight and not SoundManager.is_playing("leftFoot") and OS.get_ticks_msec() >= stepDelay + stepTime:
			SoundManager.play_effect("rightFoot")
			stepLeft = true
			stepRight = false
			stepTime = OS.get_ticks_msec()
		
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
		elif lastAnimation == "water circle up":
			$Sprite.play("Water Circle Up")
		elif lastAnimation == "water circle down":
			$Sprite.play("Water Circle Down")
		elif lastAnimation == "water circle left":
			$Sprite.play("Water Circle Left")
		elif lastAnimation == "water circle right":
			$Sprite.play("Water Circle Right")
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
		elif lastAnimation == "pass out":
			$Sprite.play("Pass Out")
	
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
			if Inventory.is_equipped("TurnipSeeds"):
				Zone.spread_seeds(position, 0)
			elif Inventory.is_equipped("StrawberrySeeds"):
				Zone.spread_seeds(position, 30)
			elif Inventory.is_equipped("EggplantSeeds"):
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
			$Sprite.set_offset(Vector2()) #reset the sprite offset, it was changed during the sickle charge
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
	elif lastAnimation == "water circle up" or lastAnimation == "water circle down" or lastAnimation == "water circle left" or lastAnimation == "water circle right":
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
	
	#track the passing out animation
	if lastAnimation == "pass out": #TODO requires code generalization for expansion of the game
		if $Sprite.get_frame() == 15 and not do_it_once: #player is done passing out
			do_it_once = true
			if Zone.name == "House": #player is already in the houes
				Game.house_to_sleep()
			else: #player is anywhere else in the world
				Game.teleport_player_to_bed()
			Game.get_node("Farm").sleep() #progress farm logic TODO move this and all below to Game script
			EnergyBar.reset_energy() #restore the player's energy for a new day
			Game.new_day() #increment the day
			SoundManager.play_music("house") #TODO move to game new day logic
			animationCommit = false
			lastAnimation = "down"

#switches the player to an idle animation so the player can immediately perform another action
func reset_animation():
	animationCommit = false
	if facingDirection == "left" or facingDirection == "right":
		lastAnimation = "left"
	elif facingDirection == "up":
		lastAnimation = "up"
	elif facingDirection == "down":
		lastAnimation = "down"

#plays an animation in the requested direction for the hammer, hoe, axe, and sickle
#this allows the player to move towards another square before bouncing back to her own when performing an action
func play_animation(x_multiplier, y_multiplier, frame_count, action):
	if $Sprite.get_frame() == frame_count-2:
		$Sprite.set_offset(Vector2($Sprite.get_frame() * x_multiplier, $Sprite.get_frame() * y_multiplier))
	elif $Sprite.get_frame() == frame_count-1:
		$Sprite.set_offset(Vector2($Sprite.get_frame()/2 * x_multiplier, $Sprite.get_frame()/2 * y_multiplier))
	elif $Sprite.get_frame() == frame_count:
		$Sprite.set_offset(Vector2()) #0, reset animation
		reset_animation()
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
		reset_animation()
	elif $Sprite.get_frame() == 21:
		$Sprite.set_offset(Vector2(10 * x_multiplier, 10 * y_multiplier))
	elif ($Sprite.get_frame() == 17): #signal to change the tile
		Zone.water_square(position, facingDirection)
	elif $Sprite.get_frame() <= 10:
		$Sprite.set_offset(Vector2($Sprite.get_frame() * 2 * x_multiplier, $Sprite.get_frame() * 2 * y_multiplier))

func play_animation_water_circle():
	$Sprite.flip_h = false
	
	if facingDirection == "down":
		if $Sprite.get_frame() == 5:
			$Sprite.set_offset(Vector2(0, 5))
			Zone.water_square(position, "down") #down
		elif $Sprite.get_frame() == 6:
			$Sprite.set_offset(Vector2(-5, 5))
		elif $Sprite.get_frame() == 7:
			$Sprite.set_offset(Vector2(-10, 10))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "down") #left and down
		elif $Sprite.get_frame() == 8:
			$Sprite.set_offset(Vector2(-5, 0))
		elif $Sprite.get_frame() == 9:
			$Sprite.set_offset(Vector2(-10, 0))
			Zone.water_square(position, "left") #left
		elif $Sprite.get_frame() == 10:
			$Sprite.set_offset(Vector2(-5, -5))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "up") #left and up
		elif $Sprite.get_frame() == 11:
			$Sprite.set_offset(Vector2(0, -5))
		elif $Sprite.get_frame() == 12:
			$Sprite.set_offset(Vector2(0, -10))
			Zone.water_square(position, "up") #up
		elif $Sprite.get_frame() == 13:
			$Sprite.set_offset(Vector2(5, -5))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "right") #right and up
		elif $Sprite.get_frame() == 14:
			$Sprite.set_offset(Vector2(5, 0))
		elif $Sprite.get_frame() == 15:
			$Sprite.set_offset(Vector2(10, 0))
			Zone.water_square(position, "right") #right
		elif $Sprite.get_frame() == 16:
			$Sprite.set_offset(Vector2(5, 5))
		elif $Sprite.get_frame() == 17:
			$Sprite.set_offset(Vector2(10, 10))
			Zone.water_square(Vector2(position.x, position.y+Zone.tile_size.x), "right") #right and down
		elif $Sprite.get_frame() == 18:
			$Sprite.set_offset(Vector2(0, 5))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "down") #current square
		elif $Sprite.get_frame() == 19:
			$Sprite.set_offset(Vector2())
		elif $Sprite.get_frame() == 20:
			animationCommit = false
	elif facingDirection == "up":
		if $Sprite.get_frame() == 5:
			$Sprite.set_offset(Vector2(0, -5))
			Zone.water_square(position, "up") #up
		elif $Sprite.get_frame() == 6:
			$Sprite.set_offset(Vector2(5, -5))
		elif $Sprite.get_frame() == 7:
			$Sprite.set_offset(Vector2(10, -10))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "right") #right and up
		elif $Sprite.get_frame() == 8:
			$Sprite.set_offset(Vector2(5, 0))
		elif $Sprite.get_frame() == 9:
			$Sprite.set_offset(Vector2(10, 0))
			Zone.water_square(position, "right") #right
		elif $Sprite.get_frame() == 10:
			$Sprite.set_offset(Vector2(5, 5))
			Zone.water_square(Vector2(position.x, position.y+Zone.tile_size.x), "right") #right and down
		elif $Sprite.get_frame() == 11:
			$Sprite.set_offset(Vector2(0, 5))
		elif $Sprite.get_frame() == 12:
			$Sprite.set_offset(Vector2(0, 10))
			Zone.water_square(position, "down") #down
		elif $Sprite.get_frame() == 13:
			$Sprite.set_offset(Vector2(-5, 5))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "down") #left and down
		elif $Sprite.get_frame() == 14:
			$Sprite.set_offset(Vector2(-5, 0))
		elif $Sprite.get_frame() == 15:
			$Sprite.set_offset(Vector2(-10, 0))
			Zone.water_square(position, "left")
		elif $Sprite.get_frame() == 16:
			$Sprite.set_offset(Vector2(-5, -5))
		elif $Sprite.get_frame() == 17:
			$Sprite.set_offset(Vector2(-10, -10))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "up") #left and up
		elif $Sprite.get_frame() == 18:
			$Sprite.set_offset(Vector2(0, -5))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "down") #current square
		elif $Sprite.get_frame() == 19:
			$Sprite.set_offset(Vector2())
		elif $Sprite.get_frame() == 20:
			animationCommit = false
	elif facingDirection == "left":
		if $Sprite.get_frame() == 5:
			$Sprite.set_offset(Vector2(-5, 0))
			Zone.water_square(position, "left") #left
		elif $Sprite.get_frame() == 6:
			$Sprite.set_offset(Vector2(-5, -5))
		elif $Sprite.get_frame() == 7:
			$Sprite.set_offset(Vector2(-10, -10))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "up") #left and up
		elif $Sprite.get_frame() == 8:
			$Sprite.set_offset(Vector2(0, -5))
		elif $Sprite.get_frame() == 9:
			$Sprite.set_offset(Vector2(0, -10))
			Zone.water_square(position, "up") #up
		elif $Sprite.get_frame() == 10:
			$Sprite.set_offset(Vector2(5, -5))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "right") #right and up
		elif $Sprite.get_frame() == 11:
			$Sprite.set_offset(Vector2(5, 0))
		elif $Sprite.get_frame() == 12:
			$Sprite.set_offset(Vector2(10, 0))
			Zone.water_square(position, "right") #right
		elif $Sprite.get_frame() == 13:
			$Sprite.set_offset(Vector2(5, 5))
			Zone.water_square(Vector2(position.x, position.y+Zone.tile_size.x), "right") #right and down
		elif $Sprite.get_frame() == 14:
			$Sprite.set_offset(Vector2(0, 5))
		if $Sprite.get_frame() == 15:
			$Sprite.set_offset(Vector2(0, 10))
			Zone.water_square(position, "down") #down
		elif $Sprite.get_frame() == 16:
			$Sprite.set_offset(Vector2(-5, 5))
		elif $Sprite.get_frame() == 17:
			$Sprite.set_offset(Vector2(-10, 10))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "down") #left and down
		elif $Sprite.get_frame() == 18:
			$Sprite.set_offset(Vector2(-5, 0))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "down") #current square
		elif $Sprite.get_frame() == 19:
			$Sprite.set_offset(Vector2())
		elif $Sprite.get_frame() == 20:
			animationCommit = false
	elif facingDirection == "right":
		if $Sprite.get_frame() == 5:
			$Sprite.set_offset(Vector2(5, 0))
			Zone.water_square(position, "right") #right
		elif $Sprite.get_frame() == 6:
			$Sprite.set_offset(Vector2(5, 5))
		elif $Sprite.get_frame() == 7:
			$Sprite.set_offset(Vector2(10, 10))
			Zone.water_square(Vector2(position.x, position.y+Zone.tile_size.x), "right") #right and down
		elif $Sprite.get_frame() == 8:
			$Sprite.set_offset(Vector2(0, 5))
		elif $Sprite.get_frame() == 9:
			$Sprite.set_offset(Vector2(0, 10))
			Zone.water_square(position, "down") #down
		elif $Sprite.get_frame() == 10:
			$Sprite.set_offset(Vector2(-5, 5))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "down") #left and down
		elif $Sprite.get_frame() == 11:
			$Sprite.set_offset(Vector2(-5, 0))
		elif $Sprite.get_frame() == 12:
			$Sprite.set_offset(Vector2(-10, 0))
			Zone.water_square(position, "left") #left
		elif $Sprite.get_frame() == 13:
			$Sprite.set_offset(Vector2(-5, -5))
			Zone.water_square(Vector2(position.x-Zone.tile_size.x, position.y), "up") #left and up
		elif $Sprite.get_frame() == 14:
			$Sprite.set_offset(Vector2(0, -5))
		elif $Sprite.get_frame() == 15:
			$Sprite.set_offset(Vector2(0, -10))
			Zone.water_square(position, "up") #up
		elif $Sprite.get_frame() == 16:
			$Sprite.set_offset(Vector2(5, -5))
		elif $Sprite.get_frame() == 17:
			$Sprite.set_offset(Vector2(10, -10))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "right") #right and up
		elif $Sprite.get_frame() == 18:
			$Sprite.set_offset(Vector2(5, 0))
			Zone.water_square(Vector2(position.x, position.y-Zone.tile_size.x), "down") #current square
		elif $Sprite.get_frame() == 19:
			$Sprite.set_offset(Vector2())
		elif $Sprite.get_frame() == 20:
			$Sprite.flip_h = true
			animationCommit = false

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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Eggplant")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Eggplant")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Eggplant")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Strawberry")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Strawberry")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Strawberry")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Turnip")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Turnip")
					do_it_once = true
					SoundManager.play_effect("store")
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
				if not do_it_once: #only perform this code ONCE for the third frame
					Inventory.add("Turnip")
					do_it_once = true
					SoundManager.play_effect("store")
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