tool
extends TileMap
class_name SpawnerTileMap, "res://addons/spawner_tilemap/spawner_tile_map.svg"

## Instances selected scenes based on the cells showed in this TileMap
## To select the scenes to be instanced, press the "edit scenes" button that appears in the inspector
## when this node is selected.

# CLASS VARIABLES

# Instance the scenes according to the tiles showed in the tilemap
# or disable the instancing function (it will work as usual tilemap)
export (int, "On ready", "Deferred", "Threaded","Disabled") var instance_mode = 1
# Clean all the cells from the tilemap after instancing the scenes, it doesn't consider specific scene settings for each tile
export (bool) var clean_tiles
# Path of the node to store all the scenes instances setted on tile_to_scene_dictionary
export (NodePath) var instance_container: NodePath setget set_container_nodepath
onready var container_node = get_node_or_null(instance_container)
# Shows an error in the console when trying to instantiate an unassigned tile
var print_errors: bool = true
var show_time: bool = false
var signal_per_instance: bool
# TileToSceneDictionary resource instance
# This variable is created automatically and modified by the TileToSceneEditor
# It stores each tile id as a key and a PackedScene as the value for each id.
# ADVICE: Set this variable manually if you are already using a similar dictionary format for your project.
const TileToSceneDictionary: GDScript = preload("res://addons/spawner_tilemap/node/tile_to_scene_dictionary.gd")
var tile_to_scene_dictionary: TileToSceneDictionary setget set_tile_to_scene_dict
const SceneSettings: GDScript = preload("res://addons/spawner_tilemap/node/scene_settings.gd")

var _tile_count: int = 0
var thread: Thread = Thread.new()
var instancing: bool = false
var single_global_instances: Dictionary

# SIGNALS

signal intancing_finished
signal scene_instanced(scene,tile_id,spawner_node)
signal instanced_scenes_cleaned

# METHODS

func _ready() -> void:
	if not tile_to_scene_dictionary:
		var new_tile_to_scene_dict = TileToSceneDictionary.new()
		# warning-ignore:unsafe_property_access
		new_tile_to_scene_dict.loaded_dictionary=true
		set_tile_to_scene_dict(new_tile_to_scene_dict)
	else:
		pass
			
	if not Engine.editor_hint:
		match instance_mode:
			0:
				instance_scenes()
			1:
				instance_in_idle_time()
			2:
				threaded_instance()
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
	properties.append({
		usage = PROPERTY_USAGE_DEFAULT,
		name="show_time",
		type=TYPE_BOOL
	})
	properties.append({
		usage = PROPERTY_USAGE_DEFAULT,
		name="signal_per_instance",
		type=TYPE_BOOL
	})
	return properties

## Set function for custom resource that contains the dictionary of tiles and scenes
func set_tile_to_scene_dict(new_dict: TileToSceneDictionary):
	if not (not new_dict or new_dict.get_class() == "TileToSceneDictionary"):
		printerr("[SpawnerTileMap] Resource set in tile_to_scene_dictionary is not a TileToSceneDictionary type.")
	else:
		tile_to_scene_dictionary = new_dict

func threaded_instance():
	if not thread.is_alive():
		thread.start(self,"instance_scenes")

func instance_in_idle_time():
	call_deferred("instance_scenes")

func _exit_tree():
	if instancing: instancing = false
	elif thread.is_active(): thread.wait_to_finish()

## Instances scenes in the instance_container node according to the visible tiles in this tilemap.
func instance_scenes() -> Array:
	if not container_node:
		printerr("[SpawnerTileMap/%s] There isn't any instance_container node selected to instance the scenes."%[name])
		return []
	var start: int = Time.get_ticks_usec()
	var _tile_id: int = -1
	var _tile_id_str: String
	var new_scene_instance: Node
	var _scene_data: Array
	var _scene_settings: SceneSettings
	var _instances_scene_settings: Array
	var _instanced_scenes: Array
	var _target: Node
	var _params: Dictionary
	var _call_once_params: Dictionary
	var _temp_call_once_params: Array
	var _subtile_coord: Vector2
	var _single_instance: bool
	instancing = true
	for _cell_pos in get_used_cells():
		if not instancing:
			return []
		_cell_pos = _cell_pos as Vector2
		_tile_id = get_cell(_cell_pos.x,_cell_pos.y)
		if tile_set.tile_get_tile_mode(_tile_id) == TileSet.SINGLE_TILE:
			_tile_id_str = str(_tile_id)
			_scene_settings = tile_to_scene_dictionary.get_scene_settings_by_tile_id(_tile_id_str)
		else:
			_subtile_coord = get_cell_autotile_coord(_cell_pos.x,_cell_pos.y)
			_tile_id_str = str(_tile_id)+"-"+str(_subtile_coord.x)+"-"+str(_subtile_coord.y)
			_scene_settings = tile_to_scene_dictionary.get_scene_settings_by_tile_id(_tile_id_str)
			# If the tile has use_base_autotile_settings enabled, it will use the base tile (autotile/atlas) scene settings (scene, instance, call settings)
			if _scene_settings and _scene_settings.use_base_autotile_settings:
				_scene_settings = tile_to_scene_dictionary.get_scene_settings_by_tile_id(str(_tile_id))
		if _scene_settings and _scene_settings.instance_mode == 0:
			continue
		if _scene_settings and _scene_settings.selected_scene:
			_single_instance = false
			new_scene_instance = null
			if _scene_settings:
				if _scene_settings.clean_tile:
					set_cellv(_cell_pos,-1)
				if _scene_settings.instance_mode == 1:
					new_scene_instance = _scene_settings.single_instance
				if _scene_settings.instance_mode == 2:
					new_scene_instance = single_global_instances.get(_scene_settings.selected_scene)
					if new_scene_instance and not _scene_settings.single_instance: _instances_scene_settings.append(_scene_settings)
				if new_scene_instance:
					_scene_settings.single_instance = new_scene_instance
					if _scene_settings.call_once:
						if _scene_settings.default_parameters & 1:
							_scene_settings.add_cell_pos(_cell_pos)
						if tile_set.tile_get_tile_mode(_tile_id) != TileSet.SINGLE_TILE and _scene_settings.default_parameters & 1000:
							_scene_settings.add_cell_subcoord(_subtile_coord)
						if (tile_set.tile_get_tile_mode(_tile_id) == TileSet.SINGLE_TILE and _scene_settings.default_parameters & 1000) or \
							(tile_set.tile_get_tile_mode(_tile_id) != TileSet.SINGLE_TILE and _scene_settings.default_parameters & 10000):
								_scene_settings.add_cell_axis_setting(Vector3(is_cell_x_flipped(_cell_pos.x,_cell_pos.y),is_cell_y_flipped(_cell_pos.x,_cell_pos.y),is_cell_transposed(_cell_pos.x,_cell_pos.y)))
						continue
			if not (new_scene_instance and is_instance_valid(new_scene_instance)):
				new_scene_instance = _scene_settings.selected_scene.instance()
				if not _scene_settings or not _scene_settings.position_zero:
					if new_scene_instance is Node2D:
						new_scene_instance.position = Vector2(_cell_pos.x*cell_size.x,_cell_pos.y*cell_size.y)
					elif new_scene_instance is Control:
						new_scene_instance.rect_position = Vector2(_cell_pos.x*cell_size.x,_cell_pos.y*cell_size.y)
				if instance_mode == 2: # Threaded instances nodes in idle time
					container_node.call_deferred("add_child",new_scene_instance)
					new_scene_instance.call_deferred("set_owner",get_tree().edited_scene_root)
					if signal_per_instance:
						call_deferred("emit_signal","scene_instanced",new_scene_instance,_tile_id_str,self)
				else:
					container_node.add_child(new_scene_instance)
					new_scene_instance.set_owner(get_tree().edited_scene_root)
					if signal_per_instance:
						emit_signal("scene_instanced",new_scene_instance,_tile_id_str,self)
				# Add the Spawner instance id to identify which nodes will be freed when the "clean" button is pressed
				new_scene_instance.set_meta(get_class(),get_instance_id())
				_instanced_scenes.append(new_scene_instance)
				if _scene_settings:
					if _scene_settings.instance_mode == 1:
						_scene_settings.single_instance = new_scene_instance
						_single_instance = true
					if _scene_settings.instance_mode == 2:
						single_global_instances[_scene_settings.selected_scene] = new_scene_instance
						_scene_settings.single_instance = new_scene_instance
						_single_instance = true
					if _single_instance and _scene_settings.call_once:
						_instances_scene_settings.append(_scene_settings)
						if _scene_settings.default_parameters & 1:
							_scene_settings.add_cell_pos(_cell_pos)
						if tile_set.tile_get_tile_mode(_tile_id) != TileSet.SINGLE_TILE and _scene_settings.default_parameters & 1000:
							_scene_settings.add_cell_subcoord(_subtile_coord)
						if (tile_set.tile_get_tile_mode(_tile_id) == TileSet.SINGLE_TILE and _scene_settings.default_parameters & 1000) or \
							(tile_set.tile_get_tile_mode(_tile_id) != TileSet.SINGLE_TILE and _scene_settings.default_parameters & 10000):
								_scene_settings.add_cell_axis_setting(Vector3(is_cell_x_flipped(_cell_pos.x,_cell_pos.y),is_cell_y_flipped(_cell_pos.x,_cell_pos.y),is_cell_transposed(_cell_pos.x,_cell_pos.y)))
						continue
			# TODO: Add a path_to_target verification to avoid calling a new method
			# Calling method after instancing
			if instance_mode == 2: # Calling target nodes on idle time if threaded instancing is active
				call_deferred("call_to_target", new_scene_instance, _tile_id, _cell_pos, _scene_settings)
			else:
				call_to_target(new_scene_instance, _tile_id, _cell_pos, Vector3(is_cell_x_flipped(_cell_pos.x,_cell_pos.y),is_cell_y_flipped(_cell_pos.x,_cell_pos.y),is_cell_transposed(_cell_pos.x,_cell_pos.y)), _scene_settings)
		else:
			if print_errors: printerr("[SpawnerTileMap/%s] Tile with id:"%[name]+str(_tile_id)+" does not have any related scene in the tile to scene dictionary.")
			continue
	for _settings in _instances_scene_settings:
		if instance_mode == 2: call_deferred("call_to_target_at_end",_settings)
		else: call_to_target_at_end(_settings)
	if clean_tiles:
		clear()
	if instance_mode == 2:
		call_deferred("print","[SpawnerTileMap/%s] Scenes instanced successfully."%name)
		call_deferred("emit_signal","intancing_finished")
		if show_time: call_deferred("print","[SpawnerTileMap/%s] Time: %s"%[name,(Time.get_ticks_usec()-start)/1000000.0])
	else:
		emit_signal("intancing_finished")
		print("[SpawnerTileMap/%s] Scenes instanced successfully."%name)
		if show_time: print("[SpawnerTileMap/%s] Time: %s"%[name,(Time.get_ticks_usec()-start)/1000000.0])
	instancing = false
	return _instanced_scenes

func call_to_target(_target: Node, _tile_id: int, _cell_pos: Vector2, _axis_settings: Vector3, _scene_settings: SceneSettings):
	if not _scene_settings: return
	if _scene_settings.method_name.empty(): return
	var params: Array = []
	if _target and not _scene_settings.path_to_target.empty(): _target = _target.get_node_or_null(_scene_settings.path_to_target)
	if not _target:
		printerr("[SpawnerTileMap/%s/call_to_target] Can't find target node '%s' (tile-id %s)"%[name,_scene_settings.path_to_target,_tile_id])
		return
	if not _target.has_method(_scene_settings.method_name): 
		printerr("[SpawnerTileMap/%s/call_to_target] Can't find method with name '%s' in target node (tile-id %s)"%[name,_scene_settings.method_name,_tile_id])
		return
	if _scene_settings.default_parameters & 0001:
		params.append(_cell_pos)
	if _scene_settings.default_parameters & 0010:
		params.append(_tile_id)
	if _scene_settings.default_parameters & 0100:
		params.append(_scene_settings.metadata)
	if tile_set.tile_get_tile_mode(_tile_id) != TileSet.SINGLE_TILE:
		if _scene_settings.default_parameters & 1000:
			params.append(_scene_settings.subtile_coord)
		if _scene_settings.default_parameters & 10000:
			params.append(_axis_settings)
	else:
		if _scene_settings.default_parameters & 1000:
			params.append(_axis_settings)
	_target.callv(_scene_settings.method_name, params)


func call_to_target_at_end(_scene_settings: SceneSettings):
	if _scene_settings.method_name.empty(): return
	var params: Array = []
	var _target: Node
	if _scene_settings.path_to_target.empty(): _target = _scene_settings.single_instance
	else: _target = _scene_settings.single_instance.get_node_or_null(_scene_settings.path_to_target)
	if not _target:
		printerr("[SpawnerTileMap/%s/call_to_target_at_end] Can't find target node '%s' (tile-id %s)"%[name,_scene_settings.path_to_target,_scene_settings.tile_id])
		return
	if not _target.has_method(_scene_settings.method_name): 
		printerr("[SpawnerTileMap/%s/call_to_target_at_end] Can't find method with name '%s' in target node (tile-id %s)"%[name,_scene_settings.method_name,_scene_settings.tile_id])
		return
	_scene_settings.trim()
	if _scene_settings.default_parameters & 0001:
		params.append(_scene_settings.cell_pos_pool)
	if _scene_settings.default_parameters & 0010:
		params.append(_scene_settings.tile_id)
	if _scene_settings.default_parameters & 0100:
		params.append(_scene_settings.metadata)
	print(_scene_settings.tile_id)
	if tile_set.tile_get_tile_mode(_scene_settings.tile_id) != TileSet.SINGLE_TILE:
		if _scene_settings.default_parameters & 1000:
			params.append(_scene_settings.cell_subcoord_pool)
		if _scene_settings.default_parameters & 10000:
			params.append(_scene_settings.cell_axis_settings_pool)
		
	else:
		if _scene_settings.default_parameters & 1000:
			params.append(_scene_settings.cell_axis_settings_pool)
	_target.callv(_scene_settings.method_name, params)

## Adds the scenes instanced by [instance_scenes] as children of the [container_node]
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

## Set function for instance_container.
func set_container_nodepath(new_nodepath:NodePath):
	container_node = get_node_or_null(new_nodepath)
	instance_container = new_nodepath

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

