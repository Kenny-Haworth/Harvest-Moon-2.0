extends VBoxContainer

# functions that can be used in player class aside from default
# new_day() 
# resets the timer and add 1 to the day
# recommended to use set_weather("") with new_day()
# recommended to use reset_energy() with new_day()
#
# set_day(d)
# set the exact day
#
# set_time(h, m)
# set the exact time
#
# example usage in player class
# $UI/Date/Layout.new_day()

var season = "Spring"
var day = 1
var hour = 0
var minute = 0

func _ready():
	hour = 6
	minute = 0
	pass

func _process(delta):
	if hour > 23 :
		hour = 0
	if minute > 59 :
		minute = 0
		hour += 1
	
	if (day < 15) :
		season = "Spring"
	elif (day < 30) :
		season = "Summer"
	elif (day < 45) :
		season = "Fall"
	elif (day < 60) :
		season = "Winter"
		
	$Season.set_text(season)
	$Day.set_text("Day " + str(day))
	$Time.set_text(str(hour).pad_zeros(2) + ":" + str(minute).pad_zeros(2))


func _on_Timer_timeout():
	minute += 10
	
func new_day():
	hour = 6
	minute = 0
	day += 1
	
func set_day(d):
	day = d

func set_time(h, m):
	hour = h
	minute = m

