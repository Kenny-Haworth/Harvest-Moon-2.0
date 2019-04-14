#All tilemap children of this node have different tilesets. This class is
#responsible for ensuring they all have the same grid size, tile size,
#and are able to interact with each other.

#The player may interact with dirt and crops (such as tilling and watering
#soil or planting crops), but may not interact with the background. Objects
#requires interaction to prevent the player from moving to squares with objects
#on them, so it is used as the main grid.

extends Node2D

#get all the necessary tilemaps for this area (in top draw order)
onready var Crops = get_node("Crops")
onready var Dirt = get_node("Dirt")
onready var Objects = get_node("Objects")
onready var Background1 = get_node("Background1")
onready var Background2 = get_node("Background2")

#declare the size of this area and the tile sizes of this area
var grid_size = Vector2(18, 18) #18 tiles x 18 tiles
var tile_size = Vector2(32, 32) #32 pixels x 32 pixels
var half_tile_size = tile_size / 2
var grid = []

onready var Player = preload("res://player/Player.tscn")
enum ENTITY_TYPES {PLAYER}

func _ready():
	#all children of this node should have the same cell size
	assert (Background1.get_cell_size() == Background2.get_cell_size() and Background2.get_cell_size() == Objects.get_cell_size() and Objects.get_cell_size() == Dirt.get_cell_size() and Dirt.get_cell_size() == Crops.get_cell_size())
	
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(null)
			
	var new_player = Player.instance()
	new_player.position = Objects.map_to_world(Vector2(0,0)) + half_tile_size
	add_child(new_player)
	
	get_node("Player").connect("sleep", self, "sleep")
	get_node("Player").connect("hammer", self, "smash_hammer")
	get_node("Player").connect("seeds", self, "spread_seeds")
	get_node("Player").connect("hoe", self, "swing_hoe")
	get_node("Player").connect("sickle", self, "swing_sickle")
	get_node("Player").connect("sickle_circle", self, "swing_sickle_circle")
	get_node("Player").connect("axe", self, "swing_axe")
	get_node("Player").connect("water", self, "water_square")
			
func is_cell_vacant(pos, direction):
	var grid_pos = Objects.world_to_map(pos) + direction
	
	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
			#if grid[grid_pos.x][grid_pos.y] == null:
			if get_cell(grid_pos.x, grid_pos.y) == -1:
				return true
		
	return false
	
func update_child_pos(child_node):
	var grid_pos = Objects.world_to_map(child_node.position)
	grid[grid_pos.x][grid_pos.y] = null
	
	var new_grid_pos = grid_pos + child_node.direction
	grid[new_grid_pos.x][new_grid_pos.y] = child_node.type
	
	var target_pos = Objects.map_to_world(new_grid_pos) + half_tile_size
	return target_pos
	
#simulate plant growth (or decay) for the day
func sleep():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			#each crop must be watered for it to progress to the next growth cycle
			#after the day, the crop must be watered again
			
			#grow turnips
			if Crops.get_cell(x,y) == 0 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 1)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 1 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 2)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 2 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 3)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 3 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 4)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 4 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 5)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 5 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 0)
				Dirt.set_cell(x,y,0)
				
#change the tile the player has swung their hammer towards
func smash_hammer(pos, orientation):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
		
	Objects.set_cellv(Objects.world_to_map(pos), -1)
		
#spread seeds around the player
func spread_seeds(pos):
	
	#only spread seeds if the tile is already tilled (it can be watered already too, so 0 or 2)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+tile_size.x, pos.y))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x-tile_size.x, pos.y))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x, pos.y+tile_size.x))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x, pos.y+tile_size.x)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x, pos.y-tile_size.x))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x, pos.y-tile_size.x)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x))) >= 0):
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x)), 0)
	if (Dirt.get_cellv(Dirt.world_to_map(pos)) >= 0):
		Crops.set_cellv(Crops.world_to_map(pos), 0)
	
#tills a tile of soil the player is facing towards
func swing_hoe(pos, orientation):
	var x1 = 0
	var y1 = 0
	var x2 = 0
	var y2 = 0
	
	if orientation == "up":
		pos.y -= tile_size.x
		x1 += tile_size.x
		x2 -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
		x1 += tile_size.x
		x2 -= tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
		y1 += tile_size.x
		y2 -= tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
		y1 += tile_size.x
		y2 -= tile_size.x
		
	#create unwatered dirt
	Dirt.set_cellv(Dirt.world_to_map(pos), 0)
	Dirt.set_cellv(Dirt.world_to_map(Vector2(pos.x+x1,pos.y+y1)), 0)
	Dirt.set_cellv(Dirt.world_to_map(Vector2(pos.x+x2,pos.y+y2)), 0)
	
func swing_sickle(pos, orientation):
	swing_hoe(pos, orientation)
	
func swing_sickle_circle(pos):
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x+tile_size.x, pos.y)), -1)
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x-tile_size.x, pos.y)), -1)
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x, pos.y+tile_size.x)), -1)
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x, pos.y-tile_size.x)), -1)
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x)), -1)
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x)), -1)
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x)), -1)
	Objects.set_cellv(Objects.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x)), -1)
	
func swing_axe(pos, orientation):
	smash_hammer(pos, orientation)
	
func water_square(pos, orientation):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
	
	#the cell must be tilled before it can be watered
	if (Dirt.get_cellv(Dirt.world_to_map(pos)) == 0):
		Dirt.set_cellv(Dirt.world_to_map(pos), 2)