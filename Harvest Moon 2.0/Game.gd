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
const sleepSpawn = Vector2(7, 4)

#for spawning the player
onready var Player = preload("res://player/Player.tscn")
var player

#declare global constant for all areas in the entire game. Every area will inherit these constants
const tile_size = Vector2(32, 32) #32 pixels x 32 pixels tile sizes
const half_tile_size = tile_size / 2

#for sound
var farmMusic
var houseMusic
var rain
var forceSleep
var bell
var drop
var harvest
var leftFoot
var rightFoot
var store
var axe
var hammer
var hoe
var seeds
var sickle
var watering

func _ready():
	#spawn the player at their farm for the beginning of the game
	player = Player.instance()
	player.position = FarmMap.map_to_world(farmSpawn) + half_tile_size
	Farm.add_child(player)
	
	#create the audio players
	farmMusic = AudioStreamPlayer.new()
	self.add_child(farmMusic)
	farmMusic.stream = load("res://sound/Farm1.wav")
	
	houseMusic = AudioStreamPlayer.new()
	self.add_child(houseMusic)
	houseMusic.stream = load("res://sound/houseMusic.wav")
	
	rain = AudioStreamPlayer.new()
	self.add_child(rain)
	rain.stream = load("res://sound/rain.wav")
	
	forceSleep = AudioStreamPlayer.new()
	self.add_child(forceSleep)
	forceSleep.stream = load("res://sound/forceSleep.wav")
	
	bell = AudioStreamPlayer.new() #TODO use this sound file
	self.add_child(bell)
	bell.stream = load("res://sound/effects/bell.wav")
	
	drop = AudioStreamPlayer.new()
	self.add_child(drop)
	drop.stream = load("res://sound/effects/drop.wav")
	drop.volume_db = -15
	
	harvest = AudioStreamPlayer.new()
	self.add_child(harvest)
	harvest.stream = load("res://sound/effects/harvest.wav")
	harvest.volume_db = -15
	
	leftFoot = AudioStreamPlayer.new()
	self.add_child(leftFoot)
	leftFoot.stream = load("res://sound/effects/leftFoot.wav")
	leftFoot.volume_db = -15
	
	rightFoot = AudioStreamPlayer.new()
	self.add_child(rightFoot)
	rightFoot.stream = load("res://sound/effects/rightFoot.wav")
	rightFoot.volume_db = -15
	
	store = AudioStreamPlayer.new()
	self.add_child(store)
	store.stream = load("res://sound/effects/store.wav")
	store.volume_db = -15
	
	axe = AudioStreamPlayer.new()
	self.add_child(axe)
	axe.stream = load("res://sound/tools/axe.wav")
	
	hammer = AudioStreamPlayer.new()
	self.add_child(hammer)
	hammer.stream = load("res://sound/tools/hammer.wav")
	
	hoe = AudioStreamPlayer.new()
	self.add_child(hoe)
	hoe.stream = load("res://sound/tools/hoe.wav")
	
	seeds = AudioStreamPlayer.new() #TODO overlap seed sounds when adding power moves in (1x1, 3x1, 3x3)
	self.add_child(seeds)
	seeds.stream = load("res://sound/tools/seeds.wav")
	
	sickle = AudioStreamPlayer.new()
	self.add_child(sickle)
	sickle.stream = load("res://sound/tools/sickle.wav")
	
	watering = AudioStreamPlayer.new()
	self.add_child(watering)
	watering.stream = load("res://sound/tools/watering.wav")

#moves the player from the farm to the house
func farm_to_house():
	Farm.remove_child(Farm.get_node("Player"))
	player.position = HouseMap.map_to_world(houseSpawn) + half_tile_size
	House.add_child(player)
	player.set_owner(House)
	player.readyAgain()
	player.toggle_tweeners() #disables time of day shaders and weather effects
	farmMusic.stop()
	houseMusic.play()
	rain.volume_db = -10 #lower the volume of the rain, you're going indoors

#moves the player from the house to the farm
func house_to_farm():
	House.remove_child(House.get_node("Player"))
	player.position = FarmMap.map_to_world(farmSpawn) + half_tile_size
	Farm.add_child(player)
	player.set_owner(Farm)
	player.readyAgain()
	player.toggle_tweeners() #enables time of day shaders and weather effects
	houseMusic.stop()
	farmMusic.play()
	rain.volume_db = 0 #set the rain to max volume

#moves the player from the farm to the house, and puts them in bed
func farm_to_house_sleep():
	Farm.remove_child(Farm.get_node("Player"))
	player.position = HouseMap.map_to_world(sleepSpawn) + half_tile_size
	House.add_child(player)
	player.set_owner(House)
	player.readyAgain()
	player.toggle_tweeners() #disables time of day shaders and weather effects
	rain.volume_db = -10 #lower the volume of the rain, you're going indoors

#puts the player in bed
func house_to_sleep():
	player.position = HouseMap.map_to_world(sleepSpawn) + half_tile_size