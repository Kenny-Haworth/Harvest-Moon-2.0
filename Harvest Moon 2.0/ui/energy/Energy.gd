extends HBoxContainer

#functions available in energy class aside from default
#take_action()
#subtracts one to the energy bar
#reset_energy()
#set the energy back to the default maximum value
var maximum = 53 #50 total actions before the player becomes exhausted
var current = 53 

func _ready():
	pass

func _process(delta):
	$Bar.value = current
	$Bar.max_value = maximum
	
func take_action():
	if current == maximum:
		current = current - 4
	else:
		current = current - 1
	$Bar.value = current
	
func reset_energy():
	current = maximum