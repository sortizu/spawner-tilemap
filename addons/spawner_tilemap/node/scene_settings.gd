tool
extends Resource

## Stores custom value for each PackedScene inside a [tile_to_scene_dictionary]
export var metadata: Dictionary

export (int, "Ignore","Single","Multiple") var instance_mode = 2
export (int, FLAGS, "Tile Position","Tile ID","Metadata") var default_parameters
export (String) var path_to_target
export (String) var method_name
