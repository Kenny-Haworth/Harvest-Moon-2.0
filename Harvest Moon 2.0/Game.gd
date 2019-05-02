extends Node

#get all areas
onready var Farm = get_node("Farm")
onready var House = get_node("House")

#get all grids from these areas to traverse
onready var FarmMap = get_node("Farm/Objects1")
onready var HouseMap = get_node("House/Objects")

#locations to spawn the player for each area
const farmSpawn = Vector2(19, 9)
const houseSpawn = Vector2(4, 7)

#for spawning the player
onready var PlayerType = preload("res://player/Player.tscn")
enum ENTITY_TYPES {PLAYER}
var player

#declare global constant for all areas in the entire game. Every area will inherit these constants
const tile_size = Vector2(32, 32) #32 pixels x 32 pixels tile sizes
const half_tile_size = tile_size / 2

func _ready():
	#spawn the player at their farm for the beginning of the game
	player = PlayerType.instance()
	player.position = FarmMap.map_to_world(farmSpawn) + half_tile_size
	Farm.add_child(player)

#moves the player from the farm to the house
func farm_to_house():
	Farm.remove_child(Farm.get_node("Player"))
	player.position = HouseMap.map_to_world(houseSpawn) + half_tile_size
	House.add_child(player)
	player.set_owner(House)
	player.readyAgain()
	player.toggle_tweeners() #disables time of day shaders and weather effects

#moves the player from the house to the farm
func house_to_farm():
	House.remove_child(House.get_node("Player"))
	player.position = FarmMap.map_to_world(farmSpawn) + half_tile_size
	Farm.add_child(player)
	player.set_owner(Farm)
	player.readyAgain()
	player.toggle_tweeners() #enables time of day shaders and weather effects