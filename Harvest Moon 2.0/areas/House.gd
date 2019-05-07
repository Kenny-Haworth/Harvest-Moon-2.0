extends Node2D

#get the master node
onready var Game = get_parent()

#get all the necessary tilemaps for this area (in top draw order)
onready var Objects = get_node("Objects")
onready var Background = get_node("Background")

#declare the size of this area and the tile sizes of this area
const grid_size = Vector2(9, 9) #9 tiles x 9 tiles (x,y)
var tile_size #32 pixels x 32 pixels
var half_tile_size
var grid = []

enum ENTITY_TYPES {PLAYER}

func _ready():
	tile_size = Game.tile_size #get the tile size from Game
	half_tile_size = Game.half_tile_size
	
	#all tilemap children of this node should have the same cell size
	assert (tile_size == Background.get_cell_size() and Background.get_cell_size() == Objects.get_cell_size())
	
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			if Objects.get_cell(x, y) != -1: #add all objects to the grid
				grid[x].append(1)
			else:
				grid[x].append(null)

#this function tells the player if they are about to be teleported to a new area
func teleport(position):
	if Objects.world_to_map(position) == Vector2(4, 8):
		return true
	return false

#tells the player if they are standing next to the bed or not
func can_sleep(position):
	if Objects.world_to_map(position) == Vector2(5, 3):
		return true
	return false

#checks if this cell is vacant
func is_cell_vacant(pos, direction):
	var grid_pos = Objects.world_to_map(pos) + direction
	
	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
			if grid[grid_pos.x][grid_pos.y] != 1:
				return true
	
	return false

#updates the grid position for the player
func update_child_pos(child_node):
	var grid_pos = Objects.world_to_map(child_node.position)
	grid[grid_pos.x][grid_pos.y] = null
	
	var new_grid_pos = grid_pos + child_node.direction
	grid[new_grid_pos.x][new_grid_pos.y] = child_node.type
	
	var target_pos = Objects.map_to_world(new_grid_pos) + half_tile_size
	return target_pos