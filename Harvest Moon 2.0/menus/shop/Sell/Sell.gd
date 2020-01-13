extends Control

#for disabling the sell menu when the buy menu is open
onready var Buy = get_parent().get_node("Buy")

#for playing the sell sound
onready var SoundManager = get_node("/root/Game/Sound")

#for displaying and updating how much gold the player has
onready var Your_Gold = get_node("Your Gold")

#for disabling and enabling buttons depending on how much gold the player has
onready var plus_1 = get_node("Amount/ButtonContainer/+1")
onready var plus_5 = get_node("Amount/ButtonContainer/+5")
onready var Max = get_node("Amount/ButtonContainer/Max")

#the amount of gold the player currently has
var gold = 0

#for updating labels
onready var Value_Per_Item = get_node("Value Per Item")
onready var You_Currently_Have = get_node("You Currently Have")
onready var Total_Value = get_node("Total Value")
onready var Amount = get_node("Amount/Amount")

#the amount of items for the current transaction
var amount = 0

#for moving the chosen item indicator
onready var Chosen_Item_Indicator = get_node("Chosen Item Indicator")

#the position of the chosen item indicator
var indicator_position = 1

#for getting the player's current gold, inventory items, and adding/subtracting items from the inventory
onready var Inventory = get_node("/root/Game/Farm/Player/UI/Inventory")

#a list of items that can be sold, according to (Sellable Item, Value)
const sellableItems = {"Sickle":10, "Axe":50, "Hammer":150, "Turnip":10, "Strawberry":20, "Eggplant":45, "TurnipSeeds":1, "StrawberrySeeds":2, "EggplantSeeds":5}

#a list of all (Current Items, Amounts) in the Inventory that are sellable
var currentItems = {}

#three arrays for holding all [textures, amounts labels, values labels] in the sell menu
var textures = []
var amounts = []
var values = []

#add all the current textures and labels nodes to the arrays
func _ready():
	for button in get_node("Item Grid Container").get_children():
		var texture_label_and_label = button.get_children()
		textures.append(texture_label_and_label[0])
		amounts.append(texture_label_and_label[1])
		values.append(texture_label_and_label[2])

#resets the menu when the player closes and reopens the shop
func reset_menu():
	_move_chosen_item_indicator(1)

#adds all items that can be sold to the sell window, along with their amounts and prices
#updates your gold, the value per item, and how much you currently have
func update_sell_menu():
	
	#clear any previous values
	for i in currentItems.size():
		textures[i].set_texture(null)
		amounts[i].set_text("")
		values[i].set_text("")
	
	currentItems.clear()
	
	#the current index of items added to the inventory
	var index = 0
	
	for item in sellableItems.keys():
		var amount = Inventory.get_amount(item)
		
		if amount > 0:
			textures[index].set_texture(load("res://ui/inventory/tools and items/" + item + ".png"))
			
			if amount > 1:
				amounts[index].set_text(str(amount))
			else:
				amounts[index].set_text("")
			
			values[index].set_text(str(sellableItems[item]))
			index+=1
			currentItems[item] = amount
	
	_update_your_gold()
	_update_amount_buttons()
	_update_value_per_item_and_currently_have()

#handles moving the equipped item indicator
func _input(event):
	
	#disable the sell menu when the buy menu is visible
	if Buy.visible:
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
	Chosen_Item_Indicator.rect_position = Vector2(300 + ((((indicator_position-1) % 4))*362), 334 + (((indicator_position-1)/4)*362))
	_update_value_per_item_and_currently_have()
	amount = 0
	_update_amount_and_total_value()
	_update_amount_buttons()

#updates the value per item and how many of that item are currently in the inventory
func _update_value_per_item_and_currently_have():
	Value_Per_Item.set_text(str(values[indicator_position-1].get_text()))
	
	#set the text to nothing if there is nothing hovering over to sell
	if indicator_position > currentItems.size():
		You_Currently_Have.set_text("")
		return

	You_Currently_Have.get("custom_fonts/font").size = 100
	var itemName = currentItems.keys()[indicator_position-1]
	var number = Inventory.get_amount(itemName)
	
	#insert a space and make the font size smaller if it is a seeds name
	if itemName.ends_with("Seeds"):
		itemName = itemName.insert(itemName.length()-5, " ")
		You_Currently_Have.get("custom_fonts/font").size = 80
	
	#unique grammar case for strawberries
	if itemName == "Strawberry" and number > 1:
		itemName = "Strawberrie"

	#make the item singular if there is exactly 1 or it is seeds
	if number == 1 or itemName.ends_with("Seeds"):
		You_Currently_Have.set_text(str(number) + " " + itemName)
	else:
		You_Currently_Have.set_text(str(number) + " " + itemName + "s")

#updates the amount and total cost labels
func _update_amount_and_total_value():

	#reset the amount to a good value if it went negative on a button being pressed
	if amount < 0:
		amount = 0
	
	Amount.set_text(str(amount))
	Total_Value.set_text(str(int(Value_Per_Item.get_text())*amount))

func _update_your_gold():
	Your_Gold.set_text(str(Inventory.get_amount("Gold")))
	gold = Inventory.get_amount("Gold")

#disables the amount buttons if there is not enough of the item to sell
func _update_amount_buttons():
	
	#assume the currentAmount is 0; if the indicator is lying on a valid slot, grab the currentAmount
	var currentAmount = 0
	
	if indicator_position <= currentItems.size():
		currentAmount = currentItems.values()[indicator_position-1]
	
	#you can't sell 5 more of that item
	if amount + 5 > currentAmount:
		plus_5.disabled = true
	else:
		plus_5.disabled = false
	
	#you can't buy 1 more of this item
	if amount + 1 > currentAmount:
		plus_1.disabled = true
		Max.disabled = true
	else:
		plus_1.disabled = false
		Max.disabled = false

func _on_Sell_pressed():
	#disable selling if there is nothing in the cart
	if amount == 0:
		return
	
	#play the sell sound
	SoundManager.play_effect("sell")
	
	#add gold to the inventory
	var totalValue = int(Total_Value.get_text())
	gold += totalValue
	Inventory.add("Gold", totalValue)
	
	#remove items from inventory
	Inventory.remove(currentItems.keys()[indicator_position-1], amount)
	
	#update the shop menu
	amount = 0
	_update_amount_and_total_value()
	update_sell_menu()

func _on_plus_1_pressed():
	amount += 1
	_update_amount_and_total_value()
	_update_amount_buttons()

func _on_plus_5_pressed():
	amount += 5
	_update_amount_and_total_value()
	_update_amount_buttons()

func _on_Max_pressed():
	amount = currentItems[currentItems.keys()[indicator_position-1]]
	_update_amount_and_total_value()
	_update_amount_buttons()

func _on_minus_1_pressed():
	amount -= 1
	_update_amount_and_total_value()
	_update_amount_buttons()

func _on_minus_5_pressed():
	amount -= 5
	_update_amount_and_total_value()
	_update_amount_buttons()

func _on_Min_pressed():
	amount = 0
	_update_amount_and_total_value()
	_update_amount_buttons()

#for when the user clicks directly on a square
func _on_Button_pressed(position):
	_move_chosen_item_indicator(position)