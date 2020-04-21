extends Node

#get all areas
onready var Farm = get_node("Farm")
onready var House = get_node("House")
onready var Town = get_node("Town")

#get all grids from these areas to traverse
onready var FarmMap = get_node("Farm/Objects1")
onready var HouseMap = get_node("House/Objects")
onready var TownMap = get_node("Town/DummyObject")

#get the player and keep track of the player's location
onready var player = get_node("Farm/Player")
onready var player_location = get_node("Farm")

#to toggle the shaders and weather for walking indoors/outdoors
onready var Shaders = get_node("Shaders")
onready var Weather = get_node("Farm/Player/UI/Dashboard/Weather")

#for sound effects
onready var SoundManager = get_node("Sound")

#to set the dashboard for a new day
onready var Dashboard = get_node("Farm/Player/UI/Dashboard")

#locations to spawn the player for each area
const farm_to_house_spawn = Vector2(4, 7)
const house_to_farm_spawn = Vector2(19, 9)
const farm_to_town_spawn = Vector2(37, 92)
const town_to_farm_spawn = Vector2(19, 0)
const sleep_spawn = Vector2(7, 4)

#declare global constant for all areas in the entire game. Every area will inherit these constants
const tile_size = Vector2(32, 32) #32 pixels x 32 pixels tile sizes
const half_tile_size = tile_size / 2

#to obtain the current node count for all custom-created nodes in the game tree
func _ready():
	var array = [self]
	var count = 0
	
	while !array.empty():
		var base = array.pop_front()
		count += 1
		for child in base.get_children():
			array.append(child)
	
	print("The Count is:", count)

#updates the shaders, TimeManager, and weather for a new day
func new_day():
	Shaders.new_day()
	Dashboard.new_day()

#moves the player from the farm to the house
func farm_to_house():
	Farm.remove_child(Farm.get_node("Player"))
	House.add_child(player)
	player.set_owner(House)
	player.position = HouseMap.map_to_world(farm_to_house_spawn) + half_tile_size
	Shaders.toggle_shaders() #hides shaders
	Weather.toggle_weather() #hides weather
	SoundManager.stop_music("farm")
	SoundManager.play_music("house")
	SoundManager.set_music_volume("rain", -10) #lower the volume of the rain, the player is going indoors
	player_location = House

#moves the player from the house to the farm
func house_to_farm():
	House.remove_child(House.get_node("Player"))
	Farm.add_child(player)
	player.set_owner(Farm)
	player.position = FarmMap.map_to_world(house_to_farm_spawn) + half_tile_size
	Shaders.toggle_shaders() #shows shaders
	Weather.toggle_weather() #shows weather
	SoundManager.stop_music("house")
	SoundManager.play_music("farm")
	SoundManager.set_music_volume("rain", 0) #set the rain to max volume, the player is going back outside
	player_location = Farm

#moves the player from the farm to the town
func farm_to_town():
	Farm.remove_child(Farm.get_node("Player"))
	Town.add_child(player)
	player.set_owner(Town)
	player.position = TownMap.map_to_world(farm_to_town_spawn) + half_tile_size
	SoundManager.stop_music("farm")
	SoundManager.play_music("town")
	player_location = Town

#moves the player from the town to the farm
func town_to_farm():
	Town.remove_child(Town.get_node("Player"))
	Farm.add_child(player)
	player.set_owner(Farm)
	player.position = FarmMap.map_to_world(town_to_farm_spawn) + half_tile_size
	SoundManager.stop_music("town")
	SoundManager.play_music("farm")
	player_location = Farm

#puts the player in bed wherever they currently are in the world
func teleport_player_to_bed():
	player_location.remove_child(player_location.get_node("Player"))
	House.add_child(player)
	player.set_owner(House)
	player.position = HouseMap.map_to_world(sleep_spawn) + half_tile_size
	Shaders.toggle_shaders() #hides shaders
	Weather.toggle_weather() #hides weather
	SoundManager.set_music_volume("rain", -10) #lower the volume of the rain, the player is going indoors
	player_location = House

#puts the player in bed while the player is in the house
func house_to_sleep():
	player.position = HouseMap.map_to_world(sleep_spawn) + half_tile_size