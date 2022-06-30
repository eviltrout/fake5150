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
	image_tex.create_from_image(image, 0)

	material.albedo_texture = image_tex

func update_texture():
	image.create_from_data(320, 200, false, Image.FORMAT_RGB8, sarien.get_frame())
	image_tex.set_data(image)

func _process(delta: float):
	pc.rotate_y(delta * 0.1)
	update_texture()
