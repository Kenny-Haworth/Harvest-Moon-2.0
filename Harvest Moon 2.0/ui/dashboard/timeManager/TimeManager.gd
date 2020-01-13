extends VBoxContainer

#for telling other classes when to sleep
signal sleep

#for fading in the proper shaders at the proper time
onready var Shaders = get_node("/root/Game/Shaders")

#for changing the weather image when night comes
onready var Weather = get_parent().get_node("Weather")

var day = 1
var hour = 6
var armyTimeHour = 6
var minute = 0
var period = "AM"
var season = "Spring"

#updates the time, season, and day for each new day
func new_day():
	day += 1
	hour = 6
	armyTimeHour = 6
	minute = 0
	period = "AM"
	
	#each season is 15 days and repeats
	if (day % 61 <= 15):
		season = "Spring"
	elif (day % 61 <= 30):
		season = "Summer"
	elif (day % 61 <= 45):
		season = "Fall"
	elif (day % 61 <= 60):
		season = "Winter"
	
	#redraw the time, season, and day
	$Time.set_text(str(hour) + ":" + str(minute).pad_zeros(2) + " " + period)
	$Season.set_text(season)
	$Day.set_text("Day " + str(day))

func _on_Timer_timeout():
	minute += 1
	
	if minute == 60: #convert minutes to hours
		minute = 0
		hour += 1
		armyTimeHour += 1
	if hour == 12 && minute == 0: #every 12 hours it swaps from AM to PM
		if period == "AM":
			period = "PM"
		else:
			period = "AM"
	if hour == 13: #change back to hour 1
		hour = 1
	
	$Time.set_text(str(hour) + ":" + str(minute).pad_zeros(2) + " " + period)
	
	#toggle the tweeners changing
	if armyTimeHour == 6 && minute == 0: #6 in the morning TODO this logic point will never be hit
		Shaders.fade_in_shader("afternoon")
	elif armyTimeHour == 12 && minute == 0: #12 in the afternoon
		Shaders.fade_in_shader("evening")
	elif armyTimeHour == 17 && minute == 0: #5 in the evening
		Shaders.fade_in_shader("night")
	
	#toggle changing the weather image to night when night comes and it is not raining
	if armyTimeHour == 20: #8pm
		Weather.set_weather_to_night()
	
	#emit the sleep signal if it is 11pm
	if armyTimeHour == 23 and minute == 0:
		emit_signal("sleep")