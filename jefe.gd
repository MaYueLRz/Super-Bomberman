extends CharacterBody2D
class_name Jefe

signal vida_cambio(vida)
signal derrotado

@export var velocidad = 50.0
@export var multiplicador_vertical = 0.85
@export var vida = 10
@export var tiempo_entre_ataques = 7.0
@export var explosion_escena: PackedScene = preload("res://llama.tscn")

var CELDA = 64.0

var martillo = preload("res://sounds/Bigaron's Hammer.wav")
var dano = preload("res://sounds/Enemy Dies.wav")
var victoria = preload("res://sounds/Stage Clear.wav")

var direccion_actual = Vector2.DOWN
var jugador = null

var muriendo = false
var atacando = false
var puede_recibir_dano = true

@onready var sprite = $AnimatedSprite2D
@onready var area_martillo = $AreaMartillo
@onready var colision_martillo = $AreaMartillo/CollisionShape2D
@onready var reproductor_audio = $AudioStreamPlayer2D

func _ready():
	add_to_group("jefe")
	jugador = get_tree().get_first_node_in_group("bomberman")
	
	# Atraviesa paredes
	collision_mask = 0
	desactivar_martillo(true)
	
	if area_martillo:
		area_martillo.body_entered.connect(_on_area_martillo_body_entered)
	
	sprite.play("movimiento")
	iniciar_ciclo_ataque()

func _physics_process(delta):
	if muriendo or atacando:
		return

	if jugador and is_instance_valid(jugador):
		direccion_actual = calcular_direccion()

	var vel_calculada = Vector2(
		direccion_actual.x * velocidad,
		direccion_actual.y * velocidad * multiplicador_vertical
	)
	
	global_position += vel_calculada * delta
	revisar_contacto_jugador()

func calcular_direccion():
	if jugador == null or not is_instance_valid(jugador):
		return direccion_actual

	var diff = jugador.global_position - global_position
	if abs(diff.x) > abs(diff.y):
		return Vector2(sign(diff.x), 0)
	else:
		return Vector2(0, sign(diff.y))

func revisar_contacto_jugador():
	if jugador and is_instance_valid(jugador):
		if global_position.distance_to(jugador.global_position) < 36.0:
			if jugador.has_method("morir"):
				jugador.morir()

func iniciar_ciclo_ataque():
	await get_tree().create_timer(3.0).timeout
	while not muriendo:
		if not muriendo and not atacando:
			await ejecutar_ataque()
		await get_tree().create_timer(tiempo_entre_ataques).timeout

func ejecutar_ataque():
	if muriendo:
		return
		
	atacando = true
	sprite.play("ataque")
	
	await get_tree().create_timer(0.4).timeout
	if muriendo: return
	
	sonar(martillo)
	desactivar_martillo(false)
	
	if area_martillo:
		for cuerpo in area_martillo.get_overlapping_bodies():
			if cuerpo.is_in_group("bomberman") and cuerpo.has_method("morir"):
				cuerpo.morir()
	
	await get_tree().create_timer(0.3).timeout
	if muriendo: return
	desactivar_martillo(true)

	await get_tree().create_timer(0.5).timeout
	if muriendo: return

	atacando = false
	if not muriendo:
		sprite.play("movimiento")

func desactivar_martillo(desactivado):
	if colision_martillo:
		colision_martillo.set_deferred("disabled", desactivado)

func _on_area_martillo_body_entered(body):
	if body.is_in_group("bomberman") and body.has_method("morir"):
		body.morir()

func recibir_dano(cantidad = 1):
	if not puede_recibir_dano or muriendo:
		return
		
	vida -= cantidad
	vida_cambio.emit(vida)
	puede_recibir_dano = false

	sonar(dano)

	sprite.play("muerte")
	sprite.frame = 0
	sprite.pause()

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.15)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	if vida <= 0:
		morir()
	else:
		await get_tree().create_timer(0.4).timeout
		if not muriendo:
			sprite.play("movimiento")
		await get_tree().create_timer(0.8).timeout
		if not muriendo:
			puede_recibir_dano = true

func morir():
	muriendo = true
	atacando = false
	desactivar_martillo(true)
	sprite.modulate = Color.WHITE

	sprite.sprite_frames.set_animation_loop("muerte", true)
	sprite.sprite_frames.set_animation_speed("muerte", 12.0)
	sprite.play("muerte")

	# Lluvia de explosiones
	for i in range(18):
		generar_explosion_aleatoria()
		await get_tree().create_timer(0.12).timeout

	z_index = 20
	sonar(victoria)
	
	# Zoom y desvanecimiento
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(4.5, 4.5), 1.2)
	tween.tween_property(self, "position:y", position.y + 120.0, 1.2)
	tween.tween_property(sprite, "modulate:a", 0.0, 1.2)

	await tween.finished
	derrotado.emit()
	queue_free()

func generar_explosion_aleatoria():
	if explosion_escena:
		var exp = explosion_escena.instantiate()
		var offset = Vector2(randf_range(-45.0, 45.0), randf_range(-45.0, 45.0))
		exp.position = global_position + offset
		get_parent().add_child.call_deferred(exp)

func sonar(stream):
	if reproductor_audio and stream:
		reproductor_audio.stream = stream
		reproductor_audio.play()
