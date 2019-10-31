extends Control

onready var Bar = get_node("Backdrop/Filled Bar")

#subtracts the player's energy
func take_action():
	Bar.value -= 1

#resets the player's energy
func reset_energy():
	Bar.value = 50 #50 energy maximum

#returns true if the player has energy
func has_energy():
	if Bar.value == 0:
		return false
	return true