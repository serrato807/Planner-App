extends PanelContainer

@onready var _title_label      : Label         = $VBoxContainer/Header/TitleLabel
@onready var _status_badge     : Label         = $VBoxContainer/Header/StatusBadge
@onready var _task_count_label : Label         = $VBoxContainer/Header/TaskCountLabel
@onready var _expand_button    : Button        = $VBoxContainer/Header/ExpandButton
@onready var _expanded_content : VBoxContainer = $VBoxContainer/ExpandedContent
@onready var _description_label: Label         = $VBoxContainer/ExpandedContent/DescriptionLabel
@onready var _milestone_list   : VBoxContainer = $VBoxContainer/ExpandedContent/MilestoneList
@onready var _task_list        : VBoxContainer = $VBoxContainer/ExpandedContent/TaskList
@onready var _add_task_input   : LineEdit      = $VBoxContainer/ExpandedContent/AddTaskRow/AddTaskInput
@onready var _save_task_btn    : Button        = $VBoxContainer/ExpandedContent/AddTaskRow/SaveTask
@onready var _btn_a            : Button        = $VBoxContainer/ExpandedContent/AddTaskRow/PriorityA
@onready var _btn_b            : Button        = $VBoxContainer/ExpandedContent/AddTaskRow/PriorityB
@onready var _btn_c            : Button        = $VBoxContainer/ExpandedContent/AddTaskRow/PriorityC
@onready var _status_row       : HBoxContainer = $VBoxContainer/ExpandedContent/StatusRow

var project_id        : String = ""
var _selected_priority: String = "B"
var _expanded         : bool   = false
var _task_scene       : PackedScene

func _ready() -> void:
	# Card background — rounded with subtle shadow
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.BG_SURFACE
	sb.border_color = ThemeManager.BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(ThemeManager.RADIUS_MD)
	sb.shadow_color  = ThemeManager.SHADOW_COLOR
	sb.shadow_size   = ThemeManager.SHADOW_SIZE
	sb.shadow_offset = ThemeManager.SHADOW_OFFSET
	sb.content_margin_left   = 20.0
	sb.content_margin_right  = 20.0
	sb.content_margin_top    = 16.0
	sb.content_margin_bottom = 16.0
	add_theme_stylebox_override("panel", sb)

	_task_scene = load("res://scenes/components/TaskItem.tscn")

	# Expand button styling
	_expand_button.flat = true
	_expand_button.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)

	_expand_button.pressed.connect(_on_expand_toggled)
	_save_task_btn.pressed.connect(_on_save_task_pressed)
	_add_task_input.text_submitted.connect(func(_t: String) -> void: _on_save_task_pressed())
	_btn_a.pressed.connect(func() -> void: _select_priority("A"))
	_btn_b.pressed.connect(func() -> void: _select_priority("B"))
	_btn_c.pressed.connect(func() -> void: _select_priority("C"))

	# Wire status buttons
	for btn in _status_row.get_children():
		if btn is Button:
			var btn_text: String = btn.text
			btn.pressed.connect(func() -> void: _on_status_pressed(btn_text))
			btn.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
			btn.add_theme_font_size_override("font_size", 12)

	ThemeManager.style_button_accent(_save_task_btn)

	# Style section sub-headers
	var milestone_hdr: Label = $VBoxContainer/ExpandedContent/MilestoneHeader
	milestone_hdr.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	var tasks_hdr: Label = $VBoxContainer/ExpandedContent/TasksHeader
	tasks_hdr.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	var status_lbl: Label = $VBoxContainer/ExpandedContent/StatusLabel
	status_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)

	DataManager.data_changed.connect(_refresh_task_list)
	_select_priority("B")

func setup(project_data: Dictionary) -> void:
	project_id = project_data.get("id", "")

	_title_label.text = project_data.get("title", "Untitled")
	_title_label.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
	_title_label.add_theme_font_size_override("font_size", 15)

	_task_count_label.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	_task_count_label.add_theme_font_size_override("font_size", 12)

	_description_label.text = project_data.get("description", "")
	_description_label.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	_description_label.add_theme_font_size_override("font_size", 13)

	_refresh_status(project_data.get("status", "Active"))
	_refresh_milestones(project_data.get("milestones", []))
	_refresh_task_list()

func _refresh_status(status: String) -> void:
	_status_badge.text = "● " + status
	_status_badge.add_theme_font_size_override("font_size", 12)
	match status:
		"Active":
			_status_badge.add_theme_color_override("font_color", ThemeManager.PRIORITY_C)
		"Paused":
			_status_badge.add_theme_color_override("font_color", ThemeManager.PRIORITY_B)
		"Complete":
			_status_badge.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)

func _refresh_milestones(milestones: Array) -> void:
	for c in _milestone_list.get_children():
		c.queue_free()
	if milestones.is_empty():
		return
	for m in milestones:
		var lbl := Label.new()
		lbl.text = "◦ " + str(m)
		lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		lbl.add_theme_font_size_override("font_size", 13)
		_milestone_list.add_child(lbl)

func _refresh_task_list() -> void:
	if not is_node_ready():
		return
	var project_tasks := DataManager.get_tasks_for_project(project_id)
	_task_count_label.text = str(project_tasks.size()) + " tasks"

	for c in _task_list.get_children():
		c.queue_free()

	for t in project_tasks:
		var item: Node = _task_scene.instantiate()
		_task_list.add_child(item)
		item.setup(t)
		item.toggle_requested.connect(func(tid: String) -> void:
			DataManager.toggle_task_done(tid)
		)

func _on_expand_toggled() -> void:
	_expanded = not _expanded
	_expanded_content.visible = _expanded
	_expand_button.text = "▲" if _expanded else "▼"

func _select_priority(p: String) -> void:
	_selected_priority = p
	_btn_a.add_theme_color_override("font_color",
		ThemeManager.PRIORITY_A if p == "A" else ThemeManager.TEXT_MUTED)
	_btn_b.add_theme_color_override("font_color",
		ThemeManager.PRIORITY_B if p == "B" else ThemeManager.TEXT_MUTED)
	_btn_c.add_theme_color_override("font_color",
		ThemeManager.PRIORITY_C if p == "C" else ThemeManager.TEXT_MUTED)

func _on_save_task_pressed() -> void:
	var title := _add_task_input.text.strip_edges()
	if title.is_empty():
		return
	DataManager.add_task(title, _selected_priority, DataManager._today_str(), project_id)
	_add_task_input.clear()

func _on_status_pressed(new_status: String) -> void:
	DataManager.update_project(project_id, {"status": new_status})
	_refresh_status(new_status)
