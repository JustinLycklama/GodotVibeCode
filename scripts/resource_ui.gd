extends CanvasLayer

@onready var label: Label = $Panel/Label


func _ready() -> void:
	# Connect to MatchManager's signal
	MatchManager.resources_changed.connect(_on_resources_changed)
	# Initialize display
	_update_display(MatchManager.get_resources())


func _on_resources_changed(resources: Dictionary) -> void:
	_update_display(resources)


func _update_display(resources: Dictionary) -> void:
	var text := ""
	for symbol in resources.keys():
		text += "%s: %d\n" % [symbol, resources[symbol]]
	label.text = text.strip_edges()
