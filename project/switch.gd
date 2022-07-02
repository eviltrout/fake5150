extends Spatial

signal booting

var on:bool = false;

func switch_up():
	emit_signal("booting")

func _on_Area_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if !on:
			on = true
			$click.play()
			$AnimationPlayer.play("Turn On")

