extends TileMap

var tile_size = get_cell_size()
var half_tile_size = tile_size / 2

enum ENTITY_TYPES {PLAYER, OBSTACLE, COLLECTIBLE}

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
	
	get_node("Player").connect("hammer", self, "smash_hammer")

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

func smash_hammer(pos):
	set_cellv(world_to_map(pos), 5)