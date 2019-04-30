extends Label

var season = "Season"

func _process(delta):
	set_text(season)

func set_season(seas):
	season = seas