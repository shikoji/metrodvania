extends Area2D


@export var bob_height: float = 3.0
@export var bob_speed: float = 1.0
@onready var collect_sound = $CollectSound

var size_max = 0.15
var size_speed = 5

func _ready() -> void:
	
	var start_y = position.y
	
	var tween = create_tween().set_loops()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", start_y - bob_height, bob_speed)
	tween.tween_property(self, "position:y", start_y + bob_height, bob_speed)
	


func _on_body_entered(body):
	if body is CharacterBody2D and body.name == "player":
		
		collect_sound.play()
		await get_tree().create_timer(0.2).timeout
		
		var particles = ParticleHelper.spawn_particles(position)
		var particles_material: ParticleProcessMaterial = particles.process_material
		particles_material.color = Color.RED
		
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "modulate:a", 0, 0.4)
		await tween.finished
		
		Global.potion_amount += 1
		queue_free()
