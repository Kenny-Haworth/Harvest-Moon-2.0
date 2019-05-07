extends Node

var url = "user://PlayerData.bin"
var inventory = {}
var maxSlots = 30
onready var playerData = Global_Parser.load_data(url)

func _ready():
	load_data()

func load_data():
	if playerData == null:
		var dict = {"inventory":{}}
		for slot in range (0, maxSlots):
			dict["inventory"][String(slot)] = {"id": "0", "amount": 0}
		Global_Parser.write_data(url, dict)
		inventory = dict["inventory"]
	else:
		inventory = playerData["inventory"]
		
func empty_data():
	var dict = {"inventory":{}}
	for slot in range (0, maxSlots):
		dict["inventory"][String(slot)] = {"id": "0", "amount": 0}
	Global_Parser.write_data(url, dict)
	inventory = dict["inventory"]

func getEmptySlot():
	for slot in range(0, maxSlots):
		if inventory[String(slot)]["id"] == "0": return int(slot)
	print ("Inventory is full!")
	return -1
	
func inventory_addItem(var itemId):
	var itemData = Global_ItemData.get_item(String(itemId))
	if itemData == null: return
	if !itemData["stackable"]:
		var slot = getEmptySlot()
		if slot < 0: return
		inventory[String(slot)] = {"id": String(itemId), "amount": 1}
		return
	for slot in range (0, maxSlots):
		if inventory[String(slot)]["id"] ==  String(itemId):
			inventory[String(slot)]["amount"] = int(inventory[String(slot)]["amount"] + 1)
			return
	var slot = getEmptySlot()
	if slot < 0: return
	inventory[String(slot)] = {"id": String(itemId), "amount": 1}

func inventory_addItems(var itemId, var number):
	var itemData = Global_ItemData.get_item(String(itemId))
	if itemData == null: return
	if !itemData["stackable"]:
		var slot = getEmptySlot()
		if slot < 0: return
		inventory[String(slot)] = {"id": String(itemId), "amount": number}
		return
	for slot in range (0, maxSlots):
		if inventory[String(slot)]["id"] ==  String(itemId):
			inventory[String(slot)]["amount"] = int(inventory[String(slot)]["amount"] + number)
			return
	var slot = getEmptySlot()
	if slot < 0: return
	inventory[String(slot)] = {"id": String(itemId), "amount": number}

func inventory_removeItem(var slot):
	if int(inventory[String(slot)]["id"]) < 1: return
	var newAmount = inventory[String(slot)]["amount"] - 1
	if newAmount < 1:
		inventory[String(slot)] = {"id": "0", "amount": 0}
		return 0
	inventory[String(slot)]["amount"] = newAmount
	return newAmount
	
func inventory_moveItem(var fromSlot, var toSlot):
	var temp_toSlotItem = inventory[String(toSlot)]
	inventory[String(toSlot)] = inventory[String(fromSlot)]
	inventory[String(fromSlot)] = temp_toSlotItem

func get_number(var slot):
	return inventory[String(slot)]["amount"]