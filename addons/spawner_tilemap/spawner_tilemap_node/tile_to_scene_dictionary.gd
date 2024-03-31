tool
extends Resource
class_name TileToSceneDictionary
# ---------------------------- RESOURCE VARIABLES --------------------------
export (Dictionary) var dictionary: Dictionary setget set_dictionary
var loaded_dictionary:bool = false

func set_dictionary(new_dictionary:Dictionary):
	for id in new_dictionary.keys():
		if not (id is int):
			printerr("TileToSceneDictionary: The added key should be an integer")
			return
		var scene = new_dictionary[id]
		if scene and not (scene is PackedScene):
			printerr("TileToSceneDictionary in key = " +str(id)+ ": The added value should be a PackedScene")
			return
	dictionary = new_dictionary

func get_scene_by_tile_id(id:int)->PackedScene:
	return dictionary[id]
