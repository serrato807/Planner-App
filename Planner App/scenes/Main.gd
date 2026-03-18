extends Control

@onready var _sidebar      : PanelContainer = $Layout/Sidebar
@onready var _content_area : PanelContainer = $Layout/ContentArea
@onready var _app_title    : Label          = $Layout/Sidebar/NavButtons/TitleArea/AppTitle
@onready var _btn_today    : Button         = $Layout/Sidebar/NavButtons/BtnToday
@onready var _btn_week     : Button         = $Layout/Sidebar/NavButtons/BtnWeek
@onready var _btn_monthly  : Button         = $Layout/Sidebar/NavButtons/BtnMonthly
@onready var _btn_projects : Button         = $Layout/Sidebar/NavButtons/BtnProjects
@onready var _btn_master   : Button         = $Layout/Sidebar/NavButtons/BtnMasterList

const SCENE_TODAY      := "res://scenes/views/Today.tscn"
const SCENE_WEEKLY     := "res://scenes/views/Weekly.tscn"
const SCENE_MONTHLY    := "res://scenes/views/Monthly.tscn"
const SCENE_PROJECTS   := "res://scenes/views/Projects.tscn"
const SCENE_MASTERLIST := "res://scenes/views/MasterList.tscn"

var _nav_buttons  : Array = []
var _current_view : Node  = null

func _ready() -> void:
	# ── Sidebar: BG_SIDEBAR with right border only ───────────────────────────
	var sidebar_sb := StyleBoxFlat.new()
	sidebar_sb.bg_color          = ThemeManager.BG_SIDEBAR
	sidebar_sb.border_color      = ThemeManager.BORDER
	sidebar_sb.border_width_left   = 0
	sidebar_sb.border_width_right  = 1
	sidebar_sb.border_width_top    = 0
	sidebar_sb.border_width_bottom = 0
	sidebar_sb.content_margin_left   = 0.0
	sidebar_sb.content_margin_right  = 0.0
	sidebar_sb.content_margin_top    = 20.0
	sidebar_sb.content_margin_bottom = 12.0
	_sidebar.add_theme_stylebox_override("panel", sidebar_sb)

	# ── App title ─────────────────────────────────────────────────────────────
	_app_title.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
	_app_title.add_theme_font_size_override("font_size", 15)

	# Apply left padding to title label manually
	var title_margin := $Layout/Sidebar/NavButtons/TitleArea as HBoxContainer
	title_margin.add_theme_constant_override("margin_left", 16)

	# ── Content area: plain BG_PRIMARY, no border ────────────────────────────
	var ca_sb := StyleBoxFlat.new()
	ca_sb.bg_color = ThemeManager.BG_PRIMARY
	ca_sb.set_border_width_all(0)
	ca_sb.set_content_margin_all(0)
	_content_area.add_theme_stylebox_override("panel", ca_sb)

	_nav_buttons = [_btn_today, _btn_week, _btn_monthly, _btn_projects, _btn_master]

	_btn_today.pressed.connect(func() -> void:
		_navigate(SCENE_TODAY, _btn_today))
	_btn_week.pressed.connect(func() -> void:
		_navigate(SCENE_WEEKLY, _btn_week))
	_btn_monthly.pressed.connect(func() -> void:
		_navigate(SCENE_MONTHLY, _btn_monthly))
	_btn_projects.pressed.connect(func() -> void:
		_navigate(SCENE_PROJECTS, _btn_projects))
	_btn_master.pressed.connect(func() -> void:
		_navigate(SCENE_MASTERLIST, _btn_master))

	_navigate(SCENE_TODAY, _btn_today)

func _navigate(scene_path: String, active_button: Button) -> void:
	for btn in _nav_buttons:
		if btn.has_method("_apply_style"):
			btn.is_active = (btn == active_button)

	if _current_view != null:
		_current_view.queue_free()
		_current_view = null

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Main: Failed to load scene: " + scene_path)
		return

	_current_view = packed.instantiate()
	_current_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_current_view.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	_content_area.add_child(_current_view)
