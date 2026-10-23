extends Area2D

signal golpeo(cuerpo)

@export var duracion := 0.5
var cuerpos_golpeados: Array = []
var sfx_explosion = preload("res://sounds/Bomb Explodes.wav")
@onready var reproductor_audio = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null

func sonar(stream: AudioStream) -> void:
	if stream == null:
		return
	if reproductor_audio:
		reproductor_audio.stream = stream
		reproductor_audio.play()
	else:
		var player := AudioStreamPlayer.new()
		player.stream = stream
		player.autoplay = true
		player.finished.connect(player.queue_free)
		get_tree().root.add_child.call_deferred(player)
func preparar(tipo: String, es_punta: bool, direccion: Vector2) -> void:
	var animacion = "llama_centro"
	match tipo:
		"horizontal": 
			animacion = "llama_punta_h" if es_punta else "llama_cuerpo_h"
			if has_node("AnimatedSprite2D"):
				$AnimatedSprite2D.flip_h = es_punta and direccion == Vector2.LEFT
		"vertical":
			animacion = "llama_punta_v" if es_punta else "llama_cuerpo_v"
			if has_node("AnimatedSprite2D"):
				$AnimatedSprite2D.flip_v = es_punta and direccion == Vector2.UP
				
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play(animacion)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sonar(sfx_explosion)
	await get_tree().process_frame
	for cuerpo in get_overlapping_bodies():
		procesar_impacto(cuerpo)
		
	await get_tree().create_timer(duracion).timeout
	queue_free()

func _on_body_entered(cuerpo: Node2D) -> void:
	procesar_impacto(cuerpo)

func procesar_impacto(cuerpo: Node2D) -> void:
	# Evita aplicar daño múltiple con la misma llama
	if cuerpo in cuerpos_golpeados:
		return
		
	cuerpos_golpeados.append(cuerpo)
	golpeo.emit(cuerpo)
	
	# Daño a Bomberman
	if cuerpo.is_in_group("bomberman") and cuerpo.has_method("morir"):
		cuerpo.morir()
		
	# Daño al Jefe
	elif cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(1)
