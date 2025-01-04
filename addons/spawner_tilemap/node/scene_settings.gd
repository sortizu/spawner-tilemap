tool
extends Resource

var tile_mode: int
var tile: Texture setget set_tile
var subtile_coord: Vector2

## Stores custom value for each PackedScene inside a [tile_to_scene_dictionary]
var metadata: Dictionary
var instance_mode: int = 2
var default_parameters: int
var path_to_target: String
var method_name: String

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
		name="metadata",
		type=TYPE_DICTIONARY,
		usage = PROPERTY_USAGE_DEFAULT,
	})
	properties.append({
		name="instance_mode",
		type=TYPE_INT,
		usage = PROPERTY_USAGE_DEFAULT,
		hint = PROPERTY_HINT_ENUM,
		hint_string = "Ignore,Single,Multiple"
	})
	# Different parameters depending on tile mode
	if tile_mode == TileSet.ATLAS_TILE or tile_mode == TileSet.AUTO_TILE:
		flags = "Tile Position,Tile ID,Metadata,Subtile Coordinate"
	else:
		flags = "Tile Position,Tile ID,Metadata"
	properties.append({
		name="default_parameters",
		type=TYPE_INT,
		hint_string = flags,
		hint = PROPERTY_HINT_FLAGS,
		usage = PROPERTY_USAGE_DEFAULT,
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
	return properties

func set_tile(new_tile: Texture):
	if not tile:
		tile = new_tile
