extends CanvasLayer

const TOP_LEFT_FONT := preload("res://examples_dd3d/Minecraft - by BennyFonts1002 - from fontstruct.ttf")
const TOP_LEFT_COLOR := Color("7df9ff")
const TOP_LEFT_FONT_SIZE := 20


func _ready() -> void:
	_apply_debug_draw_style()
	_style_descendants(self)
	child_entered_tree.connect(_on_child_entered_tree)


func _on_child_entered_tree(node: Node) -> void:
	_style_descendants(node)


func _style_descendants(node: Node) -> void:
	_apply_style(node)
	for child in node.get_children():
		_style_descendants(child)


func _apply_debug_draw_style() -> void:
	DebugDraw2D.config.text_default_size = TOP_LEFT_FONT_SIZE
	DebugDraw2D.config.text_foreground_color = TOP_LEFT_COLOR
	DebugDraw2D.config.text_custom_font = TOP_LEFT_FONT


func _apply_style(node: Node) -> void:
	if node is Label3D:
		node.font = TOP_LEFT_FONT
		node.font_size = TOP_LEFT_FONT_SIZE
		node.modulate = TOP_LEFT_COLOR
	elif node is Label:
		node.add_theme_font_override("font", TOP_LEFT_FONT)
		node.add_theme_font_size_override("font_size", TOP_LEFT_FONT_SIZE)
		node.add_theme_color_override("font_color", TOP_LEFT_COLOR)
