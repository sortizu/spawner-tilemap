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
export (NodePath) var container_node_path: NodePath setget set_container_nodepath
onready var container_node = get_node_or_null(container_node_path)
# TileToSceneDictionary resource instance
# This variable is created automatically and modified by the TileToSceneEditor
# It stores each tile id as a key and a PackedScene as the value for each id.
# TIP: Set this variable manually if you are
# already using a similar dictionary format for your project.
var tile_to_scene_dictionary: TileToSceneDictionary
# ----------------------- SIGNALS -----------------------
signal scenes_instanced
signal instanced_scenes_cleaned

func _init() -> void:
	if not tile_to_scene_dictionary:
		var new_tile_to_scene_dict = TileToSceneDictionary.new()
		# warning-ignore:unsafe_property_access
		new_tile_to_scene_dict.loaded_dictionary=true
		tile_to_scene_dictionary = new_tile_to_scene_dict
	
func _ready() -> void:
	if not Engine.editor_hint:
		if spawn_scenes_at_start:
			instance_scenes_from_dictionary()

func _get_property_list() -> Array:
	var properties = []
	# Property editor to set the addon buttons
	properties.append({
		name="_manage_buttons",
		type=TYPE_NIL,
		usage =PROPERTY_USAGE_DEFAULT
	})
	# "Advanced settings" group in editor
	properties.append({
		name="Advanced Settings",
		type=TYPE_NIL,
		usage = PROPERTY_USAGE_GROUP
	})
	# TileToSceneDictionary variable export
	properties.append({
		classname = "",
		hint = 24,
		usage = PROPERTY_USAGE_DEFAULT,
		name="tile_to_scene_dictionary",
		type=TYPE_OBJECT
	})
	return properties

func _get(property: String):
	if property == "tile_to_scene_dictionary":
		return tile_to_scene_dictionary

func _set(property: String, value) -> bool:
	print(property+": "+str(value))
	if property == "tile_to_scene_dictionary":
		if not (value is TileToSceneDictionary or not value):
			printerr("Resource set in tile_to_scene_dictionary is not a TileToSceneDictionary type.")
		else:
			tile_to_scene_dictionary = value
			return false
	return true

# Instances scenes in the container node according to the visible tiles in this tilemap.
func instance_scenes_from_dictionary():
	if not container_node:
		printerr("SpawnerTileMap: There isn't any container node selected to instance the scenes.")
		return
	for cell_pos in get_used_cells():
		var tile_id = get_cell(cell_pos.x,cell_pos.y)
		# warning-ignore:unsafe_method_access
		var scene: PackedScene = tile_to_scene_dictionary.get_scene_by_tile_id(tile_id)
		if scene:
			var new_scene_instance = scene.instance()
			new_scene_instance.position = Vector2(cell_pos.x*cell_size.x,cell_pos.y*cell_size.y)
			container_node.add_child(new_scene_instance)
			new_scene_instance.set_owner(get_tree().edited_scene_root)
		else:
			printerr("Tile with id:"+str(tile_id)+" does not have any related scene in the tile to scene dictionary.")
			return
	if clean_after_spawning:
		clear()
	emit_signal("scenes_instanced")
	print("SpawnerTileMap: Scenes instanced successfully.")

# Deletes all child nodes from the container node
func clean_instanced_scenes():
	if container_node:
		for child in container_node.get_children():
			child.queue_free()
		emit_signal("instanced_scenes_cleaned")

# Set function for container_node_path.
func set_container_nodepath(new_nodepath:NodePath):
	container_node = get_node_or_null(new_nodepath)
	container_node_path = new_nodepath
