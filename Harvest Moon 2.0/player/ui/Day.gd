extends Label

var day = "Day"
var num = 1


func _process(delta):
	set_text(str(day) + " " + str(num))
	
func set_day(n):
	num = n

func set_new_day():
	num = num + 1