tool
extends Resource

## Resource used by the SpawnerTileMap to match tile ids with a PackedScene

#  RESOURCE VARIABLES

export (Dictionary) var dictionary: Dictionary setget set_dictionary
var loaded_dictionary:bool = false

# METHODS

## Set the dictionary that stores the tile ids and PackedScenes
func set_dictionary(new_dictionary:Dictionary):
	for id in new_dictionary.keys():
		var scene = new_dictionary[id][0]
		if scene and not (scene is PackedScene):
			printerr("TileToSceneDictionary in key = " +str(id)+ ": The added value should be a PackedScene")
			return
	dictionary = new_dictionary

## Returns the PackedScene related to a tile id
func get_scene_by_tile_id(id: String) -> Array:
	return dictionary.get(id, [])

func get_class():
	return "TileToSceneDictionary"
