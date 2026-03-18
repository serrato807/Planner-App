extends HBoxContainer

# ─── Nav ───────────────────────────────────────────────────────────────────────
@onready var _month_label    : Label        = $CalendarSection/MonthNavBar/MonthLabel
@onready var _prev_btn       : Button       = $CalendarSection/MonthNavBar/PrevMonthBtn
@onready var _next_btn       : Button       = $CalendarSection/MonthNavBar/NextMonthBtn
@onready var _this_month_btn : Button       = $CalendarSection/MonthNavBar/ThisMonthBtn
@onready var _day_headers    : HBoxContainer = $CalendarSection/DayHeaders
@onready var _cal_grid       : GridContainer = $CalendarSection/CalGrid

# ─── Key Tasks Panel ───────────────────────────────────────────────────────────
@onready var _tasks_section_hdr : Label        = $TasksSection/TasksSectionHeader
@onready var _task_rows         : VBoxContainer = $TasksSection/TasksScroll/TaskRows
@onready var _col_date_hdr      : Label         = $TasksSection/TasksColHeader/TaskColDate
@onready var _col_status_hdr    : Label         = $TasksSection/TasksColHeader/TaskColStatus
@onready var _col_abc_hdr       : Label         = $TasksSection/TasksColHeader/TaskColABC
@onready var _col_title_hdr     : Label         = $TasksSection/TasksColHeader/TaskColTitle

# ─── State ─────────────────────────────────────────────────────────────────────
var _display_year  : int = 0
var _display_month : int = 0

const DAY_NAMES := ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
const MONTH_NAMES := ["January","February","March","April","May","June",
                      "July","August","September","October","November","December"]

# ─── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	var today := Time.get_datetime_dict_from_system()
	_display_year  = int(today.year)
	_display_month = int(today.month)

	_style_headers()

	_prev_btn.pressed.connect(func() -> void: _shift_month(-1))
	_next_btn.pressed.connect(func() -> void: _shift_month(1))
	_this_month_btn.pressed.connect(func() -> void:
		var t := Time.get_datetime_dict_from_system()
		_display_year  = int(t.year)
		_display_month = int(t.month)
		_rebuild()
	)

	_apply_panel_styles()
	_build_day_headers()
	_rebuild()

	DataManager.data_changed.connect(_refresh_key_tasks)

func _style_headers() -> void:
	_month_label.add_theme_font_size_override("font_size", 18)
	_month_label.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)

	for btn in [_prev_btn, _next_btn, _this_month_btn]:
		btn.add_theme_color_override("font_color", ThemeManager.ACCENT)
		btn.add_theme_font_size_override("font_size", 14)

	_tasks_section_hdr.add_theme_font_size_override("font_size", 13)
	_tasks_section_hdr.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	_tasks_section_hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var header_color := ThemeManager.TEXT_MUTED
	for lbl in [_col_date_hdr, _col_status_hdr, _col_abc_hdr, _col_title_hdr]:
		lbl.add_theme_color_override("font_color", header_color)
		lbl.add_theme_font_size_override("font_size", 11)

func _apply_panel_styles() -> void:
	# Tasks section
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.BG_SURFACE
	sb.set_border_width_all(0)
	sb.content_margin_left   = 16.0
	sb.content_margin_right  = 16.0
	sb.content_margin_top    = 0.0
	sb.content_margin_bottom = 0.0

func _build_day_headers() -> void:
	for c in _day_headers.get_children():
		c.queue_free()
	for name in DAY_NAMES:
		var lbl := Label.new()
		lbl.text = name
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		_day_headers.add_child(lbl)

# ─── Month Navigation ──────────────────────────────────────────────────────────
func _shift_month(delta: int) -> void:
	_display_month += delta
	if _display_month > 12:
		_display_month = 1
		_display_year += 1
	elif _display_month < 1:
		_display_month = 12
		_display_year -= 1
	_rebuild()

# ─── Calendar Grid ─────────────────────────────────────────────────────────────
func _rebuild() -> void:
	_month_label.text = "%s %d" % [MONTH_NAMES[_display_month - 1], _display_year]

	for c in _cal_grid.get_children():
		c.queue_free()

	var today_str := _get_today_str()
	var days_in_month := _days_in_month(_display_year, _display_month)

	# Find weekday of the 1st (Monday=0 … Sunday=6)
	var first_str := "%04d-%02d-01" % [_display_year, _display_month]
	var first_unix := Time.get_unix_time_from_datetime_dict({
		"year": _display_year, "month": _display_month, "day": 1,
		"hour": 12, "minute": 0, "second": 0
	})
	var first_info    := Time.get_datetime_dict_from_unix_time(first_unix)
	var first_weekday := int(first_info.weekday)  # 0=Sun … 6=Sat
	var first_col     := (first_weekday - 1 + 7) % 7  # Monday-based offset

	# Empty padding cells
	for _i in range(first_col):
		var empty := Control.new()
		empty.custom_minimum_size = Vector2(0, 72)
		_cal_grid.add_child(empty)

	# Day cells
	for day in range(1, days_in_month + 1):
		var date_str := "%04d-%02d-%02d" % [_display_year, _display_month, day]
		_cal_grid.add_child(_make_day_cell(day, date_str, date_str == today_str))

	_refresh_key_tasks()

func _make_day_cell(day: int, date_str: String, is_today: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 72)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL

	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.ACCENT_LIGHT if is_today else ThemeManager.BG_SURFACE
	sb.border_color = ThemeManager.ACCENT if is_today else ThemeManager.BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(ThemeManager.RADIUS_SM)
	sb.shadow_color  = ThemeManager.SHADOW_COLOR
	sb.shadow_size   = 4
	sb.shadow_offset = ThemeManager.SHADOW_OFFSET
	sb.content_margin_left   = 7.0
	sb.content_margin_right  = 7.0
	sb.content_margin_top    = 6.0
	sb.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", sb)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)
	panel.add_child(inner)

	# Day number
	var day_lbl := Label.new()
	day_lbl.text = str(day)
	day_lbl.add_theme_font_size_override("font_size", 13)
	if is_today:
		day_lbl.add_theme_color_override("font_color", ThemeManager.ACCENT)
	else:
		day_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
	inner.add_child(day_lbl)

	# Task chips (show up to 3)
	var day_tasks := DataManager.get_tasks_for_date(date_str)
	var shown := 0
	for t in day_tasks:
		if shown >= 3:
			break
		var chip := Label.new()
		var priority: String = t.get("priority", "C")
		chip.text = t.get("title", "")
		chip.add_theme_font_size_override("font_size", 10)
		chip.clip_text = true
		if t.get("done", false):
			chip.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		else:
			match priority:
				"A": chip.add_theme_color_override("font_color", ThemeManager.PRIORITY_A)
				"B": chip.add_theme_color_override("font_color", ThemeManager.PRIORITY_B)
				_:   chip.add_theme_color_override("font_color", ThemeManager.PRIORITY_C)
		inner.add_child(chip)
		shown += 1

	if day_tasks.size() > 3:
		var more_lbl := Label.new()
		more_lbl.text = "+%d more" % (day_tasks.size() - 3)
		more_lbl.add_theme_font_size_override("font_size", 10)
		more_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		inner.add_child(more_lbl)

	return panel

# ─── Key Tasks Panel ───────────────────────────────────────────────────────────
func _refresh_key_tasks() -> void:
	if not is_node_ready():
		return
	for c in _task_rows.get_children():
		c.queue_free()

	# Gather all tasks for this month
	var month_tasks: Array = []
	for t in DataManager.tasks:
		var d: String = t.get("date", "")
		if d.begins_with("%04d-%02d" % [_display_year, _display_month]):
			month_tasks.append(t)

	# Sort by date then priority
	month_tasks.sort_custom(func(a, b):
		var da: String = a.get("date", "")
		var db: String = b.get("date", "")
		if da != db:
			return da < db
		return a.get("priority","C") < b.get("priority","C")
	)

	for t in month_tasks:
		_task_rows.add_child(_make_key_task_row(t))

func _make_key_task_row(t: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 30)
	row.add_theme_constant_override("separation", 0)

	var sb_empty := StyleBoxEmpty.new()

	# Date column
	var date_wrap := PanelContainer.new()
	date_wrap.custom_minimum_size = Vector2(56, 0)
	date_wrap.add_theme_stylebox_override("panel", sb_empty)
	var date_lbl := Label.new()
	var d_parts := t.get("date", "----").split("-")
	if d_parts.size() == 3:
		date_lbl.text = "%s/%s" % [d_parts[1].lstrip("0"), d_parts[2].lstrip("0")]
	date_lbl.add_theme_font_size_override("font_size", 12)
	date_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	date_wrap.add_child(date_lbl)
	row.add_child(date_wrap)

	# Done status
	var status_wrap := PanelContainer.new()
	status_wrap.custom_minimum_size = Vector2(24, 0)
	status_wrap.add_theme_stylebox_override("panel", sb_empty)
	var status_lbl := Label.new()
	status_lbl.text = "✓" if t.get("done", false) else "○"
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.add_theme_color_override("font_color",
		ThemeManager.PRIORITY_C if t.get("done", false) else ThemeManager.TEXT_MUTED)
	status_wrap.add_child(status_lbl)
	row.add_child(status_wrap)

	# Priority
	var abc_wrap := PanelContainer.new()
	abc_wrap.custom_minimum_size = Vector2(28, 0)
	abc_wrap.add_theme_stylebox_override("panel", sb_empty)
	var abc_lbl := Label.new()
	var priority: String = t.get("priority", "C")
	abc_lbl.text = priority
	abc_lbl.add_theme_font_size_override("font_size", 12)
	match priority:
		"A": abc_lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_A)
		"B": abc_lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_B)
		_:   abc_lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_C)
	abc_wrap.add_child(abc_lbl)
	row.add_child(abc_wrap)

	# Title
	var title_lbl := Label.new()
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.text = t.get("title", "")
	title_lbl.add_theme_font_size_override("font_size", 12)
	title_lbl.clip_text = true
	if t.get("done", false):
		title_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	else:
		title_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
	row.add_child(title_lbl)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.add_child(row)
	var sep := HSeparator.new()
	wrapper.add_child(sep)
	return wrapper

# ─── Helpers ───────────────────────────────────────────────────────────────────
func _get_today_str() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func _days_in_month(year: int, month: int) -> int:
	const DAYS_PER_MONTH := [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	if month == 2:
		var leap := (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)
		return 29 if leap else 28
	return DAYS_PER_MONTH[month]
