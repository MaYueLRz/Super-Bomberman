extends Area2D

signal golpeo(cuerpo)

@export var duracion := 0.5

func preparar(tipo: String, es_punta: bool, direccion: Vector2)->void:
	var animacion = "llama_centro"
	match tipo:
		"horizontal": 
			animacion = "llama_punta_h" if es_punta else "llama_cuerpo_h"
			$AnimatedSprite2D.flip_h = es_punta and direccion == Vector2.LEFT
		"vertical":
			animacion = "llama_punta_v" if es_punta else "llama_cuerpo_v"
			$AnimatedSprite2D.flip_v = es_punta and direccion == Vector2.UP
	$AnimatedSprite2D.play(animacion)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	await  get_tree().create_timer(duracion).timeout
	queue_free()

func _on_body_entered(cuerpo: Node2D) -> void:
	golpeo.emit(cuerpo)
