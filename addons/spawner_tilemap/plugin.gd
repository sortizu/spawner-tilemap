tool
extends EditorPlugin

var plugin

func _enter_tree() -> void:
	# Add custom type
	#var custom_type_script: Script = preload("res://addons/spawner_tilemap/node/spawner_tile_map.gd")
	#var spawner_tilemap_texture: Texture = get_editor_interface().get_base_control().get_icon("TileMap","EditorIcons")
	#add_custom_type("SpawnerTileMap","TileMap",custom_type_script,spawner_tilemap_texture)
	# Add EditorInspectorPlugin
	plugin = preload("res://addons/spawner_tilemap/editor_spawner_tilemap.gd").new()
	plugin.editor_interface = get_editor_interface()
	add_inspector_plugin(plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(plugin)
	#remove_custom_type("SpawnerTileMap")
	
