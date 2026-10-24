extends Area2D

signal golpeo(cuerpo)

@export var duracion = 0.5

var sfx_explosion = preload("res://sounds/Bomb Explodes.wav")
var cuerpos_golpeados = []

@onready var sprite = $AnimatedSprite2D
@onready var reproductor_audio = $AudioStreamPlayer2D

func _ready():
	body_entered.connect(_on_body_entered)
	sonar(sfx_explosion)
	
	# Detecta cuerpos que ya estaban dentro al instanciar la llama
	await get_tree().process_frame
	for cuerpo in get_overlapping_bodies():
		procesar_impacto(cuerpo)
		
	await get_tree().create_timer(duracion).timeout
	queue_free()

func preparar(tipo, es_punta, direccion):
	var animacion = "llama_centro"
	
	match tipo:
		"horizontal":
			animacion = "llama_punta_h" if es_punta else "llama_cuerpo_h"
			if sprite:
				sprite.flip_h = es_punta and direccion == Vector2.LEFT
		"vertical":
			animacion = "llama_punta_v" if es_punta else "llama_cuerpo_v"
			if sprite:
				sprite.flip_v = es_punta and direccion == Vector2.UP
				
	if sprite:
		sprite.play(animacion)

func _on_body_entered(cuerpo):
	procesar_impacto(cuerpo)

func procesar_impacto(cuerpo):
	if cuerpo in cuerpos_golpeados:
		return
		
	cuerpos_golpeados.append(cuerpo)
	golpeo.emit(cuerpo)
	
	if cuerpo.is_in_group("bomberman") and cuerpo.has_method("morir"):
		cuerpo.morir()
	elif cuerpo.has_method("recibir_dano"):
		cuerpo.recibir_dano(1)

func sonar(stream):
	if reproductor_audio and stream:
		reproductor_audio.stream = stream
		reproductor_audio.play()
