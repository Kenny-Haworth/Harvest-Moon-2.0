extends HBoxContainer

var current = 25
var maximum = 50

func _ready():
	pass

func _process(delta):
	$Bar.value = current
	$Bar.max_value = maximum
	$Number.set_text(str(current)+"/"+str(maximum))