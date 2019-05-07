#All tilemap children of this node have different tilesets. This class is
#responsible for ensuring they all have the same grid size, tile size,
#and are able to interact with each other.

#The player may interact with dirt and crops (such as tilling and watering
#soil or planting crops), but may not interact with the background. Objects
#requires interaction to prevent the player from moving to squares with objects
#on them, so all object tilemaps are added to the main grid.

extends Node2D

#get the master node
onready var Game = get_parent()

#get all the necessary tilemaps for this area (in top draw order)
onready var Foreground = get_node("Foreground")
onready var Crops = get_node("Crops")
onready var Dirt = get_node("Dirt")
onready var Junk = get_node("Junk")
onready var Objects1 = get_node("Objects1")
onready var Objects2 = get_node("Objects2")
onready var Background1 = get_node("Background1")
onready var Background2 = get_node("Background2")

#get the player's inventory (to edit # of seeds when throwing them)
#onready var Inventory = get_node("Player/Camera2D/Inventory")

#location of other areas to teleport to
const house_location = Vector2(19, 8)

#declare the size of this area and the tile sizes of this area
const grid_size = Vector2(39, 23) #39 tiles x 23 tiles (x,y)
var tile_size #32 pixels x 32 pixels, inherited from Game
var half_tile_size
var grid = []

enum ENTITY_TYPES {PLAYER}

func _ready():
	tile_size = Game.tile_size #get the tile size from Game
	half_tile_size = Game.half_tile_size
	
	#all tilemap children of this node should have the same cell size
	assert (tile_size == Crops.get_cell_size() and Crops.get_cell_size() == Dirt.get_cell_size() and Dirt.get_cell_size() == Junk.get_cell_size() and Junk.get_cell_size() == Objects1.get_cell_size() and Objects1.get_cell_size() == Objects2.get_cell_size() and Objects2.get_cell_size() == Foreground.get_cell_size() and Foreground.get_cell_size() == Background1.get_cell_size() and Background1.get_cell_size() == Background2.get_cell_size())
	
	#add all objects to the grid for this area
	for x in range(grid_size.x):
		grid.append([])
		for y in range(grid_size.y):
			if Objects1.get_cell(x, y) != -1 or Objects2.get_cell(x,y) != -1: #add all objects to the grid
				grid[x].append(1)
			else:
				grid[x].append(null)
	
#this function tells the player if they are about to be teleported to a new area
func teleport(position):
	if Objects1.world_to_map(position) == house_location: #the player is going into their house
		return true
	return false
		
#checks if this cell is vacant
func is_cell_vacant(pos, direction):
	var grid_pos = Objects1.world_to_map(pos) + direction
	
	if grid_pos.x < grid_size.x and grid_pos.x >= 0:
		if grid_pos.y < grid_size.y and grid_pos.y >= 0:
			if grid[grid_pos.x][grid_pos.y] != 1:
				return true
	
	return false

#updates the grid position for the player
func update_child_pos(child_node):
	var grid_pos = Objects1.world_to_map(child_node.position)
	grid[grid_pos.x][grid_pos.y] = null
	
	var new_grid_pos = grid_pos + child_node.direction
	grid[new_grid_pos.x][new_grid_pos.y] = child_node.type
	
	var target_pos = Objects1.map_to_world(new_grid_pos) + half_tile_size
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
				
			#grow strawberries
			elif Crops.get_cell(x,y) == 30 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 31)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 31 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 32)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 32 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 33)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 33 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 34)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 34 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 35)
				Dirt.set_cell(x,y,0)
				
			#grow eggplants
			elif Crops.get_cell(x,y) == 12 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 13)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 13 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 14)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 14 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 15)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 15 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 16)
				Dirt.set_cell(x,y,0)
			elif Crops.get_cell(x,y) == 16 and Dirt.get_cell(x,y) == 2:
				Crops.set_cellv(Vector2(x, y), 17)
				Dirt.set_cell(x,y,0)
				
			#any watered dirt without crops should become unwatered at the end of the day
			elif Dirt.get_cell(x,y) == 2:
				Dirt.set_cell(x,y,0)
			
			#chance to spawn wood, weeds, or stone at the end of the day,
			#conditions: it is a soil cell, it is not tilled, it does not already have junk on it
			#5% chance to spawn junk
			if Background2.get_cell(x,y) == 15 and Dirt.get_cell(x,y) == -1 and Junk.get_cell(x,y) == -1 and randi()%20 + 1 == 1:
				var junk_type = randi()%3 + 1 #1-3
				if junk_type == 1:
					Junk.set_cell(x,y,4) #weeds
				elif junk_type == 2:
					if randi()%2+1 == 1:
						Junk.set_cell(x,y,2) #rock 1
					else:
						Junk.set_cell(x,y,3) #rock 2
				elif junk_type == 3:
					Junk.set_cell(x,y,0) #wood

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
		
	#un-till the tile of dirt if there are no crops on it, and it is tilled or tilled and watered
	if (Crops.get_cellv(Crops.world_to_map(pos)) == -1) and (Dirt.get_cellv(Dirt.world_to_map(pos)) == 0 or Dirt.get_cellv(Dirt.world_to_map(pos)) == 2):
		Dirt.set_cellv(Dirt.world_to_map(pos), -1)
		if not Game.hammer.playing: #do not overlap this sound
			Game.hammer.play()
	elif (Junk.get_cellv(Junk.world_to_map(pos)) == 2) or (Junk.get_cellv(Junk.world_to_map(pos)) == 3):
		Junk.set_cellv(Junk.world_to_map(pos), -1)
		if not Game.hammer.playing:
			Game.hammer.play()

#spread seeds around the player
func spread_seeds(pos, seedType):
	
	var Inventory = get_node("Player/Camera2D/Inventory")
	var seedAmount = PlayerInventory_Script.get_number(Inventory.equippedItemSlot)
	
	#only spread seeds if the tile is already tilled (it can be watered already too, so 0 or 2)
	#also, there must not already be crops or seeds on this tile
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+tile_size.x, pos.y))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x-tile_size.x, pos.y))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x, pos.y+tile_size.x))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x, pos.y+tile_size.x))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x, pos.y+tile_size.x)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x, pos.y-tile_size.x))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x, pos.y-tile_size.x))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x, pos.y-tile_size.x)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x))) >= 0) and (Crops.get_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x))) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x)), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	if (Dirt.get_cellv(Dirt.world_to_map(pos)) >= 0) and (Crops.get_cellv(Crops.world_to_map(pos)) == -1) and seedAmount != 0:
		Crops.set_cellv(Crops.world_to_map(pos), seedType)
		seedAmount = PlayerInventory_Script.inventory_removeItem(Inventory.equippedItemSlot)
		if not Game.seeds.playing:
			Game.seeds.play()
	
	if seedAmount == 0: #unequip the seeds
		Inventory.equipItem()
	
	Inventory.load_items()

#tills 3 tiles of soil the player is facing towards
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
		
	#create tilled soil
	#check that the square is first a soil square and that it isn't already watered or hoed. It also must have no junk on it
	if Background2.get_cellv(Background2.world_to_map(pos)) == 15 and Dirt.get_cellv(Dirt.world_to_map(pos)) == -1 and Junk.get_cellv(Junk.world_to_map(pos)) == -1:
		Dirt.set_cellv(Dirt.world_to_map(pos), 0)
		if not Game.hoe.playing:
			Game.hoe.play()
	if Background2.get_cellv(Background2.world_to_map(Vector2(pos.x+x1,pos.y+y1))) == 15 and Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+x1,pos.y+y1))) == -1 and Junk.get_cellv(Junk.world_to_map(Vector2(pos.x+x1,pos.y+y1))) == -1:
		Dirt.set_cellv(Dirt.world_to_map(Vector2(pos.x+x1,pos.y+y1)), 0)
		if not Game.hoe.playing:
			Game.hoe.play()
	if Background2.get_cellv(Background2.world_to_map(Vector2(pos.x+x2,pos.y+y2))) == 15 and Dirt.get_cellv(Dirt.world_to_map(Vector2(pos.x+x2,pos.y+y2))) == -1 and Junk.get_cellv(Junk.world_to_map(Vector2(pos.x+x2,pos.y+y2))) == -1:
		Dirt.set_cellv(Dirt.world_to_map(Vector2(pos.x+x2,pos.y+y2)), 0)
		if not Game.hoe.playing:
			Game.hoe.play()

func swing_axe(pos, orientation):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
	
	if (Junk.get_cellv(Junk.world_to_map(pos)) == 0):
		Junk.set_cellv(Junk.world_to_map(pos), 1)
		if not Game.axe.playing: #do not overlap this sound
			Game.axe.play()
	elif (Junk.get_cellv(Junk.world_to_map(pos)) == 1) and not Game.axe.playing: #TODO temporary fix for running code twice
		Junk.set_cellv(Junk.world_to_map(pos), -1)
		if not Game.axe.playing: #do not overlap this sound
			Game.axe.play()

#deletes weeds
func swing_sickle(pos, orientation):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
	
	if (Junk.get_cellv(Junk.world_to_map(pos)) == 4):
		Junk.set_cellv(Junk.world_to_map(pos), -1)
		if not Game.sickle.playing: #do not overlap this sound
			Game.sickle.play()

#deletes weeds all around
func swing_sickle_circle(pos):
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x+tile_size.x, pos.y))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x+tile_size.x, pos.y)), -1)
		if not Game.sickle.playing: #do not overlap this sound
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x-tile_size.x, pos.y))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x-tile_size.x, pos.y)), -1)
		if not Game.sickle.playing:
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x, pos.y+tile_size.x))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x, pos.y+tile_size.x)), -1)
		if not Game.sickle.playing:
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x, pos.y-tile_size.x))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x, pos.y-tile_size.x)), -1)
		if not Game.sickle.playing:
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x+tile_size.x, pos.y+tile_size.x)), -1)
		if not Game.sickle.playing:
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x+tile_size.x, pos.y-tile_size.x)), -1)
		if not Game.sickle.playing:
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x-tile_size.x, pos.y+tile_size.x)), -1)
		if not Game.sickle.playing:
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x))) == 4):
		Junk.set_cellv(Junk.world_to_map(Vector2(pos.x-tile_size.x, pos.y-tile_size.x)), -1)
		if not Game.sickle.playing:
			Game.sickle.play()
	if (Junk.get_cellv(Junk.world_to_map(pos)) == 4):
		Junk.set_cellv(Junk.world_to_map(pos), -1)
		if not Game.sickle.playing:
			Game.sickle.play()

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
		if not Game.watering.playing:
			Game.watering.play()

#checks to make sure that there is a fully grown crop on this cell that is ready to harvest
#the id number of this crop is returned, or -1 if there is no crop ready for harvest on this square
func check_square_for_harvest(pos, orientation):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
	
	#the cell is a turnip
	if Crops.get_cellv(Crops.world_to_map(pos)) == 5:
		return 5
	#the cell is a strawberry
	elif Crops.get_cellv(Crops.world_to_map(pos)) == 35:
		return 35
	#the cell is an eggplant
	elif Crops.get_cellv(Crops.world_to_map(pos)) == 17:
		return 17
		
	return -1 #there is no crop ready for harvest on this square

#this is a "safe" function; it is only called if check_square_for_harvest() was called in the player script first
#thus, checking does not need to occur within this function to ensure the square is ready for harvest
func harvest_crop(pos, orientation):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
		
	#remove the crop from this tile
	Crops.set_cellv(Crops.world_to_map(pos), -1)
	if not Game.harvest.playing:
		Game.harvest.play()

#checks to make sure that there is nothing else on this square, so that the player may drop a harvested crop they are holding on this square
#returns true if the player may drop their item, returns false otherwise
func check_square_for_drop(pos, orientation):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
		
	#ensures there are no crops or non-passable objects on this tile
	if Crops.get_cellv(Crops.world_to_map(pos)) != -1:
		return false
	elif Objects1.get_cellv(Objects1.world_to_map(pos)) != -1:
		return false
	elif Objects2.get_cellv(Objects2.world_to_map(pos)) != -1:
		return false
	elif Objects2.world_to_map(pos) == house_location: #the player is trying to drop a crop on a teleport tile
		return false
		
	return true

#this is a "safe" function; it is only called if check_square_for_drop() was called in the player script first
#thus, checking does not need to occur within this function to ensure the square is clear for a harvested crop to be dropped on
func drop_crop(pos, orientation, crop_number):
	if orientation == "up":
		pos.y -= tile_size.x
	elif orientation == "down":
		pos.y += tile_size.x
	elif orientation == "right":
		pos.x += tile_size.x
	elif orientation == "left":
		pos.x -= tile_size.x
		
	Crops.set_cellv(Crops.world_to_map(pos), crop_number)
	if not Game.drop.playing:
		Game.drop.play()

#waters all unwatered, tilled soil
func simulate_rain():
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			#the cell must be tilled and unwatered to be watered by rain
			if (Dirt.get_cell(x,y) == 0):
				Dirt.set_cell(x,y,2)