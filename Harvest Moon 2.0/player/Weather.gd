extends Sprite


var cloud = preload("res://player/ui/cloud.jpg")
var sun = preload("res://player/ui/sun.jpg")
var cur = cloud

func _ready():
	set_texture(cloud)
	pass
func _process(delta):
	set_texture(cur)
	
func set_weather(w):
	if w == "cloud":
		cur = cloud
	if w == "sun":
		cur = sun
	
