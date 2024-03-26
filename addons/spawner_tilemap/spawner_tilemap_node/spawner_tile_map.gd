tool
extends TileMap
class_name SpawnerTileMap
# ----------------------- Class Variables -----------------------
# Instance the scenes according to the tiles showed in the tilemap
# or disable the instancing function (it will work as usual tilemap)
export (bool) var spawn_scenes_at_start
# Clean the tilemap after instancing the scenes
export (bool) var clean_after_spawning
# Path of the node to store all the scenes instances setted on tile_to_scene_dictionary
export (NodePath) var container_node_path: NodePath
# TileToSceneDictionary resource instance
export (Resource) var tile_to_scene_dictionary: Resource setget set_tile_to_scene_dictionary
# Placeholder for spawn scenes button
export (bool) var _spawn_scenes

func _init() -> void:
	if not tile_to_scene_dictionary:
		tile_to_scene_dictionary = TileToSceneDictionary.new()
		# warning-ignore:unsafe_property_access
		tile_to_scene_dictionary.loaded_dictionary=true

func _ready() -> void:
	if not Engine.editor_hint:
		if spawn_scenes_at_start:
			instance_scenes_from_dictionary()
			if clean_after_spawning:
				clear()

func set_tile_to_scene_dictionary(new_tile_to_node_dict:Resource):
	if new_tile_to_node_dict is TileToSceneDictionary or not new_tile_to_node_dict:
		tile_to_scene_dictionary=new_tile_to_node_dict
	else:
		printerr("Resource set in tile_to_scene_dictionary is not a TileToSceneDictionary type")

func instance_scenes_from_dictionary():
	var container_node = get_node_or_null(container_node_path)
	if not container_node:
		printerr("There isn't any container node selected to instance the scenes. The instancing process will stop.")
		return
	for cell_pos in get_used_cells():
		var tile_id = get_cell(cell_pos.x,cell_pos.y)
		# warning-ignore:unsafe_method_access
		var scene: PackedScene = tile_to_scene_dictionary.get_scene_by_tile_id(tile_id)
		if scene:
			var new_scene_instance = scene.instance()
			new_scene_instance.position = Vector2(cell_pos.x*cell_size.x,cell_pos.y*cell_size.y)
			container_node.add_child(new_scene_instance)
		else:
			printerr("Tile with id:"+str(tile_id)+" does not have any related scene in the tile to scene dictionary.")
