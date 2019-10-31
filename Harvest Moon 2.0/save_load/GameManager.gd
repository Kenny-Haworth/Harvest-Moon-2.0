#this script is responsible for saving games and loading games
#the following information is required to save games:
#	the player's variables (position, facing direction, animation, etc.)
#	the player's inventory
#	the player's hotbar
#	the world map
#	the current time and day
#	the current shaders
#	the current weather
#this information is then loaded back into the game
#when the saved game is chosen to be loaded

extends Node

#keeps track of whether the current game session was loaded is a new game
#this is necessary for tracking whether a save can be overwritten in the
#current game session, or if a brand new save must be created
var game_type

#the name of the file to load
var file_name

#the time the game began initializing
var start_time

func _ready():
	set_physics_process(false)

#saves all necessary variables for the game to a dictionary, then parses
#the dictionary into a string to be saved in a text file
func save_game(file_name):
	#get the Player node, which the Game script always keeps track of
	var Player = get_node("/root/Game").player
	
	#create a new save file. This will overwrite the save if it already exists
	var saveFile = File.new()
	saveFile.open("user://" + file_name + ".txt", File.WRITE)
	
	#a dictionary to save all the game's necessary dependencies to reload the game in the exact same state
	var saveDictionary = {
		
		#environment variables
		cropsDictionary = {},
		dirtDictionary = {},
		junkDictionary = {},
		
		#inventory variables
		textures = [],
		labels = [],
		stacked_items = {},
		IndicatorSlot = 0,
		equippedItem = "null",
		
		#hotbar variables
		hotbar_textures = [],
		hotbar_labels = [],
		inventory_textures = [],
		inventory_labels = [],
		hotbar_IndicatorSlot = 0,
		
		#save the dashboard
		day = 0,
		hour = 0,
		armyTimeHour = 0,
		minute = 0,
		period = "null",
		season = "null",
		
		#save the weather
		weather = "null",
		raining = false,
		rain_one_shot = false,
		
		#player variables
		player_location = "null",
		pos_x = 0,
		pos_y = 0,
		sleepTime = 0,
		crop_number = 0,
		holdingItem = false,
		holdTime = 0,
		powerHold = false,
		do_it_once = false,
		lastAnimation = "null",
		facingDirection = "null",
		animationCommit = false,
		animation = "null",
		animationFrame = 0,
		teleport = false,
		speed = 0,
		direction_x = 0,
		direction_y = 0,
		velocity_x = 0,
		velocity_y = 0,
		target_pos_x = 0,
		target_pos_y = 0,
		target_direction_x = 0,
		target_direction_y = 0,
		is_moving = false,
		stepLeft = false,
		stepRight = false,
		stepTime = 0,
		flipped = false,
		holdEggplant = false,
		holdStrawberry = false,
		holdTurnip = false,
		
		#player's energy
		energy = 0,
		
		#save all the sounds
		sound_dictionary = {},
		
		#tweener variables
		
		#alpha variables
		morningAlpha = 0,
		afternoonAlpha = 0,
		eveningAlpha = 0,
		nightAlpha = 0,
		
		#playback positions
		TweenMorningOut = 0,
		TweenAfternoonIn = 0,
		TweenAfternoonOut = 0,
		TweenEveningIn = 0,
		TweenEveningOut = 0,
		TweenNightIn = 0
	}
	
	#save the world environment to individual dictionaries
	var cropsDictionary = {}
	var dirtDictionary = {}
	var junkDictionary = {}
	var Crops = get_node("/root/Game/Farm/Crops")
	var Dirt = get_node("/root/Game/Farm/Dirt")
	var Junk = get_node("/root/Game/Farm/Junk")
	
	#crops
	var used_cells_array = Crops.get_used_cells()
	for location in used_cells_array:
		cropsDictionary[location] = Crops.get_cellv(location)
	
	#dirt
	used_cells_array = Dirt.get_used_cells()
	for location in used_cells_array:
		dirtDictionary[location] = Dirt.get_cellv(location)
	
	#junk
	used_cells_array = Junk.get_used_cells()
	for location in used_cells_array:
		junkDictionary[location] = Junk.get_cellv(location)
	
	saveDictionary.cropsDictionary = cropsDictionary
	saveDictionary.dirtDictionary = dirtDictionary
	saveDictionary.junkDictionary = junkDictionary
	
	#save the player's inventory
	var Inventory = Player.get_node("UI/Inventory")
	
	#fill the textures and labels in the inventory
	#2 arrays are used, which preserve order and allow duplicate entries, unlike dictionaries
	var textures = []
	var labels = []
	var current = Inventory.textures_and_labels
	
	for texture in current.keys():
		var currentTexture = texture.get_texture()
		if currentTexture != null:
			var textureNameCutoff = currentTexture.get_load_path().get_file().find(".")
			textures.push_back(currentTexture.get_load_path().get_file().substr(0, textureNameCutoff))
		else:
			textures.push_back("none")
		
		var currentLabel = current[texture].get_text()
		if currentLabel != "":
			labels.push_back(currentLabel)
		else:
			labels.push_back("0")
	
	saveDictionary.textures = textures
	saveDictionary.labels = labels
	saveDictionary.stacked_items = Inventory.stacked_items
	saveDictionary.IndicatorSlot = Inventory.IndicatorSlot
	saveDictionary.equippedItem = Inventory.equippedItem
	
	#save the player's hotbar
	var Hotbar = Player.get_node("UI/Hotbar")
	
	#fill the hotbar's inventory data
	var hotbar_textures = []
	var hotbar_labels = []
	current = Hotbar.textures_and_labels
	
	for texture in current.keys():
		var currentTexture = texture.get_texture()
		if currentTexture != null:
			var textureNameCutoff = currentTexture.get_load_path().get_file().find(".")
			hotbar_textures.push_back(currentTexture.get_load_path().get_file().substr(0, textureNameCutoff))
		else:
			hotbar_textures.push_back("none")
		
		var currentLabel = current[texture].get_text()
		if currentLabel != "":
			hotbar_labels.push_back(currentLabel)
		else:
			hotbar_labels.push_back("0")
	
	var inventory_textures = []
	var inventory_labels = []
	current = Hotbar.inventory_textures_and_labels
	
	#fill the hotbar's inventory clone data
	for texture in current.keys():
		var currentTexture = texture.get_texture()
		if currentTexture != null:
			var textureNameCutoff = currentTexture.get_load_path().get_file().find(".")
			inventory_textures.push_back(currentTexture.get_load_path().get_file().substr(0, textureNameCutoff))
		else:
			inventory_textures.push_back("none")
		
		var currentLabel = current[texture].get_text()
		if currentLabel != "":
			inventory_labels.push_back(currentLabel)
		else:
			inventory_labels.push_back("0")
	
	saveDictionary.hotbar_textures = hotbar_textures
	saveDictionary.hotbar_labels = hotbar_labels
	saveDictionary.inventory_textures = inventory_textures
	saveDictionary.inventory_labels = inventory_labels
	saveDictionary.hotbar_IndicatorSlot = Hotbar.IndicatorSlot
	
	#save the dashboard
	var TimeManager = Player.get_node("UI/Dashboard/TimeManager")
	
	saveDictionary.day = TimeManager.day
	saveDictionary.hour = TimeManager.hour
	saveDictionary.armyTimeHour = TimeManager.armyTimeHour
	saveDictionary.minute = TimeManager.minute
	saveDictionary.period = TimeManager.period
	saveDictionary.season = TimeManager.season
	
	#save the weather
	var Weather = Player.get_node("UI/Dashboard/Weather")
	var Rain = Player.get_node("Rain")
	
	var weather_cutoff_location = Weather.get_texture().get_load_path().get_file().find(".")
	saveDictionary.weather = Weather.get_texture().get_load_path().get_file().substr(0, weather_cutoff_location)
	saveDictionary.raining = Rain.emitting
	saveDictionary.rain_one_shot = Rain.one_shot
	
	#save player variables
	saveDictionary.player_location = get_node("/root/Game").player_location.name
	saveDictionary.pos_x = Player.position.x
	saveDictionary.pos_y = Player.position.y
	saveDictionary.sleepTime = Player.sleepTime
	saveDictionary.crop_number = Player.crop_number
	saveDictionary.holdingItem = Player.holdingItem
	saveDictionary.holdTime = Player.holdTime
	saveDictionary.powerHold = Player.powerHold
	saveDictionary.do_it_once = Player.do_it_once
	saveDictionary.lastAnimation = Player.lastAnimation
	saveDictionary.facingDirection = Player.facingDirection
	saveDictionary.animationCommit = Player.animationCommit
	saveDictionary.animation = Player.get_node("Sprite").get_animation()
	saveDictionary.animationFrame = Player.get_node("Sprite").get_frame()
	saveDictionary.teleport = Player.teleport
	saveDictionary.speed = Player.speed
	saveDictionary.direction_x = Player.direction.x
	saveDictionary.direction_y = Player.direction.y
	saveDictionary.velocity_x = Player.velocity.x
	saveDictionary.velocity_y = Player.velocity.y
	saveDictionary.target_pos_x = Player.target_pos.x
	saveDictionary.target_pos_y = Player.target_pos.y
	saveDictionary.target_direction_x = Player.target_direction.x
	saveDictionary.target_direction_y = Player.target_direction.y
	saveDictionary.is_moving = Player.is_moving
	saveDictionary.stepLeft = Player.stepLeft
	saveDictionary.stepRight = Player.stepRight
	saveDictionary.stepTime = Player.stepTime
	saveDictionary.flipped = Player.get_node("Sprite").flip_h
	saveDictionary.holdEggplant = Player.get_node("PickCrops/Eggplant").visible
	saveDictionary.holdStrawberry = Player.get_node("PickCrops/Strawberry").visible
	saveDictionary.holdTurnip = Player.get_node("PickCrops/Turnip").visible
	
	#save player energy
	saveDictionary.energy = Player.get_node("UI/Energy Bar/Backdrop/Filled Bar").value
	
	#save the sounds
	var current_sound_dictionary = get_node("/root/Game/Sound").sound_dictionary
	var sound_dictionary = {}
	
	for sound in current_sound_dictionary.keys():
		sound_dictionary[sound.name] = current_sound_dictionary[sound]
		
	saveDictionary.sound_dictionary = sound_dictionary
	
	#save the shaders
	var Shaders = get_node("/root/Game/Shaders")
	
	#alpha values
	saveDictionary.morningAlpha = Shaders.get_node("Morning").color.a
	saveDictionary.afternoonAlpha = Shaders.get_node("Afternoon").color.a
	saveDictionary.eveningAlpha = Shaders.get_node("Evening").color.a
	saveDictionary.nightAlpha = Shaders.get_node("Night").color.a
	
	#playback values
	saveDictionary.TweenMorningOut = Shaders.get_node("Morning/TweenMorningOut").tell()
	saveDictionary.TweenAfternoonIn = Shaders.get_node("Afternoon/TweenAfternoonIn").tell()
	saveDictionary.TweenAfternoonOut = Shaders.get_node("Afternoon/TweenAfternoonOut").tell()
	saveDictionary.TweenEveningIn = Shaders.get_node("Evening/TweenEveningIn").tell()
	saveDictionary.TweenEveningOut = Shaders.get_node("Evening/TweenEveningOut").tell()
	saveDictionary.TweenNightIn = Shaders.get_node("Night/TweenNightIn").tell()
	
	#convert the dictionary to a string
	var json_string = JSON.print(saveDictionary)
	
	saveFile.store_line(json_string)#to_json(saveDictionary))
	saveFile.close()

#prepares the process for loading the game
func load_game(file):
	get_tree().change_scene("res://Game.tscn") #start the game
	set_physics_process(true)
	file_name = file #save the file name
	start_time = OS.get_ticks_msec() #start the timer, waiting for the game to initialize

#once the game has initialized, load variables in
func _physics_process(delta):
	
	if OS.get_ticks_msec() < start_time + 10:
		return
	
	#pause the tree before loading in game data
	get_tree().paused = true
	
	var Player = get_node("/root/Game").player #get the Player node, which the Game script always keeps track of
	
	var loadFile = File.new()
	
	#if the file suddenly doesn't exist when loaded, boot the player back to the main menu
	if not loadFile.file_exists("user://" + file_name + ".txt"):
		print("Error: Could not find file. Was it moved or deleted?")
		set_physics_process(false)
		get_tree().change_scene("res://menus/main/MainMenu.tscn") #switch back to the main menu
		return
	
	loadFile.open("user://" + file_name + ".txt", File.READ)
	var dict = parse_json(loadFile.get_line())
	
	#load in world data
	var Crops = get_node("/root/Game/Farm/Crops")
	var Dirt = get_node("/root/Game/Farm/Dirt")
	var Junk = get_node("/root/Game/Farm/Junk")
	var cropsDictionary = dict["cropsDictionary"]
	var dirtDictionary = dict["dirtDictionary"]
	var junkDictionary = dict["junkDictionary"]
	
	#crops
	for vector in cropsDictionary.keys():
		var location = _get_location(vector)
		Crops.set_cell(location.x, location.y, cropsDictionary[vector])
	
	#dirt
	for vector in dirtDictionary.keys():
		var location = _get_location(vector)
		Dirt.set_cell(location.x, location.y, dirtDictionary[vector])
	
	#junk
	for vector in junkDictionary.keys():
		var location = _get_location(vector)
		Junk.set_cell(location.x, location.y, junkDictionary[vector])
	
	#load in the inventory
	var Inventory = Player.get_node("UI/Inventory")
	
	#load in the inventory's textures and labels
	var textures = dict["textures"]
	var labels = dict["labels"]
	for i in range(0, textures.size()):
		if textures[i] == "none":
			Inventory.textures_and_labels.keys()[i].set_texture(null)
		else:
			Inventory.textures_and_labels.keys()[i].set_texture(load("res://ui/inventory/tools and items/" + textures[i] + ".png"))
		
		if labels[i] == "0":
			Inventory.textures_and_labels.values()[i].set_text("")
		else:
			Inventory.textures_and_labels.values()[i].set_text(labels[i])
	
	Inventory.stacked_items = dict["stacked_items"]
	Inventory.IndicatorSlot = dict["IndicatorSlot"]
	Inventory.equippedItem = dict["equippedItem"]
	
	#load in the hotbar
	var Hotbar = Player.get_node("UI/Hotbar")
	
	#load in the hotbar's inventory
	var hotbar_textures = dict["hotbar_textures"]
	var hotbar_labels = dict["hotbar_labels"]
	for i in range(0, hotbar_textures.size()):
		if hotbar_textures[i] == "none":
			Hotbar.textures_and_labels.keys()[i].set_texture(null)
		else:
			Hotbar.textures_and_labels.keys()[i].set_texture(load("res://ui/inventory/tools and items/" + hotbar_textures[i] + ".png"))
		
		if hotbar_labels[i] != "0":
			Hotbar.textures_and_labels.values()[i].set_text(hotbar_labels[i])
	
	#load in the cloned inventory for the hotbar node
	var inventory_textures = dict["inventory_textures"]
	var inventory_labels = dict["inventory_labels"]
	for i in range(0, inventory_textures.size()):
		if inventory_textures[i] == "none":
			Hotbar.inventory_textures_and_labels.keys()[i].set_texture(null)
		else:
			Hotbar.inventory_textures_and_labels.keys()[i].set_texture(load("res://ui/inventory/tools and items/" + inventory_textures[i] + ".png"))
		
		if inventory_labels[i] != "0":
			Hotbar.inventory_textures_and_labels.values()[i].set_text(inventory_labels[i])
	
	Hotbar.IndicatorSlot = dict["hotbar_IndicatorSlot"]
	Hotbar._move_indicator() #move the indicator back to where it should be based on the current slot
	
	#load the dashboard
	var TimeManager = Player.get_node("UI/Dashboard/TimeManager")
	
	TimeManager.day = int(dict["day"])
	TimeManager.hour = dict["hour"]
	TimeManager.armyTimeHour = dict["armyTimeHour"]
	TimeManager.minute = dict["minute"]
	TimeManager.period = dict["period"]
	TimeManager.season = dict["season"]
	
	#redraw the dashboard
	TimeManager.get_node("Time").set_text(str(dict["hour"]) + ":" + str(dict["minute"]).pad_zeros(2) + " " + dict["period"])
	TimeManager.get_node("Season").set_text(dict["season"])
	TimeManager.get_node("Day").set_text("Day " + str(dict["day"]))
	
	#load the weather
	var Weather = Player.get_node("UI/Dashboard/Weather")
	var Rain = Player.get_node("Rain")
	
	Weather.set_texture(load("res://ui/dashboard/weather/" + dict["weather"] + ".png"))
	Rain.emitting = dict["raining"]
	Rain.one_shot = dict["rain_one_shot"]
	
	#load in player data
	
	#reparent the player in the correct area
	if dict["player_location"] == "House":
		get_node("/root/Game").farm_to_house()
	elif dict["player_location"] == "Town":
		get_node("/root/Game").farm_to_town()
	Player.position = Vector2(dict["pos_x"], dict["pos_y"])
	Player.sleepTime = dict["sleepTime"]
	Player.crop_number = dict["crop_number"]
	Player.holdingItem = dict["holdingItem"]
	Player.holdTime = dict["holdTime"]
	Player.powerHold = dict["powerHold"]
	Player.do_it_once = dict["do_it_once"]
	Player.lastAnimation = dict["lastAnimation"]
	Player.facingDirection = dict["facingDirection"]
	Player.animationCommit = dict["animationCommit"]
	Player.get_node("Sprite").set_animation(dict["animation"])
	Player.get_node("Sprite").set_frame(dict["animationFrame"])
	Player.teleport = dict["teleport"]
	Player.speed = dict["speed"]
	Player.direction = Vector2(dict["direction_x"], dict["direction_y"])
	Player.velocity = Vector2(dict["velocity_x"], dict["velocity_y"])
	Player.target_pos = Vector2(dict["target_pos_x"], dict["target_pos_y"])
	Player.target_direction = Vector2(dict["target_direction_x"], dict["target_direction_y"])
	Player.is_moving = dict["is_moving"]
	Player.stepLeft = dict["stepLeft"]
	Player.stepRight = dict["stepRight"]
	Player.stepTime = dict["stepTime"]
	Player.get_node("Sprite").flip_h = dict["flipped"]
	Player.get_node("PickCrops/Eggplant").visible = dict["holdEggplant"]
	Player.get_node("PickCrops/Strawberry").visible = dict["holdStrawberry"]
	Player.get_node("PickCrops/Turnip").visible = dict["holdTurnip"]
	
	#load in the player energy bar
	Player.get_node("UI/Energy Bar/Backdrop/Filled Bar").value = dict["energy"]
	
	#load in sounds
	var Sounds = get_node("/root/Game/Sound")
	var sound_dictionary = dict["sound_dictionary"]
	
	for sound_node in Sounds.get_children():
		for sound in sound_node.get_children():
			sound.stop()
			for sound_name in sound_dictionary.keys():
				if sound.name == sound_name:
					sound.play(sound_dictionary[sound_name])
					break
	
	#load the shaders in
	var Shaders = get_node("/root/Game/Shaders")
	var tweenerDuration = Shaders.tweenerDuration
	
	var Morning = Shaders.get_node("Morning")
	var Afternoon = Shaders.get_node("Afternoon")
	var Evening = Shaders.get_node("Evening")
	var Night = Shaders.get_node("Night")
	
	var TweenMorningOut = Shaders.get_node("Morning/TweenMorningOut")
	var TweenAfternoonIn = Shaders.get_node("Afternoon/TweenAfternoonIn")
	var TweenAfternoonOut = Shaders.get_node("Afternoon/TweenAfternoonOut")
	var TweenEveningIn = Shaders.get_node("Evening/TweenEveningIn")
	var TweenEveningOut = Shaders.get_node("Evening/TweenEveningOut")
	var TweenNightIn = Shaders.get_node("Night/TweenNightIn")
	
	#stop any currently running tweeners
	TweenMorningOut.stop_all()
	TweenAfternoonIn.stop_all()
	TweenAfternoonOut.stop_all()
	TweenEveningIn.stop_all()
	TweenEveningOut.stop_all()
	TweenNightIn.stop_all()
	
	#load in the shader alpha values
	Morning.color = Color(0.79,0.79,0.32,dict["morningAlpha"])
	Afternoon.color = Color(1,1,1,dict["afternoonAlpha"])
	Evening.color = Color(1,.33,0,dict["eveningAlpha"])
	Night.color = Color(0.05,0.09,0.15,dict["nightAlpha"])
	
	#load in the shaders, resuming from where they left off
	if dict["TweenMorningOut"] > 0 and dict["TweenMorningOut"] < tweenerDuration:
		TweenMorningOut.interpolate_property(Morning, "color", Color(0.79,0.79,0.32,dict["morningAlpha"]), Color(0.79,0.79,0.32,0), tweenerDuration - dict["TweenMorningOut"], Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenMorningOut.start()
	
	if dict["TweenAfternoonIn"] > 0 and dict["TweenAfternoonIn"] < tweenerDuration:
		TweenAfternoonIn.interpolate_property(Afternoon, "color", Color(1,1,1,dict["afternoonAlpha"]), Color(1,1,1,0), tweenerDuration - dict["TweenAfternoonIn"], Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenAfternoonIn.start()
	
	if dict["TweenAfternoonOut"] > 0 and dict["TweenAfternoonOut"] < tweenerDuration:
		TweenAfternoonOut.interpolate_property(Afternoon, "color", Color(1,1,1,dict["afternoonAlpha"]), Color(1,1,1,0), tweenerDuration - dict["TweenAfternoonOut"], Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenAfternoonOut.start()
	
	if dict["TweenEveningIn"] > 0 and dict["TweenEveningIn"] < tweenerDuration:
		TweenEveningIn.interpolate_property(Evening, "color", Color(1,.33,0,dict["eveningAlpha"]), Color(1,.33,0,.25), tweenerDuration - dict["TweenEveningIn"], Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenEveningIn.start()
	
	if dict["TweenEveningOut"] > 0 and dict["TweenEveningOut"] < tweenerDuration:
		TweenEveningOut.interpolate_property(Evening, "color", Color(1,.33,0,dict["eveningAlpha"]), Color(1,.33,0,0), tweenerDuration - dict["TweenEveningOut"], Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenEveningOut.start()
	
	if dict["TweenNightIn"] > 0 and dict["TweenNightIn"] < tweenerDuration:
		TweenEveningOut.interpolate_property(Evening, "color", Color(0.05,0.09,0.15,dict["nightAlpha"]), Color(0.05,0.09,0.15,.75), tweenerDuration - dict["TweenNightIn"], Tween.TRANS_LINEAR, Tween.EASE_OUT)
		TweenNightIn.start()
	
	loadFile.close()
	set_physics_process(false)
	
	#resume the game now that the data has been loaded in
	get_tree().paused = false

#takes a string vector2 and returns it as a Vector2
func _get_location(location):
	var space = location.find(" ")
	return Vector2(int(location.substr(1, space-2)), int(location.substr(space+1, location.length()-space-2)))

#sets the game's type as either "new" or "loaded"
func set_game_type(type):
	game_type = type