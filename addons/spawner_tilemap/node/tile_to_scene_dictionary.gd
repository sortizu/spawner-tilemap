tool
extends Resource

## Resource used by the SpawnerTileMap to match tile ids with a PackedScene

const SceneSettings: GDScript = preload("res://addons/spawner_tilemap/node/scene_settings.gd")

#  RESOURCE VARIABLES

export (Dictionary) var dictionary: Dictionary setget set_dictionary
var loaded_dictionary:bool = false

# METHODS

## Set the dictionary that stores the tile ids and PackedScenes
func set_dictionary(new_dictionary:Dictionary):
	for id in new_dictionary.keys():
		var scene = new_dictionary[id].selected_scene
		if scene and not (scene is PackedScene):
			printerr("TileToSceneDictionary in key = " +str(id)+ ": The added value should be a PackedScene")
			return
	dictionary = new_dictionary

## Returns the SceneSettings related to a tile id
func get_scene_settings_by_tile_id(id: String) -> SceneSettings:
	return dictionary.get(id)

func get_class():
	return "TileToSceneDictionary"
