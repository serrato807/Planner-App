extends VBoxContainer

func _ready() -> void:
	var title: Label = $Title
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", ThemeManager.TEXT_PRIMARY)
	var subtitle: Label = $Subtitle
	subtitle.add_theme_color_override("font_color", ThemeManager.TEXT_MUTED)
