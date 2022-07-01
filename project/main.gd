extends Spatial

onready var pc = $PC
onready var screen = $PC/screen
var image: Image = null
var image_tex: ImageTexture = null
var material: Material = null

# load the SIMPLE library
const SARIEN = preload("res://gdnative/sarien.gdns")
onready var sarien = SARIEN.new()

func _ready():
	image = Image.new()
	image.create_from_data(320, 200, false, Image.FORMAT_RGB8, sarien.get_frame())

	material = screen.get_surface_material(0)
	image_tex = ImageTexture.new()
	image_tex.create_from_image(image, 4)

	material.albedo_texture = image_tex

func update_texture():
	image.create_from_data(320, 200, false, Image.FORMAT_RGB8, sarien.get_frame())
	image_tex.set_data(image)

#define KEY_STATIONARY  0x4C00

#define KEY_DOWN_LEFT 0x4F00
#define KEY_DOWN_RIGHT  0x5100
#define KEY_UP_LEFT 0x4700
#define KEY_UP_RIGHT  0x4900

#define KEY_STATUSLN  0xd900
#define KEY_PRIORITY  0xda00

func _input(event):
	if event is InputEventKey and event.pressed:
		var code: int = event.scancode
		if Input.is_action_pressed("ui_accept"):
			code = 0x0D
		elif Input.is_action_pressed("ui_cancel"):
			code = 0x1B
		elif Input.is_action_pressed("ui_backspace"):
			code = 0x08
		elif Input.is_action_pressed("ui_up"):
			code = 0x4800
		elif Input.is_action_pressed("ui_down"):
			code = 0x5000
		elif Input.is_action_pressed("ui_left"):
			code = 0x4B00
		elif Input.is_action_pressed("ui_right"):
			code = 0x4D00
		sarien.key_pressed(code)

func _process(_delta: float):
#	pc.rotate_y(_delta * 0.1)
	update_texture()
