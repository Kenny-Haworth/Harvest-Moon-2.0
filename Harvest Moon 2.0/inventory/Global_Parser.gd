extends Node

onready var file = File.new()

func load_data(url):
	if !file.file_exists(url): return
	file.open(url, File.READ)
	var data = JSON.parse(file.get_as_text())
	file.close()
	return data.result

func write_data(url, dict):
	if url == null: return
	file.open(url, File.WRITE)
	file.store_line(to_json(dict))
	file.close()
	return
