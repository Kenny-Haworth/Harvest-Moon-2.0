extends HBoxContainer

var current = 50
var maximum = 50

func _ready():
	pass
	
func _process(delta):
	$Bar.value = current
	$Bar.max_value = maximum
	$Number.set_text(str(current)+"/"+str(maximum))
	
func use_energy():
	current = current - 1
	$Bar.value = current
	print(current)