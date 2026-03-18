extends Node

# ─── Color Palette ─────────────────────────────────────────────────────────────
const BG_PRIMARY   := Color("#F7F7F5")   # Page background — warm off-white
const BG_SURFACE   := Color("#FFFFFF")   # Card/panel surface — pure white
const BG_SIDEBAR   := Color("#F0F0EE")   # Sidebar — slightly cooler off-white
const BORDER       := Color("#E8E8E5")   # Dividers and panel borders (softer)
const TEXT_PRIMARY := Color("#1A1A1A")   # Main body text
const TEXT_MUTED   := Color("#9B9B9B")   # Labels, placeholders, secondary info
const ACCENT       := Color("#2563EB")   # Interactive blue
const ACCENT_LIGHT := Color("#EEF3FD")   # ~6% ACCENT tint for hover/focus bg
const PRIORITY_A   := Color("#DC2626")   # Critical — red
const PRIORITY_B   := Color("#D97706")   # Important — amber
const PRIORITY_C   := Color("#16A34A")   # Good-to-do — green

# ─── Corner Radii ──────────────────────────────────────────────────────────────
const RADIUS_SM  := 6    # Buttons, inputs, small chips
const RADIUS_MD  := 10   # Cards, panels
const RADIUS_LG  := 14   # Modal-sized containers

# ─── Shadow ────────────────────────────────────────────────────────────────────
const SHADOW_COLOR  := Color(0.0, 0.0, 0.0, 0.07)
const SHADOW_SIZE   := 8
const SHADOW_OFFSET := Vector2(0, 2)

# ─── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	await get_tree().process_frame
	get_tree().root.theme = _build_global_theme()

# ─── Global Theme Builder ──────────────────────────────────────────────────────
func _build_global_theme() -> Theme:
	var t := Theme.new()

	# ── Panel / PanelContainer ─────────────────────────────────────────────────
	var panel_sb := _card_box(BG_SURFACE)
	t.set_stylebox("panel", "Panel", panel_sb)
	t.set_stylebox("panel", "PanelContainer", panel_sb)

	# ── Label ──────────────────────────────────────────────────────────────────
	t.set_color("font_color", "Label", TEXT_PRIMARY)

	# ── Button ─────────────────────────────────────────────────────────────────
	var btn_normal := _flat_box(Color(0,0,0,0), Color(0,0,0,0), 0, RADIUS_SM)
	btn_normal.content_margin_left   = 10.0
	btn_normal.content_margin_right  = 10.0
	btn_normal.content_margin_top    = 5.0
	btn_normal.content_margin_bottom = 5.0

	var btn_hover := _flat_box(ACCENT_LIGHT, Color(0,0,0,0), 0, RADIUS_SM)
	btn_hover.content_margin_left   = 10.0
	btn_hover.content_margin_right  = 10.0
	btn_hover.content_margin_top    = 5.0
	btn_hover.content_margin_bottom = 5.0

	var btn_pressed := _flat_box(Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.18), Color(0,0,0,0), 0, RADIUS_SM)
	btn_pressed.content_margin_left   = 10.0
	btn_pressed.content_margin_right  = 10.0
	btn_pressed.content_margin_top    = 5.0
	btn_pressed.content_margin_bottom = 5.0

	t.set_stylebox("normal",   "Button", btn_normal)
	t.set_stylebox("hover",    "Button", btn_hover)
	t.set_stylebox("pressed",  "Button", btn_pressed)
	t.set_stylebox("focus",    "Button", StyleBoxEmpty.new())
	t.set_stylebox("disabled", "Button", btn_normal)
	t.set_color("font_color",          "Button", TEXT_PRIMARY)
	t.set_color("font_hover_color",    "Button", ACCENT)
	t.set_color("font_pressed_color",  "Button", ACCENT)
	t.set_color("font_focus_color",    "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", TEXT_MUTED)

	# ── LineEdit ───────────────────────────────────────────────────────────────
	var le_normal := _flat_box(BG_SURFACE, BORDER, 1, RADIUS_SM)
	le_normal.content_margin_left   = 10.0
	le_normal.content_margin_right  = 10.0
	le_normal.content_margin_top    = 7.0
	le_normal.content_margin_bottom = 7.0

	var le_focus := _flat_box(BG_SURFACE, ACCENT, 2, RADIUS_SM)
	le_focus.content_margin_left   = 10.0
	le_focus.content_margin_right  = 10.0
	le_focus.content_margin_top    = 7.0
	le_focus.content_margin_bottom = 7.0

	t.set_stylebox("normal",    "LineEdit", le_normal)
	t.set_stylebox("focus",     "LineEdit", le_focus)
	t.set_stylebox("read_only", "LineEdit", le_normal)
	t.set_color("font_color",             "LineEdit", TEXT_PRIMARY)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_MUTED)
	t.set_color("selection_color",        "LineEdit", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.28))
	t.set_color("caret_color",            "LineEdit", ACCENT)

	# ── TextEdit ───────────────────────────────────────────────────────────────
	var te_normal := _flat_box(BG_SURFACE, BORDER, 1, RADIUS_SM)
	te_normal.content_margin_left   = 10.0
	te_normal.content_margin_right  = 10.0
	te_normal.content_margin_top    = 8.0
	te_normal.content_margin_bottom = 8.0

	var te_focus := _flat_box(BG_SURFACE, ACCENT, 2, RADIUS_SM)
	te_focus.content_margin_left   = 10.0
	te_focus.content_margin_right  = 10.0
	te_focus.content_margin_top    = 8.0
	te_focus.content_margin_bottom = 8.0

	t.set_stylebox("normal",    "TextEdit", te_normal)
	t.set_stylebox("focus",     "TextEdit", te_focus)
	t.set_stylebox("read_only", "TextEdit", te_normal)
	t.set_color("font_color",             "TextEdit", TEXT_PRIMARY)
	t.set_color("font_placeholder_color", "TextEdit", TEXT_MUTED)
	t.set_color("selection_color",        "TextEdit", Color(ACCENT.r, ACCENT.g, ACCENT.b, 0.28))
	t.set_color("caret_color",            "TextEdit", ACCENT)

	# ── CheckBox ───────────────────────────────────────────────────────────────
	t.set_color("font_color",       "CheckBox", TEXT_PRIMARY)
	t.set_color("font_hover_color", "CheckBox", ACCENT)
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())

	# ── HSeparator / VSeparator ────────────────────────────────────────────────
	var hsep_sb := StyleBoxFlat.new()
	hsep_sb.bg_color = BORDER
	hsep_sb.content_margin_top    = 0.5
	hsep_sb.content_margin_bottom = 0.5
	t.set_stylebox("separator", "HSeparator", hsep_sb)

	var vsep_sb := StyleBoxFlat.new()
	vsep_sb.bg_color = BORDER
	vsep_sb.content_margin_left  = 0.5
	vsep_sb.content_margin_right = 0.5
	t.set_stylebox("separator", "VSeparator", vsep_sb)

	# ── ScrollContainer ────────────────────────────────────────────────────────
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

	# ── HScrollBar / VScrollBar ────────────────────────────────────────────────
	var sb_thumb := _flat_box(Color(BORDER.r - 0.06, BORDER.g - 0.06, BORDER.b - 0.06, 1.0), Color(0,0,0,0), 0, 4)
	var sb_thumb_hover := _flat_box(TEXT_MUTED, Color(0,0,0,0), 0, 4)
	var sb_scroll_bg := _flat_box(BG_PRIMARY, Color(0,0,0,0), 0, 0)
	for sbar in ["HScrollBar", "VScrollBar"]:
		t.set_stylebox("scroll",          sbar, sb_scroll_bg)
		t.set_stylebox("scroll_focus",    sbar, sb_scroll_bg)
		t.set_stylebox("grabber",         sbar, sb_thumb)
		t.set_stylebox("grabber_hover",   sbar, sb_thumb_hover)
		t.set_stylebox("grabber_pressed", sbar, sb_thumb_hover)

	return t

# ─── StyleBox Factories ────────────────────────────────────────────────────────
func _flat_box(bg: Color, border: Color, border_width: int, radius: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	return sb

# Card box: white bg, soft border, medium radius, subtle drop shadow
func _card_box(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = BORDER
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(RADIUS_MD)
	sb.shadow_color  = SHADOW_COLOR
	sb.shadow_size   = SHADOW_SIZE
	sb.shadow_offset = SHADOW_OFFSET
	return sb

# ─── Public Helpers ────────────────────────────────────────────────────────────
func priority_color(priority: String) -> Color:
	match priority:
		"A": return PRIORITY_A
		"B": return PRIORITY_B
		"C": return PRIORITY_C
		_:   return TEXT_MUTED

func style_panel(panel: PanelContainer, bg_color: Color, border_color: Color = BORDER) -> void:
	var sb := _card_box(bg_color)
	sb.border_color = border_color
	sb.content_margin_left   = 16.0
	sb.content_margin_right  = 16.0
	sb.content_margin_top    = 12.0
	sb.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", sb)

func style_button_accent(button: Button) -> void:
	var sb_n := _flat_box(ACCENT, Color(0,0,0,0), 0, RADIUS_SM)
	sb_n.content_margin_left   = 14.0
	sb_n.content_margin_right  = 14.0
	sb_n.content_margin_top    = 7.0
	sb_n.content_margin_bottom = 7.0

	var darker := Color(ACCENT.r * 0.86, ACCENT.g * 0.86, ACCENT.b * 0.86, 1.0)
	var sb_h := _flat_box(darker, Color(0,0,0,0), 0, RADIUS_SM)
	sb_h.content_margin_left   = 14.0
	sb_h.content_margin_right  = 14.0
	sb_h.content_margin_top    = 7.0
	sb_h.content_margin_bottom = 7.0

	button.add_theme_stylebox_override("normal",  sb_n)
	button.add_theme_stylebox_override("hover",   sb_h)
	button.add_theme_stylebox_override("pressed", sb_h)
	button.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",         Color.WHITE)
	button.add_theme_color_override("font_hover_color",   Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)

func style_button_outline(button: Button, color: Color = BORDER) -> void:
	var sb_n := _flat_box(BG_SURFACE, color, 1, RADIUS_SM)
	sb_n.content_margin_left   = 10.0
	sb_n.content_margin_right  = 10.0
	sb_n.content_margin_top    = 5.0
	sb_n.content_margin_bottom = 5.0

	var sb_h := _flat_box(ACCENT_LIGHT, ACCENT, 1, RADIUS_SM)
	sb_h.content_margin_left   = 10.0
	sb_h.content_margin_right  = 10.0
	sb_h.content_margin_top    = 5.0
	sb_h.content_margin_bottom = 5.0

	button.add_theme_stylebox_override("normal", sb_n)
	button.add_theme_stylebox_override("hover",  sb_h)
	button.add_theme_stylebox_override("focus",  StyleBoxEmpty.new())
	button.add_theme_color_override("font_color",       TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", ACCENT)
