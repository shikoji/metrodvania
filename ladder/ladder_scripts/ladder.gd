extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Player:
		body.ladders_touching += 1
		body.on_ladder = true

func _on_body_exited(body):
	if body is Player:
		body.ladders_touching -= 1

		if body.ladders_touching <= 0:
			body.ladders_touching = 0
			body.on_ladder = false
			body.climbing = false
