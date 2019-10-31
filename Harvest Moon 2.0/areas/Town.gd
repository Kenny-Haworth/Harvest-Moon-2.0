extends Node2D

#get the master node
onready var Game = get_parent()

#get all the necessary tilemaps for this area
onready var DummyObject = get_node("DummyObject")
onready var Objects1 = get_node("Objects1")
onready var Objects2 = get_node("Objects2")
onready var Objects3 = get_node("Objects3")

#declare the size of this area and the tile sizes of this area
const grid_size = Vector2(75, 100)
var tile_size #32 pixels x 32 pixels
var half_tile_size
var grid = []

func _ready():
	tile_size = Game.tile_size #get the tile size from Game
	half_tile_size = Game.half_tile_size

	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			if Objects1.get_cell(x,y) != -1 or Objects2.get_cell(x,y) != -1 or Objects3.get_cell(x,y) != -1: #add all objects to the grid
				grid[x].append(1)
			else:
				grid[x].append(null)

#this function tells the player if they are about to be teleported to a new area
func teleport(position):
	if DummyObject.world_to_map(position) == Vector2(37, 93):
		return true
	return false

#checks if this cell is vacant
func is_cell_vacant(pos, direction):
	var grid_pos = DummyObject.world_to_map(pos) + direction
	
#	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
#		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
	if grid[grid_pos.x][grid_pos.y] != 1:
			return true
	
	return false

#updates the grid position for the player
func update_child_pos(child_node):
	var grid_pos = DummyObject.world_to_map(child_node.position)
	grid[grid_pos.x][grid_pos.y] = null
	
	var new_grid_pos = grid_pos + child_node.direction
	
	var target_pos = DummyObject.map_to_world(new_grid_pos) + half_tile_size
	return target_pos

#returns true if the player can open the shop menu, false otherwise
func can_shop(position):
	if DummyObject.world_to_map(position) == Vector2(27, 43):
		return true
	return false