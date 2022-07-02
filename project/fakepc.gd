extends Spatial

signal booted

func _ready():
	$AnimationPlayer.play("RESET")

func _on_switch_booting():
	$AnimationPlayer.play("Boot")
	$BootSound.play()

func emit_booted():
	emit_signal("booted")
