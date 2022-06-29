extends Spatial


onready var material: SpatialMaterial = $CSGBox.material
var image: Image = null
var image_tex: ImageTexture = null

# load the SIMPLE library
const SARIEN = preload("res://gdnative/sarien.gdns")
onready var sarien = SARIEN.new()

func _ready():
	image = Image.new()
	image.create_from_data(320, 200, false, Image.FORMAT_RGB8, sarien.get_frame())

	image_tex = ImageTexture.new()
	image_tex.create_from_image(image, 0)

	material.albedo_texture = image_tex

func update_texture():
	image.create_from_data(320, 200, false, Image.FORMAT_RGB8, sarien.get_frame())
	image_tex.set_data(image)

func _process(_delta: float):
#	$CSGBox.rotate_z(delta)
	update_texture()
