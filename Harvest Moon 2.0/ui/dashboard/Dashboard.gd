extends TextureRect

#sets the TimeManager and weather for a new day
func new_day():
	$TimeManager.new_day() #sets the time, day, and season for a new day
	$Weather.new_day() #rolls for a chance of weather on a new day