tool
extends EditorPlugin

var plugin

func _enter_tree() -> void:
	plugin = preload("res://addons/spawner_tilemap/editor_spawner_tilemap.gd").new()
	plugin.editor_interface = get_editor_interface()
	add_inspector_plugin(plugin)

func _exit_tree() -> void:
	remove_inspector_plugin(plugin)
	
