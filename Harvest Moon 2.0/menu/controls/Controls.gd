extends Control
onready var popup = get_node("Controls/LeftMargin/Description/Popup")
onready var popup2 = get_node("Controls/LeftMargin/Description/Popup/Popup2")
var action
var character = ""

func _ready():
	
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
onready var LE = get_node("Controls/LeftMargin/Description/Popup/InfoRebind")
onready var LE2 = get_node("Controls/LeftMargin/Description/Popup/Popup2/InfoRebind")

func _on_Button_pressed():
	get_tree().change_scene("res://menu/main/MainMenu.tscn")
func _on_Button2_pressed():
	get_tree().change_scene("res://menu/controls/RemapControls.tscn")


func _input(event):	
	if event is InputEventKey:
		character = char(event.unicode)
		LE.set_text(str(LE.get_text(), character))
		LE2.set_text(str("Successfully rebinded!"))
		InputMap.action_add_event(action, event)
		popup2.show()
		
		

func _on_Up_pressed():
	popup2.hide()
	action = "ui_up"
	LE.set_text(str("Select new key for: ", get_node("Controls/LeftMargin/Description/Up").get_text(), "  : ", character)) 
	popup.show()
	pass # replace with function body


func _on_Down_pressed():
	popup2.hide()
	action = "ui_down"
	LE.set_text(str("Select new key for: ", get_node("Controls/LeftMargin/Description/Down").get_text(), " : ", character)) 
	popup.show()
	pass # replace with function body


func _on_Left_pressed():
	popup2.hide()
	action = "ui_left"
	LE.set_text(str("Select new key for: ", get_node("Controls/LeftMargin/Description/Left").get_text(), " : ", character)) 
	popup.show()
	pass # replace with function body


func _on_Right_pressed():
	popup2.hide()
	action = "ui_right"
	LE.set_text(str("Select new key for: ", get_node("Controls/LeftMargin/Description/Right").get_text(), " : ", character)) 
	popup.show()
	pass # replace with function body


func _on_Use_Select_pressed():
	popup2.hide()
	action = "ui_select"
	LE.set_text(str("Select new key for:  ", get_node("Controls/LeftMargin/Description/Use Select").get_text(), " : ", character)) 
	popup.show()
	pass # replace with function body


func _on_Inventory_pressed():
	popup2.hide()
	action = "ui_focus_next"
	LE.set_text(str("Select new key for: ", get_node("Controls/LeftMargin/Description/Inventory").get_text(), " : ", character)) 
	popup.show()
	pass # replace with function body


func _on_Pickup_pressed():
	popup2.hide()
	action = "I"
	LE.set_text(str("Select new key for: ", get_node("Controls/LeftMargin/Description/Pickup").get_text(), " : ", character)) 
	popup.show()
	pass # replace with function body


func _on_Pause_pressed():
	popup2.hide()
	action ="ui_cancel"
	LE.set_text(str("Select new key for: ", get_node("Controls/LeftMargin/Description/Pause").get_text(), " : ", character)) 
	popup.show()
	pass # replace with function body
