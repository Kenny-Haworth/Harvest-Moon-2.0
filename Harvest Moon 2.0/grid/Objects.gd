extends TileMap

var tile_size = get_cell_size()
var half_tile_size = tile_size / 2

enum ENTITY_TYPES {PLAYER}

var grid_size = Vector2(30, 16)
var grid = []

onready var Player = preload("res://player/Player.tscn")

func _ready():
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			grid[x].append(null)
			
	#spawn the player
	var new_player = Player.instance()
	new_player.position = map_to_world(Vector2(0,0)) + half_tile_size
	add_child(new_player)
	
	get_node("Player").connect("sleep", self, "sleep")
	get_node("Player").connect("hammer", self, "smash_hammer")
	get_node("Player").connect("seeds", self, "spread_seeds")
	get_node("Player").connect("hoe", self, "swing_hoe")
	get_node("Player").connect("sickle", self, "swing_sickle")
	get_node("Player").connect("sickle_circle", self, "swing_sickle_circle")
	get_node("Player").connect("axe", self, "swing_axe")

func is_cell_vacant(pos, direction):
	var grid_pos = world_to_map(pos) + direction
	
	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
			if grid[grid_pos.x][grid_pos.y] == null:
			#if get_cell(grid_pos.x, grid_pos.y) == -1:
				return true
		
	return false
	
func update_child_pos(child_node):
	var grid_pos = world_to_map(child_node.position)
	grid[grid_pos.x][grid_pos.y] = null
	
	var new_grid_pos = grid_pos + child_node.direction
	grid[new_grid_pos.x][new_grid_pos.y] = child_node.type
	
	var target_pos = map_to_world(new_grid_pos) + half_tile_size
	return target_pos
	
#simulate plant growth (or decay) for the day
func sleep():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			if get_cell(x,y) == 5:
				set_cellv(Vector2(x, y), 1)
			elif get_cell(x,y) == 1:
				set_cellv(Vector2(x, y), 5)
				
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
		
	set_cellv(world_to_map(pos), -1)
		
#spread seeds around the player
func spread_seeds(pos):
	set_cellv(world_to_map(Vector2(pos.x+tile_size.x, pos.y)), 5)
	set_cellv(world_to_map(Vector2(pos.x-tile_size.x, pos.y)), 5)
	set_cellv(world_to_map(Vector2(pos.x, pos.y+tile_size.x)), 5)
	set_cellv(world_to_map(Vector2(pos.x, pos.y-tile_size.x)), 5)
	set_cellv(world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x)), 5)
	set_cellv(world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x)), 5)
	set_cellv(world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x)), 5)
	set_cellv(world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x)), 5)
	
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
		
	set_cellv(world_to_map(pos), -1)
	set_cellv(world_to_map(Vector2(pos.x+x1,pos.y+y1)), -1)
	set_cellv(world_to_map(Vector2(pos.x+x2,pos.y+y2)), -1)
	
func swing_sickle(pos, orientation):
	swing_hoe(pos, orientation)
	
func swing_sickle_circle(pos):
	set_cellv(world_to_map(Vector2(pos.x+tile_size.x, pos.y)), -1)
	set_cellv(world_to_map(Vector2(pos.x-tile_size.x, pos.y)), -1)
	set_cellv(world_to_map(Vector2(pos.x, pos.y+tile_size.x)), -1)
	set_cellv(world_to_map(Vector2(pos.x, pos.y-tile_size.x)), -1)
	set_cellv(world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x)), -1)
	set_cellv(world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x)), -1)
	set_cellv(world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x)), -1)
	set_cellv(world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x)), -1)
	
func swing_axe(pos, orientation):
	smash_hammer(pos, orientation)