extends VBoxContainer

# ─── Nav ───────────────────────────────────────────────────────────────────────
@onready var _week_label    : Label         = $WeekNavMargin/WeekNavBar/WeekLabel
@onready var _prev_btn      : Button        = $WeekNavMargin/WeekNavBar/PrevWeekBtn
@onready var _next_btn      : Button        = $WeekNavMargin/WeekNavBar/NextWeekBtn
@onready var _this_week_btn : Button        = $WeekNavMargin/WeekNavBar/ThisWeekBtn
@onready var _week_grid     : HBoxContainer = $WeekContentMargin/WeekScroll/WeekGrid

# ─── State ─────────────────────────────────────────────────────────────────────
# Monday ISO date of the displayed week
var _week_start_str : String = ""

const DAYS     := ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
const AM_HOURS := ["09","10","11"]
const PM_HOURS := ["12","13","14","15","16","17","18","19","20","21"]

# day_index (0=Mon…6=Sun) -> VBoxContainer for task chips
var _day_task_columns : Array = []
# day_index -> Dictionary of hour -> LineEdit
var _day_sched_edits  : Array = []

# ─── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_week_start_str = _get_week_start(_get_today_str())

	_week_label.add_theme_font_size_override("font_size", 16)
	_week_label.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)

	for btn in [_prev_btn, _next_btn, _this_week_btn]:
		btn.add_theme_color_override("font_color", ThemeManager.ACCENT)
		btn.add_theme_font_size_override("font_size", 13)

	_prev_btn.pressed.connect(func() -> void: _shift_week(-1))
	_next_btn.pressed.connect(func() -> void: _shift_week(1))
	_this_week_btn.pressed.connect(func() -> void:
		_week_start_str = _get_week_start(_get_today_str())
		_rebuild_grid()
	)

	_build_grid()

	DataManager.data_changed.connect(_refresh_chips)

func _shift_week(delta: int) -> void:
	var parts := _week_start_str.split("-")
	var dt := {
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 12, "minute": 0, "second": 0
	}
	var unix := Time.get_unix_time_from_datetime_dict(dt) + delta * 7 * 86400
	var nd   := Time.get_datetime_dict_from_unix_time(unix)
	_week_start_str = "%04d-%02d-%02d" % [int(nd.year), int(nd.month), int(nd.day)]
	_rebuild_grid()

# ─── Grid Construction ─────────────────────────────────────────────────────────
func _build_grid() -> void:
	_day_task_columns.clear()
	_day_sched_edits.clear()

	# Update week label
	var parts := _week_start_str.split("-")
	var months := ["January","February","March","April","May","June",
	               "July","August","September","October","November","December"]
	_week_label.text = "Week of %s %s" % [months[int(parts[1]) - 1], parts[2].lstrip("0")]

	for i in range(7):
		var day_date := _date_offset(_week_start_str, i)
		var day_col  := _make_day_column(i, day_date)
		_week_grid.add_child(day_col)

func _rebuild_grid() -> void:
	for c in _week_grid.get_children():
		c.queue_free()
	_day_task_columns.clear()
	_day_sched_edits.clear()
	_build_grid()

func _make_day_column(day_idx: int, date_str: String) -> Control:
	var today := _get_today_str()

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)

	# Column card — rounded corners, soft border, subtle shadow
	var sb := StyleBoxFlat.new()
	sb.bg_color = ThemeManager.BG_SURFACE
	sb.border_color = ThemeManager.BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(ThemeManager.RADIUS_MD)
	sb.shadow_color  = ThemeManager.SHADOW_COLOR
	sb.shadow_size   = ThemeManager.SHADOW_SIZE
	sb.shadow_offset = ThemeManager.SHADOW_OFFSET
	sb.content_margin_left   = 0.0
	sb.content_margin_right  = 0.0
	sb.content_margin_top    = 0.0
	sb.content_margin_bottom = 8.0

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	panel.add_theme_stylebox_override("panel", sb)
	panel.add_child(col)

	# ── Day header ─────────────────────────────────────────────────────────────
	var header := PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 44)
	var header_sb := StyleBoxFlat.new()
	var is_today := date_str == today
	header_sb.bg_color = ThemeManager.ACCENT if is_today else ThemeManager.BG_PRIMARY
	header_sb.set_border_width_all(0)
	# Rounded top corners to match parent card
	header_sb.corner_radius_top_left     = ThemeManager.RADIUS_MD
	header_sb.corner_radius_top_right    = ThemeManager.RADIUS_MD
	header_sb.corner_radius_bottom_left  = 0
	header_sb.corner_radius_bottom_right = 0
	header_sb.content_margin_left   = 8.0
	header_sb.content_margin_right  = 8.0
	header_sb.content_margin_top    = 10.0
	header_sb.content_margin_bottom = 10.0
	header.add_theme_stylebox_override("panel", header_sb)

	var header_inner := VBoxContainer.new()
	header_inner.add_theme_constant_override("separation", 2)
	var day_lbl := Label.new()
	day_lbl.text = DAYS[day_idx]
	day_lbl.add_theme_font_size_override("font_size", 11)
	day_lbl.add_theme_color_override("font_color",
		ThemeManager.BG_SURFACE if is_today else ThemeManager.TEXT_MUTED)
	header_inner.add_child(day_lbl)

	var date_parts := date_str.split("-")
	var date_lbl := Label.new()
	date_lbl.text = str(int(date_parts[2]))
	date_lbl.add_theme_font_size_override("font_size", 18)
	date_lbl.add_theme_color_override("font_color",
		ThemeManager.BG_SURFACE if is_today else ThemeManager.TEXT_PRIMARY)
	header_inner.add_child(date_lbl)
	header.add_child(header_inner)
	col.add_child(header)

	var header_sep := HSeparator.new()
	col.add_child(header_sep)

	# ── AM schedule rows ───────────────────────────────────────────────────────
	var sched_edits: Dictionary = {}
	for hour in AM_HOURS:
		var row := _make_schedule_row(hour, date_str, sched_edits)
		col.add_child(row)

	# ── Noon divider ───────────────────────────────────────────────────────────
	var noon_sep := HSeparator.new()
	noon_sep.add_theme_color_override("color", ThemeManager.PRIORITY_A)
	col.add_child(noon_sep)

	# ── PM schedule rows ───────────────────────────────────────────────────────
	for hour in PM_HOURS:
		var row := _make_schedule_row(hour, date_str, sched_edits)
		col.add_child(row)

	# ── Tasks section ──────────────────────────────────────────────────────────
	var tasks_sep := HSeparator.new()
	col.add_child(tasks_sep)

	var tasks_hdr := Label.new()
	tasks_hdr.text = "TASKS"
	tasks_hdr.add_theme_font_size_override("font_size", 10)
	tasks_hdr.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	col.add_child(tasks_hdr)

	var task_chips := VBoxContainer.new()
	task_chips.add_theme_constant_override("separation", 3)
	col.add_child(task_chips)

	_day_task_columns.append({"date": date_str, "container": task_chips})
	_day_sched_edits.append({"date": date_str, "edits": sched_edits})

	_populate_task_chips(task_chips, date_str)
	_populate_schedule_edits(sched_edits, date_str)

	return panel

func _make_schedule_row(hour: String, date_str: String, edits_dict: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.add_theme_constant_override("separation", 4)

	var h := int(hour)
	var time_lbl := Label.new()
	time_lbl.custom_minimum_size = Vector2(32, 0)
	if h == 12:
		time_lbl.text = "12p"
		time_lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_A)
	elif h < 12:
		time_lbl.text = str(h) + "a"
		time_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	else:
		time_lbl.text = str(h - 12) + "p"
		time_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	time_lbl.add_theme_font_size_override("font_size", 10)
	row.add_child(time_lbl)

	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", 11)
	edit.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
	var edit_sb_n := StyleBoxFlat.new()
	edit_sb_n.bg_color = Color(0, 0, 0, 0)
	edit_sb_n.set_border_width_all(0)
	edit_sb_n.content_margin_left   = 2.0
	edit_sb_n.content_margin_right  = 2.0
	edit_sb_n.content_margin_top    = 2.0
	edit_sb_n.content_margin_bottom = 2.0
	var edit_sb_f := StyleBoxFlat.new()
	edit_sb_f.bg_color = ThemeManager.ACCENT_LIGHT
	edit_sb_f.border_color = ThemeManager.ACCENT
	edit_sb_f.set_border_width_all(1)
	edit_sb_f.content_margin_left   = 1.0
	edit_sb_f.content_margin_right  = 1.0
	edit_sb_f.content_margin_top    = 1.0
	edit_sb_f.content_margin_bottom = 1.0
	edit.add_theme_stylebox_override("normal", edit_sb_n)
	edit.add_theme_stylebox_override("focus",  edit_sb_f)
	row.add_child(edit)

	edits_dict[hour] = edit

	# Debounce save
	var timer := Timer.new()
	timer.wait_time = 1.0
	timer.one_shot  = true
	add_child(timer)
	var h_str   := hour
	var d_str   := date_str
	timer.timeout.connect(func() -> void:
		DataManager.save_schedule_entry(d_str, h_str, edit.text)
	)
	edit.text_changed.connect(func(_v: String) -> void:
		timer.stop()
		timer.start()
	)

	return row

# ─── Populate ─────────────────────────────────────────────────────────────────
func _populate_task_chips(container: VBoxContainer, date_str: String) -> void:
	for c in container.get_children():
		c.queue_free()
	var day_tasks := DataManager.get_tasks_for_date(date_str)
	for t in day_tasks:
		var chip := Label.new()
		var priority: String = t.get("priority", "C")
		var title: String    = t.get("title", "")
		chip.text = "%s  %s" % [priority, title]
		chip.add_theme_font_size_override("font_size", 11)
		chip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if t.get("done", false):
			chip.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		else:
			match priority:
				"A": chip.add_theme_color_override("font_color", ThemeManager.PRIORITY_A)
				"B": chip.add_theme_color_override("font_color", ThemeManager.PRIORITY_B)
				_:   chip.add_theme_color_override("font_color", ThemeManager.PRIORITY_C)
		container.add_child(chip)

func _populate_schedule_edits(edits_dict: Dictionary, date_str: String) -> void:
	var sched := DataManager.get_schedule_for_date(date_str)
	for hour in edits_dict.keys():
		var edit: LineEdit = edits_dict[hour]
		edit.text = sched.get(hour, "")

func _refresh_chips() -> void:
	if not is_node_ready():
		return
	for entry in _day_task_columns:
		_populate_task_chips(entry["container"], entry["date"])

# ─── Date Helpers ──────────────────────────────────────────────────────────────
func _get_today_str() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func _get_week_start(date_str: String) -> String:
	# Returns the Monday of the week containing date_str
	var parts := date_str.split("-")
	var dt := {
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 12, "minute": 0, "second": 0
	}
	var unix := Time.get_unix_time_from_datetime_dict(dt)
	var info := Time.get_datetime_dict_from_unix_time(unix)
	# weekday: 0=Sunday, 1=Monday … 6=Saturday
	var weekday := int(info.weekday)
	var days_since_monday := (weekday - 1 + 7) % 7
	var monday_unix := unix - days_since_monday * 86400
	var md := Time.get_datetime_dict_from_unix_time(monday_unix)
	return "%04d-%02d-%02d" % [int(md.year), int(md.month), int(md.day)]

func _date_offset(base_str: String, days: int) -> String:
	var parts := base_str.split("-")
	var dt := {
		"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
		"hour": 12, "minute": 0, "second": 0
	}
	var unix := Time.get_unix_time_from_datetime_dict(dt) + days * 86400
	var nd   := Time.get_datetime_dict_from_unix_time(unix)
	return "%04d-%02d-%02d" % [int(nd.year), int(nd.month), int(nd.day)]
