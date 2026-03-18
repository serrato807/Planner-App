extends Node

# ─── Signals ───────────────────────────────────────────────────────────────────
signal data_changed
signal task_updated(task_id: String)
signal project_updated(project_id: String)

# ─── Constants ─────────────────────────────────────────────────────────────────
const SAVE_PATH    := "user://planner_data.json"
const SEED_VERSION := 3   # Bump to force a fresh re-seed on next launch

# ─── In-Memory Store ───────────────────────────────────────────────────────────
var tasks          : Array      = []
var projects       : Array      = []
var journal_entries: Array      = []
var daily_notes    : Array      = []
var schedules      : Dictionary = {}

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	load_data()

# ─── ID Generation ─────────────────────────────────────────────────────────────
func _generate_id() -> String:
	return str(Time.get_unix_time_from_system()) + str(randi())

# ─── Date Helper ───────────────────────────────────────────────────────────────
func _today_str() -> String:
	var d := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(d.year), int(d.month), int(d.day)]

# ─── Task Helpers ──────────────────────────────────────────────────────────────
func get_tasks_for_date(date_str: String) -> Array:
	var result: Array = []
	for t in tasks:
		if t.get("date", "") == date_str:
			result.append(t)
	return result

func get_tasks_for_project(project_id: String) -> Array:
	var result: Array = []
	for t in tasks:
		if t.get("project_id", "") == project_id:
			result.append(t)
	return result

func add_task(title: String, priority: String, date_str: String, project_id: String = "") -> Dictionary:
	var task := {
		"id":         _generate_id(),
		"title":      title,
		"priority":   priority,
		"done":       false,
		"date":       date_str,
		"project_id": project_id,
		"notes":      ""
	}
	tasks.append(task)
	save_data()
	data_changed.emit()
	return task

func update_task(task_id: String, new_data: Dictionary) -> void:
	for i in range(tasks.size()):
		if tasks[i].get("id") == task_id:
			for key in new_data.keys():
				tasks[i][key] = new_data[key]
			save_data()
			task_updated.emit(task_id)
			data_changed.emit()
			return

func toggle_task_done(task_id: String) -> void:
	for i in range(tasks.size()):
		if tasks[i].get("id") == task_id:
			tasks[i]["done"] = not tasks[i]["done"]
			save_data()
			task_updated.emit(task_id)
			data_changed.emit()
			return

# ─── Project Helpers ───────────────────────────────────────────────────────────
func add_project(title: String, description: String = "") -> Dictionary:
	var project := {
		"id":          _generate_id(),
		"title":       title,
		"description": description,
		"status":      "Active",
		"milestones":  []
	}
	projects.append(project)
	save_data()
	data_changed.emit()
	return project

func update_project(project_id: String, new_data: Dictionary) -> void:
	for i in range(projects.size()):
		if projects[i].get("id") == project_id:
			for key in new_data.keys():
				projects[i][key] = new_data[key]
			save_data()
			project_updated.emit(project_id)
			data_changed.emit()
			return

# ─── Journal Helpers ───────────────────────────────────────────────────────────
func get_journal_entry(date_str: String) -> String:
	for entry in journal_entries:
		if entry.get("date") == date_str:
			return entry.get("body", "")
	return ""

func set_journal_entry(date_str: String, body: String) -> void:
	for i in range(journal_entries.size()):
		if journal_entries[i].get("date") == date_str:
			journal_entries[i]["body"] = body
			save_data()
			return
	journal_entries.append({"date": date_str, "body": body})
	save_data()

# ─── Daily Notes Helpers ───────────────────────────────────────────────────────
func get_notes_for_date(date_str: String) -> Array:
	var result: Array = []
	for n in daily_notes:
		if n.get("date", "") == date_str:
			result.append(n)
	return result

func add_note(text: String, date_str: String) -> Dictionary:
	var note := {
		"id":   _generate_id(),
		"date": date_str,
		"text": text,
		"done": false
	}
	daily_notes.append(note)
	save_data()
	data_changed.emit()
	return note

func toggle_note_done(note_id: String) -> void:
	for i in range(daily_notes.size()):
		if daily_notes[i].get("id") == note_id:
			daily_notes[i]["done"] = not daily_notes[i]["done"]
			save_data()
			data_changed.emit()
			return

func delete_note(note_id: String) -> void:
	for i in range(daily_notes.size()):
		if daily_notes[i].get("id") == note_id:
			daily_notes.remove_at(i)
			save_data()
			data_changed.emit()
			return

# ─── Schedule Helpers ──────────────────────────────────────────────────────────
func get_schedule_for_date(date_str: String) -> Dictionary:
	return schedules.get(date_str, {})

func save_schedule_entry(date_str: String, hour: String, text: String) -> void:
	if not schedules.has(date_str):
		schedules[date_str] = {}
	if text.strip_edges().is_empty():
		schedules[date_str].erase(hour)
	else:
		schedules[date_str][hour] = text
	save_data()

func clear_schedule_entry(date_str: String, hour: String) -> void:
	if schedules.has(date_str):
		schedules[date_str].erase(hour)
		save_data()

# ─── Persistence ───────────────────────────────────────────────────────────────
func save_data() -> void:
	var payload := {
		"seed_version":    SEED_VERSION,
		"tasks":           tasks,
		"projects":        projects,
		"journal_entries": journal_entries,
		"daily_notes":     daily_notes,
		"schedules":       schedules
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("DataManager: cannot open save file — " + str(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_seed_defaults()
		save_data()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("DataManager: cannot open save file for reading.")
		_seed_defaults()
		return

	var raw := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(raw) != OK:
		push_error("DataManager: JSON parse error at line " + str(json.get_error_line()))
		_seed_defaults()
		return

	var d: Dictionary = json.data
	tasks            = d.get("tasks",           [])
	projects         = d.get("projects",        [])
	journal_entries  = d.get("journal_entries", [])
	daily_notes      = d.get("daily_notes",     [])
	schedules        = d.get("schedules",       {})

	# Re-seed if corrupt, empty, or stale seed version
	var saved_ver: int = d.get("seed_version", 0)
	if projects.is_empty() or saved_ver < SEED_VERSION:
		_seed_defaults()
		save_data()

# ─── Seed Data ─────────────────────────────────────────────────────────────────
func _seed_defaults() -> void:
	var today := _today_str()

	# ── Projects ───────────────────────────────────────────────────────────────
	projects = [
		{
			"id":          "proj_knr",
			"title":       "KNR Logistics",
			"description": "Freight and logistics coordination — routes, fleet, and client contracts.",
			"status":      "Active",
			"milestones":  ["Q2 Route Review", "Fleet Insurance Renewal", "Thompson Co. Contract"]
		},
		{
			"id":          "proj_app",
			"title":       "App Development",
			"description": "Franklin Planner desktop app build-out in Godot 4.",
			"status":      "Active",
			"milestones":  ["MVP Launch", "Today View Polish", "Weekly & Monthly Views"]
		},
		{
			"id":          "proj_personal",
			"title":       "Personal",
			"description": "Personal goals, errands, and self-improvement.",
			"status":      "Active",
			"milestones":  []
		}
	]

	# ── Tasks (today) ──────────────────────────────────────────────────────────
	tasks = [
		# A — Vital (undone)
		{
			"id":         "task_a1",
			"title":      "Finalize Q2 freight proposal for Thompson Co.",
			"priority":   "A",
			"done":       false,
			"date":       today,
			"project_id": "proj_knr",
			"notes":      ""
		},
		{
			"id":         "task_a2",
			"title":      "Call insurance broker — fleet coverage renewal",
			"priority":   "A",
			"done":       false,
			"date":       today,
			"project_id": "proj_knr",
			"notes":      ""
		},
		# B — Important (undone)
		{
			"id":         "task_b1",
			"title":      "Design app database schema and relationships",
			"priority":   "B",
			"done":       false,
			"date":       today,
			"project_id": "proj_app",
			"notes":      ""
		},
		{
			"id":         "task_b2",
			"title":      "Reply to team messages and clear action items",
			"priority":   "B",
			"done":       false,
			"date":       today,
			"project_id": "proj_personal",
			"notes":      ""
		},
		{
			"id":         "task_b3",
			"title":      "Pick up prescription from pharmacy",
			"priority":   "B",
			"done":       false,
			"date":       today,
			"project_id": "proj_personal",
			"notes":      ""
		},
		# C — Nice to do (undone)
		{
			"id":         "task_c1",
			"title":      "Read chapter 3 of Atomic Habits",
			"priority":   "C",
			"done":       false,
			"date":       today,
			"project_id": "proj_personal",
			"notes":      ""
		},
		# Done tasks
		{
			"id":         "task_done1",
			"title":      "Morning review — roles, goals, and priorities",
			"priority":   "A",
			"done":       true,
			"date":       today,
			"project_id": "proj_personal",
			"notes":      ""
		},
		{
			"id":         "task_done2",
			"title":      "Confirm delivery schedule with dispatcher",
			"priority":   "B",
			"done":       true,
			"date":       today,
			"project_id": "proj_knr",
			"notes":      ""
		}
	]

	# ── Daily Notes (today) ────────────────────────────────────────────────────
	daily_notes = [
		{
			"id":   "note_1",
			"date": today,
			"text": "Thompson Co. wants proposal by Friday COB — confirm deadline with Sarah",
			"done": false
		},
		{
			"id":   "note_2",
			"date": today,
			"text": "Fleet insurance policy #4472-B expires April 15",
			"done": false
		},
		{
			"id":   "note_3",
			"date": today,
			"text": "Ask Luis about delays on the Monterrey route",
			"done": false
		},
		{
			"id":   "note_4",
			"date": today,
			"text": "Book dentist appointment (3 months overdue)",
			"done": false
		},
		{
			"id":   "note_5",
			"date": today,
			"text": "Ordered replacement laptop charger — arrives Thursday",
			"done": true
		}
	]

	# ── Schedule (today) ───────────────────────────────────────────────────────
	schedules = {
		today: {
			"09": "Team standup — route review + weekly check-in",
			"10": "Thompson Co. proposal — draft key terms",
			"11": "Review Q2 route optimization data",
			"12": "Lunch w/ David at KNR office",
			"13": "Proposal revisions + pricing estimates",
			"14": "Insurance broker call (30 min)",
			"15": "App dev — DB schema + Today view polish",
			"16": "Admin block — email, follow-ups, Slack"
		}
	}

	journal_entries = []
