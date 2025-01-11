tool
extends TileMap
class_name SpawnerTileMap, "res://addons/spawner_tilemap/spawner_tile_map.svg"

## Instances selected scenes based on the cells showed in this TileMap
## To select the scenes to instanced, press the "edit scenes" button that appears in the inspector
## when this node is selected.

# CLASS VARIABLES

# Instance the scenes according to the tiles showed in the tilemap
# or disable the instancing function (it will work as usual tilemap)
export (bool) var spawn_scenes_at_start
# Clean all the cells from the tilemap after instancing the scenes, it doesn't consider specific scene settings for each tile
export (bool) var clean_after_spawning
# Path of the node to store all the scenes instances setted on tile_to_scene_dictionary
export (NodePath) var container_node_path: NodePath setget set_container_nodepath
onready var container_node = get_node_or_null(container_node_path)
# Shows an error in the console when trying to instantiate an unassigned tile
var print_errors: bool = true
# TileToSceneDictionary resource instance
# This variable is created automatically and modified by the TileToSceneEditor
# It stores each tile id as a key and a PackedScene as the value for each id.
# ADVICE: Set this variable manually if you are already using a similar dictionary format for your project.
const TileToSceneDictionary: GDScript = preload("res://addons/spawner_tilemap/node/tile_to_scene_dictionary.gd")
var tile_to_scene_dictionary: TileToSceneDictionary setget set_tile_to_scene_dict
const scene_settings: GDScript = preload("res://addons/spawner_tilemap/node/scene_settings.gd")

var _tile_count: int = 0

# SIGNALS

signal scenes_instanced
signal instanced_scenes_cleaned

# METHODS

func _ready() -> void:
	if not tile_to_scene_dictionary:
		var new_tile_to_scene_dict = TileToSceneDictionary.new()
		# warning-ignore:unsafe_property_access
		new_tile_to_scene_dict.loaded_dictionary=true
		set_tile_to_scene_dict(new_tile_to_scene_dict)
	if not Engine.editor_hint:
		if spawn_scenes_at_start:
			instance_scenes_from_dictionary()
	else:
		connect("settings_changed",self,"_on_settings_changed")
	if tile_set:
		_tile_count = tile_set.get_tiles_ids().size()

## Disconnects the remaining signals
func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if not is_connected("settings_changed",self,"_on_settings_changed"):
			return
		disconnect("settings_changed",self,"_on_settings_changed")

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
	properties.append({
		usage = PROPERTY_USAGE_DEFAULT,
		name="print_errors",
		type=TYPE_BOOL
	})
	return properties

## Set function for custom resource that contains the dictionary of tiles and scenes
func set_tile_to_scene_dict(new_dict: TileToSceneDictionary):
	if not (not new_dict or new_dict.get_class() == "TileToSceneDictionary"):
		printerr("[SpawnerTileMap] Resource set in tile_to_scene_dictionary is not a TileToSceneDictionary type.")
	else:
		tile_to_scene_dictionary = new_dict

## Instances scenes in the container node according to the visible tiles in this tilemap.
func instance_scenes_from_dictionary() -> Array:
	if not container_node:
		printerr("[SpawnerTileMap] There isn't any container node selected to instance the scenes.")
		return []
#	var start: int = Time.get_ticks_usec()
	var _tile_id: int = -1
	var new_scene_instance: Node
	var _scene_data: Array
	var _packed_scene: PackedScene
	var _scene_settings: scene_settings
	var _instanced_scenes: Array
	var _target: Node
	var _params: Dictionary
	for _cell_pos in get_used_cells():
		_cell_pos = _cell_pos as Vector2
		_tile_id = get_cell(_cell_pos.x,_cell_pos.y)
		if tile_set.tile_get_tile_mode(_tile_id) == TileSet.SINGLE_TILE:
			_scene_data = tile_to_scene_dictionary.get_scene_by_tile_id(str(_tile_id))
		else:
			var subtile_coord: Vector2 = get_cell_autotile_coord(_cell_pos.x,_cell_pos.y)
			_scene_data = tile_to_scene_dictionary.get_scene_by_tile_id(str(_tile_id)+"-"+str(subtile_coord.x)+"-"+str(subtile_coord.y))
		if not _scene_data.empty():
			_packed_scene = _scene_data[0]
			_scene_settings = _scene_data[1]
		else:
			_packed_scene = null
			_scene_settings = null
		if _scene_settings and _scene_settings.instance_mode == 0:
			continue
		if _packed_scene:
			new_scene_instance = null
			if _scene_settings and _scene_settings.instance_mode == 1 and _packed_scene.has_meta("SingleInstance"):
				new_scene_instance = _packed_scene.get_meta("SingleInstance")
			if not (new_scene_instance and is_instance_valid(new_scene_instance)):
				new_scene_instance = _scene_data[0].instance()
				if new_scene_instance is Node2D:
					new_scene_instance.position = Vector2(_cell_pos.x*cell_size.x,_cell_pos.y*cell_size.y)
				elif new_scene_instance is Control:
					new_scene_instance.rect_position = Vector2(_cell_pos.x*cell_size.x,_cell_pos.y*cell_size.y)
				container_node.add_child(new_scene_instance)
				new_scene_instance.set_owner(get_tree().edited_scene_root)
				# Add the Spawner instance id to identify which nodes will be freed when the "clean" button is pressed
				new_scene_instance.set_meta(get_class(),get_instance_id())
				_instanced_scenes.append(new_scene_instance)
			if _scene_settings:
				if _scene_settings.instance_mode == 1:
					_packed_scene.set_meta("SingleInstance",new_scene_instance)
				if _scene_settings.clean_tile:
					set_cellv(_cell_pos,-1)
			# Calling method after spawn
			if not _scene_settings: continue
			if _scene_settings.method_name.empty(): continue
			if _scene_settings.path_to_target.empty(): _target = new_scene_instance
			else: _target = new_scene_instance.get_node_or_null(_scene_settings.path_to_target)
			if not _target:
				printerr("[SpawnerTileMap] Can't find target node '%s' (tile-id %s)"%[_scene_settings.path_to_target,_tile_id])
				continue
			if not _target.has_method(_scene_settings.method_name): 
				printerr("[SpawnerTileMap] Can't find method with name '%s' in target node (tile-id %s)"%[_scene_settings.method_name,_tile_id])
				continue
			if _scene_settings.default_parameters & 001: # If Tile Position is set true as parameter
				_params["tile_position"] = _cell_pos
			if _scene_settings.default_parameters & 010: # If Tile ID is set true as parameter
				_params["tile_id"] = _tile_id
			if _scene_settings.default_parameters & 1000: # If metadata is set true as parameter
				_params["subtile_coordinates"] = _scene_settings.subtile_coord
			if _scene_settings.default_parameters & 100: # If metadata is set true as parameter
				_params["metadata"] = _scene_settings.metadata
			_target.call(_scene_settings.method_name,_params)
		else:
			if print_errors: printerr("Tile with id:"+str(_tile_id)+" does not have any related scene in the tile to scene dictionary.")
			continue
	if clean_after_spawning:
		clear()
	emit_signal("scenes_instanced")
#	print("[SpawnerTileMap] Scenes instanced successfully.")
#	print("Time: %s"%[(Time.get_ticks_usec()-start)/1000000.0])
	return _instanced_scenes

## Adds the scenes instanced by [instance_scenes_from_dictionary] as children of the [container_node]
func _add_instanced_scenes(nodes: Array):
	for node in nodes:
		if not is_instance_valid(node):
			continue
		if node.is_inside_tree():
			return
		node = node as Node
		container_node.add_child(node)
		node.set_owner(get_tree().edited_scene_root)

## Returns this TileMap state as a dictionary of all the used cells.
## This state can be used by [_restore_state] to restore all the cells
func _get_state() -> Dictionary:
	var _state: Dictionary
	var _id: int = -1
	for _pos in get_used_cells():
		_id = get_cellv(_pos)
		var _tile_data: Array = _state.get(_id,[])
		if _tile_data.empty():
			_state[_id] = _tile_data
		_tile_data.append([_pos,is_cell_x_flipped(_pos.x,_pos.y),is_cell_y_flipped(_pos.x,_pos.y),is_cell_transposed(_pos.x,_pos.y),get_cell_autotile_coord(_pos.x,_pos.y)])
	return _state

## Restores all the cells saved in a previous state which is contained in the [_tile_dict]
## and can be obtained using [_get_state]
func _restore_state(_state: Dictionary):
	var _tile_data_array: Array
	for _id in _state:
		if not _state.has(_id):
			continue
		_tile_data_array = _state[_id]
		for _tile_data in _tile_data_array:
			set_cellv(_tile_data[0], _id, _tile_data[1], _tile_data[2], _tile_data[3],_tile_data[4])

## Deletes all scenes in [_instances] array
## When [free_instances] is false, the scenes will only be removed from the tree, but not freed from memory
func clean_instanced_scenes(_instances: Array, free_instances: bool = true):
	if container_node:
		for node in _instances:
			if not is_instance_valid(node):
				continue
			if node.get_meta("SpawnerTileMap",-1) != get_instance_id():
				continue
			if free_instances:
				node.queue_free()
			else:
				container_node.remove_child(node)
		emit_signal("instanced_scenes_cleaned")

## Set function for container_node_path.
func set_container_nodepath(new_nodepath:NodePath):
	container_node = get_node_or_null(new_nodepath)
	container_node_path = new_nodepath

## Checks if the [container_node] has any scene instanced by this SpawnerTileMap
func _has_container_instances() -> bool:
	if container_node:
		var _id: int = get_instance_id()
		for node in container_node.get_children():
			if node.get_meta("SpawnerTileMap",-1) != _id:
				continue
			return true
	return false

## Returns an array of all the children nodes inside the [container_node] instanced by this SpawnerTileMap
func _get_instances_in_container_node() -> Array:
	var _instances: Array
	if container_node:
		var _id: int = get_instance_id()
		for node in container_node.get_children():
			if node.get_meta("SpawnerTileMap",-1) != _id:
				continue
			_instances.append(node)
	return _instances

func get_class() -> String:
	return "SpawnerTileMap"

## Updates the [tile_to_scene_dictionary] when tiles are removed
func _on_settings_changed():
	if not (tile_to_scene_dictionary and tile_set):
		return
	var _tile_ids: Array = tile_set.get_tiles_ids()
	if not _tile_ids.size() < _tile_count:
		return
	var _dict_temp: Dictionary = tile_to_scene_dictionary.dictionary.duplicate()
	for key in tile_to_scene_dictionary.dictionary.keys():
		if key in _tile_ids:
			continue
		_dict_temp.erase(key)
	tile_to_scene_dictionary.dictionary = _dict_temp
