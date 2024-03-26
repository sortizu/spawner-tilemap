tool
extends Resource
class_name TileToSceneDictionary

export (Array) var dictionary: Array setget set_dictionary
var loaded_dictionary:bool = false

func _init() -> void:
	pass

func set_dictionary(new_dictionary:Array):
	if loaded_dictionary and new_dictionary and new_dictionary.size()>dictionary.size():
		dictionary.append(TileToNodeRes.new())
	else:
		loaded_dictionary = true
		dictionary = new_dictionary

#func get_ids()->Array:
#	var id_array : Array = []
#	for tile_to_node in dictionary:
#		tile_to_node = tile_to_node as TileToNode
#		id_array.append(tile_to_node.tile_id)
#	return id_array

func get_scene_by_tile_id(id:int)->PackedScene:
	var index = dictionary.bsearch_custom(id,self,"compare",false)
	if index-1<len(dictionary) and id==dictionary[index-1].tile_id:
		return dictionary[index-1].scene
	else:
		return null
	
## Method used to do a binary search in the dictionary to find the index of
## a tile using its tile_id property
func compare(a,b):
	return a < b.tile_id
