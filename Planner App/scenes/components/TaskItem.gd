extends PanelContainer

signal toggle_requested(task_id: String)

@onready var _checkbox      : CheckBox = $HBoxContainer/CheckBox
@onready var _title_label   : Label    = $HBoxContainer/TitleLabel
@onready var _priority_badge: Label    = $HBoxContainer/PriorityBadge

var task_id   : String = ""
var task_title: String = ""
var priority  : String = "A"
var done      : bool   = false

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_panel_style(false)
	_checkbox.toggled.connect(_on_checkbox_toggled)
	_title_label.add_theme_font_size_override("font_size", 14)
	_priority_badge.add_theme_font_size_override("font_size", 11)
	_refresh_display()

func setup(data: Dictionary) -> void:
	task_id    = data.get("id", "")
	task_title = data.get("title", "Untitled")
	priority   = data.get("priority", "A")
	done       = data.get("done", false)
	_refresh_display()

func _refresh_display() -> void:
	if not is_node_ready():
		return
	_title_label.text    = task_title
	_priority_badge.text = priority
	_checkbox.button_pressed = done

	if done:
		_apply_panel_style(true)
		_title_label.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		_priority_badge.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	else:
		_apply_panel_style(false)
		_title_label.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
		_priority_badge.add_theme_color_override("font_color", ThemeManager.priority_color(priority))

func _apply_panel_style(is_done: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = ThemeManager.BG_PRIMARY if is_done else ThemeManager.BG_SURFACE
	sb.border_color = ThemeManager.BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(ThemeManager.RADIUS_SM)
	if not is_done:
		sb.shadow_color  = ThemeManager.SHADOW_COLOR
		sb.shadow_size   = 4
		sb.shadow_offset = ThemeManager.SHADOW_OFFSET
	sb.content_margin_left   = 16.0
	sb.content_margin_right  = 16.0
	sb.content_margin_top    = 10.0
	sb.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", sb)

func _on_checkbox_toggled(_pressed: bool) -> void:
	toggle_requested.emit(task_id)
