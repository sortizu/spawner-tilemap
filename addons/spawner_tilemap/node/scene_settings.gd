tool
extends Resource

## Stores custom value for each PackedScene inside a [tile_to_scene_dictionary]

# TILE DATA

var tile_id: int
var tile_mode: int
var tile: Texture setget set_tile
var subtile_coord: Vector2

# SCENE SETTINGS

var selected_scene: PackedScene
var metadata: Dictionary
var instance_mode: int = 3
var position_zero: bool
var use_base_autotile_settings: bool
var default_parameters: int
var path_to_target: String
var method_name: String
var clean_tile: bool
var call_once: bool

# INSTANCE DATA

const array_pool_size: int = 32
var pos_sub_index: int
var pos_chunk: int
var axis_sub_index: int
var axis_chunk: int
var subcoord_sub_index: int
var subcoord_chunk: int
var single_instance: Node
# Array of positions used when the flag "one_call_at_end" is activated for an scene
var cell_pos_pool: PoolVector2Array
var cell_axis_settings_pool: PoolVector3Array
var cell_subcoord_pool: PoolVector2Array

func _get_property_list():
	var properties: Array = []
	var flags: String
	# Shows the tile related to this settings
	properties.append({
		name="Tile Data",
		type=TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name="tile",
		type=TYPE_OBJECT,
		hint_string = "Texture",
		hint =  PROPERTY_HINT_RESOURCE_TYPE,
		usage = PROPERTY_USAGE_EDITOR,
	})
	properties.append({
		name="Scene Settings",
		type=TYPE_NIL,
		usage = PROPERTY_USAGE_CATEGORY
	})
	properties.append({
		name="selected_scene",
		type=TYPE_OBJECT,
		hint_string = "PackedScene",
		hint =  PROPERTY_HINT_RESOURCE_TYPE,
		usage = PROPERTY_USAGE_STORAGE,
	})
	properties.append({
		name="metadata",
		type=TYPE_DICTIONARY,
		usage = PROPERTY_USAGE_DEFAULT,
	})
	properties.append({
		name="clean_tile",
		type=TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT,
	})
	properties.append({
		name="use_base_autotile_settings",
		type=TYPE_BOOL,
		usage = PROPERTY_USAGE_NOEDITOR,
	})
	properties.append({
		name="instance_mode",
		type=TYPE_INT,
		usage = PROPERTY_USAGE_DEFAULT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Ignore,Single,Global Single,Multiple"
	})
	# Different parameters depending on tile mode
	if tile_mode == TileSet.ATLAS_TILE or tile_mode == TileSet.AUTO_TILE:
		flags = "Tile Position,Tile ID,Metadata,Subtile Coordinate,Axis Settings"
	else:
		flags = "Tile Position,Tile ID,Metadata,Axis Settings"
	properties.append({
		name="position_zero",
		type=TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT
	})
	properties.append({
		name="default_parameters",
		type=TYPE_INT,
		hint_string = flags,
		hint = PROPERTY_HINT_FLAGS,
		usage = PROPERTY_USAGE_DEFAULT,
	})
	properties.append({
		name="call_once",
		type=TYPE_BOOL,
		usage = PROPERTY_USAGE_DEFAULT
	})
	properties.append({
		name="path_to_target",
		type=TYPE_STRING,
		usage = PROPERTY_USAGE_DEFAULT
	})
	properties.append({
		name="method_name",
		type=TYPE_STRING,
		usage = PROPERTY_USAGE_DEFAULT
	})
	properties.append({
		name="subtile_coord",
		type=TYPE_VECTOR2,
		usage = PROPERTY_USAGE_NOEDITOR
	})
	properties.append({
		name="tile_mode",
		type=TYPE_INT,
		usage = PROPERTY_USAGE_NOEDITOR
	})
	properties.append({
		name="cell_pos_pool",
		type=TYPE_VECTOR2_ARRAY,
		usage = PROPERTY_USAGE_NO_INSTANCE_STATE
	})
	properties.append({
		name="single_instance",
		type=TYPE_OBJECT,
		usage = PROPERTY_USAGE_NO_INSTANCE_STATE
	})
	return properties

func set_tile(new_tile: Texture):
	if not tile:
		tile = new_tile

# METHODS FOR INSTANCING PROCESS

func add_cell_pos(_pos: Vector2):
	if pos_sub_index >= array_pool_size:
		pos_sub_index = 0
		pos_chunk += 1
		cell_pos_pool.resize(len(cell_pos_pool) + array_pool_size)
	elif cell_pos_pool.size() == 0:
		cell_pos_pool.resize(array_pool_size)
	cell_pos_pool.set(pos_chunk * array_pool_size + pos_sub_index, _pos)
	pos_sub_index += 1

func add_cell_axis_setting(_axis: Vector3):
	if axis_sub_index >= array_pool_size:
		axis_sub_index = 0
		axis_chunk += 1
		cell_axis_settings_pool.resize(len(cell_pos_pool) + array_pool_size)
	elif cell_axis_settings_pool.size() == 0:
		cell_axis_settings_pool.resize(array_pool_size)
	cell_axis_settings_pool.set(axis_chunk * array_pool_size + axis_sub_index, _axis)
	axis_sub_index += 1

func add_cell_subcoord(_coord: Vector2):
	if subcoord_sub_index >= array_pool_size:
		subcoord_sub_index = 0
		subcoord_chunk += 1
		cell_subcoord_pool.resize(len(cell_subcoord_pool) + array_pool_size)
	elif cell_subcoord_pool.size() == 0:
		cell_subcoord_pool.resize(array_pool_size)
	cell_subcoord_pool.set(axis_chunk * array_pool_size + subcoord_sub_index, _coord)
	subcoord_sub_index += 1

func trim():
	if pos_chunk < 1:
		cell_pos_pool.resize(pos_sub_index)
	elif pos_sub_index < array_pool_size:
		cell_pos_pool.resize(len(cell_pos_pool) - (array_pool_size - pos_sub_index))
	
	if axis_chunk < 1:
		cell_axis_settings_pool.resize(axis_sub_index)
	elif axis_sub_index < array_pool_size:
		cell_axis_settings_pool.resize(len(cell_axis_settings_pool) - (array_pool_size - axis_sub_index))
		
	if subcoord_chunk < 1:
		cell_subcoord_pool.resize(subcoord_sub_index)
	elif subcoord_sub_index < array_pool_size:
		cell_subcoord_pool.resize(len(cell_subcoord_pool) - (array_pool_size - subcoord_sub_index))
