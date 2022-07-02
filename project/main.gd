extends Spatial

onready var pc = $PC
onready var screen = $PC/screen
var image: Image = null
var image_tex: ImageTexture = null
var material: Material = null
var started_sarien: bool = false

onready var camera = $Camera

# load the SIMPLE library
const SARIEN = preload("res://gdnative/sarien.gdns")
onready var sarien

const TURN_SPEED = 2.0
const ZOOM_SPEED = 2.0
const ZOOM_FRICTION = 0.9

var ang: float = PI/2
var rad: float = 3.0
var zoom_speed: float = 0.0

var panning: bool = false
var panning_from: Vector2
var panning_from_ang: float

func start_sarien():
	sarien = SARIEN.new()
	started_sarien = true
	image = Image.new()
	image.create_from_data(320, 200, false, Image.FORMAT_RGB8, sarien.get_frame())

	material = screen.get_surface_material(0)
	image_tex = ImageTexture.new()
	image_tex.create_from_image(image, 4)
	material.set_shader_param("texture_albedo", image_tex)

func update_texture():
	if started_sarien:
		image.create_from_data(320, 200, false, Image.FORMAT_RGB8, sarien.get_frame())
		image_tex.set_data(image)

func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()

	if event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP && event.pressed:
			zoom_speed -= ZOOM_SPEED

		if event.button_index == BUTTON_WHEEL_DOWN && event.pressed:
			zoom_speed += ZOOM_SPEED

		if event.button_index == BUTTON_MIDDLE:
			panning = event.pressed
			panning_from_ang = ang
			panning_from = get_viewport().get_mouse_position()


	if started_sarien:
		if event is InputEventKey and event.pressed:
			var code: int = event.scancode
			if Input.is_action_pressed("ui_accept"):
				code = 0x0D
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

func _process(delta: float):
	camera.global_transform.origin = Vector3(
		rad * cos(ang), 0.85, rad * sin(ang)
	)
	camera.look_at(Vector3(0, 0.65, 0.0), Vector3.UP)

	rad += (zoom_speed * delta)
	zoom_speed *= ZOOM_FRICTION
	if abs(zoom_speed) < 0.05:
		zoom_speed = 0.0

	if rad < 1.1:
		rad = 1.1

	if panning:
		var diff = (get_viewport().get_mouse_position() - panning_from) / get_viewport().size
		ang = (panning_from_ang + (diff.x * TURN_SPEED))


	update_texture()
