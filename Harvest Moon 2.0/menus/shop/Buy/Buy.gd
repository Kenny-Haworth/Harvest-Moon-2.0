#handles buying items in the shop menu

extends Control

#for disabling the buy menu when the sell menu is open
onready var Sell = get_parent().get_node("Sell")

#for playing the purchase sound
onready var SoundManager = get_node("/root/Game/Sound")

#for disabling and enabling buttons depending on how much gold the player has
onready var plus_1 = get_node("Amount/ButtonContainer/+1")
onready var plus_5 = get_node("Amount/ButtonContainer/+5")
onready var Max = get_node("Amount/ButtonContainer/Max")

#the amount of gold the player currently has
var gold = 0

#for updating the labels
onready var Your_Gold = get_node("Your Gold")
onready var Amount = get_node("Amount/Amount")
onready var Total = get_node("Total")

#for displaying purchase information on the purchase table
var Close = []
var Item = []
var Cost_Per_Item = []
var Cart = []
var Current = []
var After = []
var Total_Cost = []

#the amount of items for the current transaction
var amount = 0

#the amount of table rows currently filled on-screen
var table_rows_filled = 0

#the current row selected to update in the table
var current_row = 0

#an array containing all indicator positions at which an item was added to the table
var index_of_items_chosen = []

#for moving the chosen item indicator
onready var Chosen_Item_Indicator = get_node("Chosen Item Indicator")

#the position of the chosen item indicator
var indicator_position = 1

#for getting the player's current gold, inventory items, and adding/subtracting items from the inventory
onready var Inventory = get_node("/root/Game/Farm/Player/UI/Inventory")

#(Buyable Item, Cost); this list is static
const buyableItems = {"Sickle":50, "Axe":200, "Hammer":500, "TurnipSeeds":5, "StrawberrySeeds":10, "EggplantSeeds":20}

#a dictionary for holding all [textures, labels] in the buy window
var textures_and_labels = {}

#initialize the buy window for the first time; this only needs to happen once
func _ready():
	
	#add all the current textures and labels to a dictionary for the buy window
	for button in get_node("Purchase Grid").get_children():
		var texture_and_label = button.get_children()
		textures_and_labels[texture_and_label[0]] = texture_and_label[1]
	
	#add all buyable items to the buy window
	var items = buyableItems.keys()
	var costs = buyableItems.values()
	
	for texture in textures_and_labels.keys():
		texture.set_texture(load("res://ui/inventory/tools and items/" + items.pop_front() + ".png"))
		textures_and_labels[texture].set_text(str(costs.pop_front()))
		
		#stop once all items have been added
		if items.empty():
			break
	
	#add all buttons, textures, and labels to their respective arrays for the purchase table
	for button in get_node("Purchase Table/Close").get_children():
		Close.push_back(button)
	
	for texture in get_node("Purchase Table/Item").get_children():
		Item.push_back(texture)
	
	for label in get_node("Purchase Table/Cost Per Item").get_children():
		Cost_Per_Item.push_back(label)
	
	for label in get_node("Purchase Table/Cart").get_children():
		Cart.push_back(label)
	
	for label in get_node("Purchase Table/Current").get_children():
		Current.push_back(label)
	
	for label in get_node("Purchase Table/After").get_children():
		After.push_back(label)
	
	for label in get_node("Purchase Table/Total Cost").get_children():
		Total_Cost.push_back(label)
	
	update_your_gold()
	_add_purchase_table_row()

#resets the menu when the player closes and reopens the shop
func reset_menu():
	_clear_purchase_table()
	_move_chosen_item_indicator(1)
	update_your_gold()

#updates the buy menu after switching from the sell tab
func update_buy_menu():
	update_your_gold()
	
	#update the "current" and "after" fields in each row, as more items may have just been purchased in the buy tab
	for i in range(table_rows_filled):
		var itemName = buyableItems.keys()[index_of_items_chosen[i]-1]
		var number = Inventory.get_amount(itemName)
		
		Current[i].set_text(str(number))
		After[i].set_text(str(int(Cart[i].get_text())+number))

#handles moving the equipped item indicator
func _input(event):
	
	#disable the buy menu when the sell menu is visible
	if Sell.visible:
		return
	
	if Input.is_action_pressed("ui_up"):
		_move_chosen_item_indicator(indicator_position-4)
	elif Input.is_action_pressed("ui_down"):
		_move_chosen_item_indicator(indicator_position+4)
	elif Input.is_action_pressed("ui_left"):
		_move_chosen_item_indicator(indicator_position-1)
	elif Input.is_action_pressed("ui_right"):
		_move_chosen_item_indicator(indicator_position+1)

#moves the chosen item indicator
func _move_chosen_item_indicator(position):
	#ignore invalid positions
	if position < 1 or position > 16:
		return
	
	indicator_position = position
	Chosen_Item_Indicator.rect_position = Vector2(267 + ((((indicator_position-1) % 4))*362), 241 + (((indicator_position-1)/4)*362))
	
	#the previous row had 0 on the amount and the table was not filled - it can be removed
	if amount == 0 and table_rows_filled != 4:
		_delete_purchase_table_row(current_row)
	
	#the row already exists in the table
	if index_of_items_chosen.has(indicator_position):
		
		#move the current_row indicator to the proper position
		current_row = index_of_items_chosen.find(indicator_position)
		amount = int(Cart[current_row].get_text())
	
	#the row is being added to the table for the first time
	else:
		_add_purchase_table_row()
		current_row = table_rows_filled
		amount = 0
	
	_update_amount()
	_update_amount_buttons()

#adds a purchase table row
#if all rows are already filled, does nothing
func _add_purchase_table_row():
	
	if table_rows_filled == 4:
		return
	
	#there is an item being hovered over
	if indicator_position <= buyableItems.size():
		Item[table_rows_filled].set_texture(textures_and_labels.keys()[indicator_position-1].get_texture())
		Cost_Per_Item[table_rows_filled].set_text(str(textures_and_labels.values()[indicator_position-1].get_text()))
		Cart[table_rows_filled].set_text("0")
		
		var itemName = buyableItems.keys()[indicator_position-1]
		var number = Inventory.get_amount(itemName)
		
		Current[table_rows_filled].set_text(str(number))
		After[table_rows_filled].set_text(str(number))
		Total_Cost[table_rows_filled].set_text("0")
		
	#set the text to nothing if there is nothing hovering over to buy
	else:
		_delete_purchase_table_row(table_rows_filled)

#updates a purchase table row
func _update_purchase_table_row():
	Cart[current_row].set_text(str(amount))
	
	var current = int(Current[current_row].get_text())
	After[current_row].set_text(str(amount+current))
	
	var cost_per_item = int(Cost_Per_Item[current_row].get_text())
	Total_Cost[current_row].set_text(str(cost_per_item*amount))
	
	var total = int(Total_Cost[0].get_text()) + int(Total_Cost[1].get_text()) + int(Total_Cost[2].get_text()) + int(Total_Cost[3].get_text())
	Total.set_text(str(total))

#deletes a purchase table row
#if there are rows beneath this table, they are moved up
func _delete_purchase_table_row(row_index):
	
	#get how many rows are filled in the inventory
	var num_rows_currently_filled = 0
	
	for item in Item:
		if item.get_texture() != null:
			num_rows_currently_filled += 1
	
	#there are other rows beneath this row that must be moved up
	if num_rows_currently_filled - row_index >= 2:
		var copy_operations = num_rows_currently_filled - row_index - 1
		
		for i in range(copy_operations):
			#row_index+1 onto row_index
			Item[row_index].set_texture(Item[row_index+1].get_texture())
			Cost_Per_Item[row_index].set_text(Cost_Per_Item[row_index+1].get_text())
			Cart[row_index].set_text(Cart[row_index+1].get_text())
			Current[row_index].set_text(Current[row_index+1].get_text())
			After[row_index].set_text(After[row_index+1].get_text())
			Total_Cost[row_index].set_text(Total_Cost[row_index+1].get_text())
			
			row_index += 1
		
		row_index = num_rows_currently_filled-1
		
	#this is the last row in the table
	Item[row_index].set_texture(null)
	Cost_Per_Item[row_index].set_text("")
	Cart[row_index].set_text("")
	Current[row_index].set_text("")
	After[row_index].set_text("")
	Total_Cost[row_index].set_text("")

#removes all rows from the purchase table
func _clear_purchase_table():
	for i in range(4):
		_delete_purchase_table_row(0)
	
	table_rows_filled = 0
	current_row = 0
	index_of_items_chosen.clear()
	Total.set_text("")

func update_your_gold():
	Your_Gold.set_text(str(Inventory.get_amount("Gold")))
	gold = Inventory.get_amount("Gold")

#set the amount label
func _update_amount():
	#reset the amount to a good value if it went negative on a button being pressed
	if amount < 0:
		amount = 0
	
	Amount.set_text(str(amount))

#enables or disables the buy buttons depending if the player can add another of that item to their list
func _update_amount_buttons():
	
	#if all rows are filled and a row is not being updated, disable the amount buttons
	if table_rows_filled == 4 and not index_of_items_chosen.has(indicator_position):
		plus_1.disabled = true
		plus_5.disabled = true
		Max.disabled = true
		return
	
	var total = int(Total.get_text())
	var cost_per_item = int(Cost_Per_Item[current_row].get_text())
	
	#disable all the buttons if the indicator is on a blank square
	if cost_per_item == 0:
		plus_1.disabled = true
		plus_5.disabled = true
		Max.disabled = true
		return
	
	#you can't buy 5 more of that item
	if total + (cost_per_item*5) > gold:
		plus_5.disabled = true
	else:
		plus_5.disabled = false
	
	#you can't buy 1 more of this item
	if total + cost_per_item > gold:
		plus_1.disabled = true
		Max.disabled = true
	else:
		plus_1.disabled = false
		Max.disabled = false

#buys all items in the purchase table and clears the table
func _on_Purchase_pressed():
	#disable purchasing if there is nothing in the cart
	if table_rows_filled == 0:
		return
	
	#play the purchase sound effect
	SoundManager.play_effect("purchase")
	
	#remove gold from inventory
	var total = int(Total.get_text())
	gold -= total
	Inventory.remove("Gold", total)
	
	#add all items that were in the grid to the inventory
	var row_num = 0
	
	for index in index_of_items_chosen:
		Inventory.add(buyableItems.keys()[index-1], int(Cart[row_num].get_text()))
		row_num += 1
	
	reset_menu()

#adds or subtracts 1 or 5 from amount
func _on_plus_or_minus_amount_pressed(amount_to_add):
	#a table row is added if amount was 0 and was then incremented
	if amount == 0 and amount_to_add > 0:
		table_rows_filled += 1
		index_of_items_chosen.push_back(indicator_position)
	
	#a table row is removed if amount was not 0 and became 0
	if amount != 0 and amount + amount_to_add <= 0:
		table_rows_filled -= 1
		index_of_items_chosen.erase(indicator_position)
	
	amount += amount_to_add
	_update_amount()
	_update_purchase_table_row()
	_update_amount_buttons()

func _on_Max_pressed():
	#a table row was added
	if amount == 0:
		table_rows_filled += 1
		index_of_items_chosen.push_back(indicator_position)
	
	var cost_per_item = int(Cost_Per_Item[current_row].get_text())
	var total_cost = int(Total_Cost[current_row].get_text())
	var total = int(Total.get_text())
	amount = ((gold-total+total_cost)/cost_per_item)
	_update_amount()
	_update_purchase_table_row()
	_update_amount_buttons()

func _on_Min_pressed():
	#a table row was removed
	if amount != 0:
		table_rows_filled -= 1
		index_of_items_chosen.erase(indicator_position)
	
	amount = 0
	_update_amount()
	_update_purchase_table_row()
	_update_amount_buttons()

#for when the user clicks directly on a square
func _on_Button_pressed(position):
	_move_chosen_item_indicator(position)