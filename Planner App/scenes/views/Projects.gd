extends ScrollContainer

@onready var _card_list: VBoxContainer = $CardList

var _card_scene: PackedScene

func _ready() -> void:
	_card_scene = load("res://scenes/components/ProjectCard.tscn")
	DataManager.data_changed.connect(_refresh_projects)
	_refresh_projects()

func _refresh_projects() -> void:
	if not is_node_ready():
		return
	for c in _card_list.get_children():
		c.queue_free()
	for p in DataManager.projects:
		var card: Node = _card_scene.instantiate()
		_card_list.add_child(card)
		card.setup(p)
