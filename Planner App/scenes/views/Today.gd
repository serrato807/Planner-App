extends VBoxContainer

# ─── Nav Bar ───────────────────────────────────────────────────────────────────
@onready var _date_label         : Label   = $NavMargin/DayNavBar/DateLabel
@onready var _completion_counter : Label   = $NavMargin/DayNavBar/CompletionCounter
@onready var _prev_day_btn       : Button  = $NavMargin/DayNavBar/PrevDayBtn
@onready var _next_day_btn       : Button  = $NavMargin/DayNavBar/NextDayBtn
@onready var _today_btn          : Button  = $NavMargin/DayNavBar/TodayBtn

# ─── Task Panel ────────────────────────────────────────────────────────────────
@onready var _task_rows      : VBoxContainer = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/TaskRows
@onready var _add_task_input : LineEdit      = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/AddTaskRow/AddTaskInput
@onready var _save_task_btn  : Button        = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/AddTaskRow/SaveTaskBtn
@onready var _btn_a          : Button        = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/AddTaskRow/BtnA
@onready var _btn_b          : Button        = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/AddTaskRow/BtnB
@onready var _btn_c          : Button        = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/AddTaskRow/BtnC

# ─── Schedule Panel ────────────────────────────────────────────────────────────
@onready var _schedule_rows  : VBoxContainer = $PanelMargin/ThreePanels/SchedulePanel/ScheduleScroll/ScheduleInner/ScheduleRows
@onready var _schedule_inner : VBoxContainer = $PanelMargin/ThreePanels/SchedulePanel/ScheduleScroll/ScheduleInner
@onready var _sched_col_time : Label         = $PanelMargin/ThreePanels/SchedulePanel/ScheduleScroll/ScheduleInner/ScheduleHeaderRow/ScheduleColTime
@onready var _sched_col_entry: Label         = $PanelMargin/ThreePanels/SchedulePanel/ScheduleScroll/ScheduleInner/ScheduleHeaderRow/ScheduleColEntry

# ─── Notes Panel ───────────────────────────────────────────────────────────────
@onready var _note_rows      : VBoxContainer = $PanelMargin/ThreePanels/NotesPanel/NotesScroll/NotesInner/NoteRows
@onready var _add_note_input : LineEdit      = $PanelMargin/ThreePanels/NotesPanel/NotesScroll/NotesInner/AddNoteRow/AddNoteInput
@onready var _save_note_btn  : Button        = $PanelMargin/ThreePanels/NotesPanel/NotesScroll/NotesInner/AddNoteRow/SaveNoteBtn
@onready var _notes_col_x    : Label         = $PanelMargin/ThreePanels/NotesPanel/NotesScroll/NotesInner/NotesHeaderRow/NotesColX
@onready var _notes_col_num  : Label         = $PanelMargin/ThreePanels/NotesPanel/NotesScroll/NotesInner/NotesHeaderRow/NotesColNum
@onready var _notes_col_text : Label         = $PanelMargin/ThreePanels/NotesPanel/NotesScroll/NotesInner/NotesHeaderRow/NotesColText

# ─── State ─────────────────────────────────────────────────────────────────────
var _view_date_str    : String     = ""
var _selected_priority: String     = "A"
var _schedule_edits   : Dictionary = {}
var _schedule_timers  : Dictionary = {}

const AM_HOURS := ["09", "10", "11"]
const PM_HOURS := ["12", "13", "14", "15", "16", "17", "18", "19", "20", "21"]

# ─── Ready ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_view_date_str = _get_today_str()

	# Nav bar
	_style_nav_bar()
	_prev_day_btn.pressed.connect(func() -> void: _shift_day(-1))
	_next_day_btn.pressed.connect(func() -> void: _shift_day(1))
	_today_btn.pressed.connect(func() -> void:
		_view_date_str = _get_today_str()
		_refresh_all()
	)

	# Thin separator line beneath the nav bar
	var nav_sep := HSeparator.new()
	add_child(nav_sep)
	move_child(nav_sep, 1)   # index 0 = NavMargin, 1 = separator, 2 = PanelMargin

	# Panel interiors
	_inject_panel_titles()
	_style_column_headers()
	_style_add_inputs()
	_apply_panel_styles()

	# Task input wiring
	ThemeManager.style_button_accent(_save_task_btn)
	_save_task_btn.pressed.connect(_on_save_task)
	_add_task_input.text_submitted.connect(func(_t: String) -> void: _on_save_task())
	_btn_a.pressed.connect(func() -> void: _select_priority("A"))
	_btn_b.pressed.connect(func() -> void: _select_priority("B"))
	_btn_c.pressed.connect(func() -> void: _select_priority("C"))
	_select_priority("A")

	# Schedule
	_build_schedule_rows()

	# Note input wiring
	ThemeManager.style_button_accent(_save_note_btn)
	_save_note_btn.pressed.connect(_on_save_note)
	_add_note_input.text_submitted.connect(func(_t: String) -> void: _on_save_note())

	DataManager.data_changed.connect(_refresh_all)
	_refresh_all()

# ─── Panel Setup ───────────────────────────────────────────────────────────────
func _inject_panel_titles() -> void:
	var task_inner  : VBoxContainer = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner
	var notes_inner : VBoxContainer = $PanelMargin/ThreePanels/NotesPanel/NotesScroll/NotesInner

	for pair in [["TASKS", task_inner], ["SCHEDULE", _schedule_inner], ["NOTES", notes_inner]]:
		var lbl := _make_panel_title(pair[0] as String)
		var container := pair[1] as VBoxContainer
		container.add_child(lbl)
		container.move_child(lbl, 0)

func _make_panel_title(text: String) -> Label:
	var lbl := Label.new()
	lbl.text                  = text
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", ThemeManager.ACCENT)
	lbl.custom_minimum_size   = Vector2(0, 32)
	lbl.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl

func _style_column_headers() -> void:
	var col_x   : Label = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/TaskHeaderRow/ColX
	var col_abc : Label = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/TaskHeaderRow/ColABC
	var col_task: Label = $PanelMargin/ThreePanels/TaskPanel/TaskScroll/TaskInner/TaskHeaderRow/ColTask
	col_x.text = "";  col_abc.text = "PRI";  col_task.text = "TASK"

	_sched_col_time.text = "TIME";  _sched_col_entry.text = "ENTRY"

	_notes_col_x.text = "";  _notes_col_num.text = "#";  _notes_col_text.text = "NOTE"

	for lbl: Label in [col_x, col_abc, col_task,
						_sched_col_time, _sched_col_entry,
						_notes_col_x, _notes_col_num, _notes_col_text]:
		lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _style_add_inputs() -> void:
	for input: LineEdit in [_add_task_input, _add_note_input]:
		input.add_theme_stylebox_override("normal", _input_sb(false))
		input.add_theme_stylebox_override("focus",  _input_sb(true))
		input.add_theme_font_size_override("font_size", 13)
	_add_task_input.placeholder_text = "New task…"
	_add_note_input.placeholder_text = "New note…"

func _input_sb(focused: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = ThemeManager.BG_SURFACE if focused else ThemeManager.BG_PRIMARY
	sb.border_color = ThemeManager.ACCENT if focused else ThemeManager.BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(ThemeManager.RADIUS_SM)
	sb.content_margin_left   = 10.0;  sb.content_margin_right  = 10.0
	sb.content_margin_top    = 8.0;   sb.content_margin_bottom = 8.0
	return sb

func _apply_panel_styles() -> void:
	for panel: PanelContainer in [
		$PanelMargin/ThreePanels/TaskPanel,
		$PanelMargin/ThreePanels/SchedulePanel,
		$PanelMargin/ThreePanels/NotesPanel
	]:
		var sb := StyleBoxFlat.new()
		sb.bg_color     = ThemeManager.BG_SURFACE
		sb.border_color = ThemeManager.BORDER
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(ThemeManager.RADIUS_MD)
		sb.shadow_color  = ThemeManager.SHADOW_COLOR
		sb.shadow_size   = ThemeManager.SHADOW_SIZE
		sb.shadow_offset = ThemeManager.SHADOW_OFFSET
		sb.content_margin_left   = 18.0;  sb.content_margin_right  = 18.0
		sb.content_margin_top    = 14.0;  sb.content_margin_bottom = 18.0
		panel.add_theme_stylebox_override("panel", sb)

# ─── Nav Bar ───────────────────────────────────────────────────────────────────
func _style_nav_bar() -> void:
	_date_label.add_theme_font_size_override("font_size", 22)
	_date_label.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
	_date_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_completion_counter.add_theme_font_size_override("font_size", 12)
	_completion_counter.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	_completion_counter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	for btn: Button in [_prev_day_btn, _next_day_btn, _today_btn]:
		btn.add_theme_color_override("font_color", ThemeManager.ACCENT)
		btn.add_theme_font_size_override("font_size", 13)

# ─── Day Navigation ────────────────────────────────────────────────────────────
func _shift_day(delta: int) -> void:
	var parts := _view_date_str.split("-")
	var dt    := {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
				  "hour": 12, "minute": 0, "second": 0}
	var unix  := Time.get_unix_time_from_datetime_dict(dt) + delta * 86400
	var nd    := Time.get_datetime_dict_from_unix_time(unix)
	_view_date_str = "%04d-%02d-%02d" % [int(nd.year), int(nd.month), int(nd.day)]
	_refresh_all()

# ─── Refresh ───────────────────────────────────────────────────────────────────
func _refresh_all() -> void:
	if not is_node_ready():
		return
	_date_label.text = _format_date(_view_date_str)
	_refresh_tasks()
	_refresh_schedule()
	_refresh_notes()

# ─── Task Panel ────────────────────────────────────────────────────────────────
func _refresh_tasks() -> void:
	for c in _task_rows.get_children():
		c.queue_free()

	var all_tasks := DataManager.get_tasks_for_date(_view_date_str)
	var undone    := all_tasks.filter(func(t): return not t.get("done", false))
	var done      := all_tasks.filter(func(t): return t.get("done", false))

	undone.sort_custom(func(a, b): return a.get("priority","C") < b.get("priority","C"))
	done.sort_custom(func(a, b):   return a.get("priority","C") < b.get("priority","C"))

	# Undone tasks — grouped by priority with section headers
	var current_group := ""
	for t in undone:
		var p: String = t.get("priority", "C")
		if p != current_group:
			current_group = p
			_task_rows.add_child(_make_priority_header(p, current_group == "A"))
		_task_rows.add_child(_make_task_row(t))

	# Done tasks — single "COMPLETED" section at the bottom
	if done.size() > 0:
		_task_rows.add_child(_make_priority_header("done", undone.is_empty()))
		for t in done:
			_task_rows.add_child(_make_task_row(t))

	# Completion counter
	var done_count := done.size()
	if all_tasks.is_empty():
		_completion_counter.text = ""
	elif done_count == all_tasks.size():
		_completion_counter.text = "✓ All done!"
		_completion_counter.add_theme_color_override("font_color", ThemeManager.PRIORITY_C)
	else:
		_completion_counter.text = "%d / %d" % [done_count, all_tasks.size()]
		_completion_counter.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)

func _make_priority_header(priority: String, is_first: bool) -> Control:
	# Wrapper adds top spacing between sections (except the very first)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top",    0 if is_first else 14)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_theme_constant_override("margin_left",   0)
	margin.add_theme_constant_override("margin_right",  0)

	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(0, 20)

	match priority:
		"A":
			lbl.text = "A  ·  VITAL"
			lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_A)
		"B":
			lbl.text = "B  ·  IMPORTANT"
			lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_B)
		"C":
			lbl.text = "C  ·  NICE TO DO"
			lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_C)
		_:
			lbl.text = "COMPLETED"
			lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)

	margin.add_child(lbl)
	return margin

func _make_task_row(t: Dictionary) -> Control:
	var is_done  : bool   = t.get("done", false)
	var priority : String = t.get("priority", "C")

	var pri_color: Color
	match priority:
		"A": pri_color = ThemeManager.PRIORITY_A
		"B": pri_color = ThemeManager.PRIORITY_B
		_:   pri_color = ThemeManager.PRIORITY_C

	# Outer panel: left-accent bar + vertical padding
	var row_panel := PanelContainer.new()
	var row_sb    := StyleBoxFlat.new()
	row_sb.bg_color            = Color(0, 0, 0, 0)
	row_sb.border_color        = pri_color if not is_done else ThemeManager.BORDER
	row_sb.border_width_left   = 3 if not is_done else 2
	row_sb.border_width_right  = 0
	row_sb.border_width_top    = 0
	row_sb.border_width_bottom = 0
	row_sb.content_margin_left   = 10.0
	row_sb.content_margin_right  = 6.0
	row_sb.content_margin_top    = 9.0
	row_sb.content_margin_bottom = 9.0
	row_panel.add_theme_stylebox_override("panel", row_sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row_panel.add_child(row)

	# Checkbox
	var chk := CheckBox.new()
	chk.button_pressed      = is_done
	chk.text                = ""
	chk.custom_minimum_size = Vector2(24, 0)
	chk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chk)

	# Priority badge
	var badge := Label.new()
	badge.text                 = priority
	badge.custom_minimum_size  = Vector2(22, 0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	badge.add_theme_font_size_override("font_size", 11)
	badge.add_theme_color_override("font_color",
		ThemeManager.TEXT_MUTED if is_done else pri_color)
	row.add_child(badge)

	# Title
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	title.text                  = t.get("title", "")
	title.add_theme_font_size_override("font_size", 14)
	title.vertical_alignment    = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode         = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color",
		ThemeManager.TEXT_MUTED if is_done else ThemeManager.TEXT_PRIMARY)
	row.add_child(title)

	var task_id: String = t.get("id", "")
	chk.toggled.connect(func(_p: bool) -> void: DataManager.toggle_task_done(task_id))

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.add_child(row_panel)
	wrapper.add_child(HSeparator.new())
	return wrapper

# ─── Priority Selector ─────────────────────────────────────────────────────────
func _select_priority(p: String) -> void:
	_selected_priority = p
	var map := {"A": [_btn_a, ThemeManager.PRIORITY_A],
				"B": [_btn_b, ThemeManager.PRIORITY_B],
				"C": [_btn_c, ThemeManager.PRIORITY_C]}
	for key in map:
		var btn : Button = map[key][0]
		var col : Color  = map[key][1]
		var sel := key == p
		btn.add_theme_color_override("font_color", Color.WHITE if sel else ThemeManager.TEXT_MUTED)
		var sb := StyleBoxFlat.new()
		sb.bg_color = col if sel else Color(0, 0, 0, 0)
		sb.set_border_width_all(0)
		sb.set_corner_radius_all(ThemeManager.RADIUS_SM)
		sb.content_margin_left  = 7.0;  sb.content_margin_right  = 7.0
		sb.content_margin_top   = 4.0;  sb.content_margin_bottom = 4.0
		for state in ["normal", "hover", "pressed"]:
			btn.add_theme_stylebox_override(state, sb)

func _on_save_task() -> void:
	var t := _add_task_input.text.strip_edges()
	if t.is_empty():
		return
	DataManager.add_task(t, _selected_priority, _view_date_str)
	_add_task_input.clear()

# ─── Schedule Panel ────────────────────────────────────────────────────────────
func _build_schedule_rows() -> void:
	_schedule_edits.clear()
	_schedule_timers.clear()
	for c in _schedule_rows.get_children():
		c.queue_free()

	_schedule_rows.add_child(_make_time_block_label("MORNING"))
	for hour in AM_HOURS:
		_schedule_rows.add_child(_make_schedule_hour_row(hour))

	var noon_sep := HSeparator.new()
	noon_sep.add_theme_color_override("color", ThemeManager.PRIORITY_A)
	_schedule_rows.add_child(noon_sep)

	_schedule_rows.add_child(_make_time_block_label("AFTERNOON"))
	for hour in PM_HOURS:
		_schedule_rows.add_child(_make_schedule_hour_row(hour))

func _make_time_block_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	lbl.custom_minimum_size = Vector2(0, 22)
	lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	return lbl

func _make_schedule_hour_row(hour: String) -> Control:
	var h := int(hour)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 32)
	row.add_theme_constant_override("separation", 8)

	var time_lbl := Label.new()
	time_lbl.custom_minimum_size  = Vector2(40, 0)
	time_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_lbl.size_flags_vertical  = Control.SIZE_EXPAND_FILL
	time_lbl.add_theme_font_size_override("font_size", 11)
	if h == 12:
		time_lbl.text = "12p"
		time_lbl.add_theme_color_override("font_color", ThemeManager.PRIORITY_A)
	elif h < 12:
		time_lbl.text = str(h) + "a"
		time_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	else:
		time_lbl.text = str(h - 12) + "p"
		time_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	row.add_child(time_lbl)

	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	edit.add_theme_font_size_override("font_size", 12)
	edit.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = Color(0, 0, 0, 0);  sb_n.set_border_width_all(0)
	sb_n.content_margin_left = 6.0;  sb_n.content_margin_right  = 6.0
	sb_n.content_margin_top  = 5.0;  sb_n.content_margin_bottom = 5.0

	var sb_f := StyleBoxFlat.new()
	sb_f.bg_color = ThemeManager.ACCENT_LIGHT;  sb_f.border_color = ThemeManager.ACCENT
	sb_f.set_border_width_all(1);  sb_f.set_corner_radius_all(ThemeManager.RADIUS_SM)
	sb_f.content_margin_left = 6.0;  sb_f.content_margin_right  = 6.0
	sb_f.content_margin_top  = 4.0;  sb_f.content_margin_bottom = 4.0

	edit.add_theme_stylebox_override("normal",    sb_n)
	edit.add_theme_stylebox_override("focus",     sb_f)
	edit.add_theme_stylebox_override("read_only", sb_n)
	row.add_child(edit)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.add_child(row)
	wrapper.add_child(HSeparator.new())

	_schedule_edits[hour] = edit

	var timer := Timer.new()
	timer.wait_time = 0.8;  timer.one_shot = true
	add_child(timer)
	var h_str := hour
	timer.timeout.connect(func() -> void: _save_schedule_hour(h_str))
	edit.text_changed.connect(func(_v: String) -> void: timer.stop(); timer.start())
	_schedule_timers[hour] = timer

	return wrapper

func _refresh_schedule() -> void:
	var sched := DataManager.get_schedule_for_date(_view_date_str)
	for hour in _schedule_edits.keys():
		(_schedule_edits[hour] as LineEdit).text = sched.get(hour, "")

func _save_schedule_hour(hour: String) -> void:
	if _schedule_edits.has(hour):
		DataManager.save_schedule_entry(_view_date_str, hour,
			(_schedule_edits[hour] as LineEdit).text)

# ─── Notes Panel ───────────────────────────────────────────────────────────────
func _refresh_notes() -> void:
	for c in _note_rows.get_children():
		c.queue_free()
	var notes := DataManager.get_notes_for_date(_view_date_str)
	for i in range(notes.size()):
		_note_rows.add_child(_make_note_row(notes[i], i + 1))

func _make_note_row(n: Dictionary, num: int) -> Control:
	var is_done: bool = n.get("done", false)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var sb_empty := StyleBoxEmpty.new()

	# Checkbox
	var chk_wrap := PanelContainer.new()
	chk_wrap.custom_minimum_size = Vector2(28, 0)
	chk_wrap.add_theme_stylebox_override("panel", sb_empty)
	var chk := CheckBox.new()
	chk.button_pressed = is_done;  chk.text = ""
	chk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chk_wrap.add_child(chk)
	row.add_child(chk_wrap)

	# Number
	var num_wrap := PanelContainer.new()
	num_wrap.custom_minimum_size = Vector2(26, 0)
	num_wrap.add_theme_stylebox_override("panel", sb_empty)
	var num_lbl := Label.new()
	num_lbl.text = str(num)
	num_lbl.add_theme_font_size_override("font_size", 11)
	num_lbl.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
	num_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
	num_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	num_wrap.add_child(num_lbl)
	row.add_child(num_wrap)

	# Note text
	var text_lbl := Label.new()
	text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_lbl.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	text_lbl.text = n.get("text", "")
	text_lbl.add_theme_font_size_override("font_size", 13)
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.autowrap_mode      = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.add_theme_color_override("font_color",
		ThemeManager.TEXT_MUTED if is_done else ThemeManager.TEXT_PRIMARY)
	row.add_child(text_lbl)

	var note_id: String = n.get("id", "")
	chk.toggled.connect(func(_p: bool) -> void: DataManager.toggle_note_done(note_id))

	# MarginContainer adds vertical breathing room around the row
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top",    9)
	margin.add_theme_constant_override("margin_bottom", 9)
	margin.add_theme_constant_override("margin_left",   0)
	margin.add_theme_constant_override("margin_right",  0)
	margin.add_child(row)

	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 0)
	wrapper.add_child(margin)
	wrapper.add_child(HSeparator.new())
	return wrapper

func _on_save_note() -> void:
	var text := _add_note_input.text.strip_edges()
	if text.is_empty():
		return
	DataManager.add_note(text, _view_date_str)
	_add_note_input.clear()

# ─── Date Helpers ──────────────────────────────────────────────────────────────
func _get_today_str() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

func _format_date(date_str: String) -> String:
	var parts := date_str.split("-")
	if parts.size() != 3:
		return date_str
	var dt   := {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]),
				 "hour": 0, "minute": 0, "second": 0}
	var unix := Time.get_unix_time_from_datetime_dict(dt)
	var info := Time.get_datetime_dict_from_unix_time(unix)
	var days   := ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
	var months := ["January","February","March","April","May","June",
	               "July","August","September","October","November","December"]
	return "%s, %s %d" % [days[int(info.weekday)], months[int(info.month) - 1], int(info.day)]
