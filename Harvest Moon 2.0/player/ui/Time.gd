extends Label

var hour = 0
var minute = 0

func _ready():
	hour = 6
	minute = 0
func _process(delta):
	if hour > 23 :
		hour = 0
		
	if minute > 59 :
		minute = 0
		hour += 1
		
	set_text(str(hour).pad_zeros(2)+":"+str(minute).pad_zeros(2))

func _on_Timer_timeout():
	minute += 5
	
func set_time(h, m):
	hour = h
	minute = m
	
func set_new_day():
	hour = 6
	minute = 0
	