extends Label

var hour = 0
var minute = 0

func _ready():
	hour = 6
	minute = 55
func _process(delta):
	if hour > 12 :
		hour = 0
		
	if minute > 59 :
		minute = 0
		hour += 1
		
	set_text(str(hour)+":"+str(minute).pad_zeros(2))

func _on_Timer_timeout():
	minute += 1