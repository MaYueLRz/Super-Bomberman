extends CharacterBody2D
class_name Jefe

const CELDA = 64.0

@export var velocidad = 50.0
@export var vida = 5
@export var fuerza_centrado = 10.0
@export var tiempo_entre_ataques = 7.0
@export var explosion_escena: PackedScene = preload("res://llama.tscn")

var direccion_actual = Vector2.DOWN
var jugador: Node2D = null

var muriendo = false
var atacando = false
var puede_recibir_dano = true

@onready var sprite = $AnimatedSprite2D
@onready var area_martillo = $AreaMartillo if has_node("AreaMartillo") else null
@onready var colision_martillo = $AreaMartillo/CollisionShape2D if has_node("AreaMartillo/CollisionShape2D") else null

func _ready():
	add_to_group("jefe")
	jugador = get_tree().get_first_node_in_group("bomberman")
	
	if jugador == null:
		print("⚠️ ALERTA: No se encontró al personaje en el grupo 'bomberman'.")

	if colision_martillo:
		colision_martillo.disabled = true
	if area_martillo and not area_martillo.body_entered.is_connected(_on_area_martillo_body_entered):
		area_martillo.body_entered.connect(_on_area_martillo_body_entered)
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("movimiento"):
		sprite.play("movimiento")
	
	iniciar_ciclo_ataque()

func _physics_process(_delta):
	if muriendo or atacando:
		return

	if jugador and is_instance_valid(jugador):
		direccion_actual = calcular_direccion()

	velocity = direccion_actual * velocidad
	centrar_en_el_pasillo()
	move_and_slide()

	if is_on_wall():
		desviar_por_muro()

	revisar_contacto_jugador()

func calcular_direccion() -> Vector2:
	var diff = jugador.global_position - global_position
	if abs(diff.x) > abs(diff.y):
		return Vector2(sign(diff.x), 0)
	else:
		return Vector2(0, sign(diff.y))

func desviar_por_muro():
	if jugador == null:
		return
	var diff = jugador.global_position - global_position
	if direccion_actual.x != 0:
		var dir_y = sign(diff.y) if diff.y != 0 else 1.0
		direccion_actual = Vector2(0, dir_y)
	else:
		var dir_x = sign(diff.x) if diff.x != 0 else 1.0
		direccion_actual = Vector2(dir_x, 0)

func centro_de_celda(p: Vector2) -> Vector2:
	return (p / CELDA).floor() * CELDA + Vector2(CELDA, CELDA) * 0.5

func centrar_en_el_pasillo():
	var centro = centro_de_celda(position)
	if direccion_actual.x != 0.0:
		velocity.y = clamp((centro.y - position.y) * fuerza_centrado, -velocidad, velocidad)
	elif direccion_actual.y != 0.0:
		velocity.x = clamp((centro.x - position.x) * fuerza_centrado, -velocidad, velocidad)

func revisar_contacto_jugador():
	for i in get_slide_collision_count():
		var colision = get_slide_collision(i)
		var cuerpo = colision.get_collider()
		if cuerpo and cuerpo.is_in_group("bomberman"):
			if cuerpo.has_method("morir"):
				cuerpo.morir()

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
	velocity = Vector2.ZERO

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("ataque"):
		sprite.play("ataque")
		
		await get_tree().create_timer(0.4).timeout
		if muriendo: return
		
		if colision_martillo:
			colision_martillo.disabled = false
		
		if area_martillo:
			for cuerpo in area_martillo.get_overlapping_bodies():
				if cuerpo.is_in_group("bomberman") and cuerpo.has_method("morir"):
					cuerpo.morir()
		
		await get_tree().create_timer(0.3).timeout
		if muriendo: return
		
		if colision_martillo:
			colision_martillo.disabled = true

		await get_tree().create_timer(0.5).timeout
		if muriendo: return

	atacando = false
	if not muriendo and sprite.sprite_frames and sprite.sprite_frames.has_animation("movimiento"):
		sprite.play("movimiento")

func recibir_dano(cantidad = 1):
	if not puede_recibir_dano or muriendo:
		return
		
	vida -= cantidad
	puede_recibir_dano = false
	print("Vida del jefe: ", vida)

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("muerte"):
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
		if not muriendo and sprite.sprite_frames and sprite.sprite_frames.has_animation("movimiento"):
			sprite.play("movimiento")
		await get_tree().create_timer(0.8).timeout
		if not muriendo:
			puede_recibir_dano = true

func morir():
	muriendo = true
	atacando = false
	velocity = Vector2.ZERO
	
	if colision_martillo:
		colision_martillo.disabled = true

	sprite.modulate = Color.WHITE

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("muerte"):
		sprite.sprite_frames.set_animation_loop("muerte", true)
		sprite.sprite_frames.set_animation_speed("muerte", 12.0)
		sprite.play("muerte")

	# FASE 1: Lluvia de explosiones aleatorias sobre el jefe
	var tiempo_explosiones := 2.2
	var tiempo_acumulado := 0.0
	while tiempo_acumulado < tiempo_explosiones:
		generar_explosion_aleatoria()
		await get_tree().create_timer(0.12).timeout
		tiempo_acumulado += 0.12

	# FASE 2: Zoom gigante acercándose a la pantalla estilo SNES
	z_index = 20
	var duracion_zoom := 1.2
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(self, "scale", Vector2(4.5, 4.5), duracion_zoom).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y + 120.0, duracion_zoom)
	tween.tween_property(sprite, "modulate:a", 0.0, duracion_zoom).set_delay(0.5)

	for i in range(8):
		generar_explosion_aleatoria()
		await get_tree().create_timer(0.1).timeout

	await tween.finished
	queue_free()

func generar_explosion_aleatoria():
	if explosion_escena:
		var exp = explosion_escena.instantiate()
		var offset = Vector2(randf_range(-45.0, 45.0), randf_range(-45.0, 45.0))
		exp.position = global_position + offset
		get_parent().add_child(exp)

func _on_area_martillo_body_entered(body: Node2D) -> void:
	if body.is_in_group("bomberman") and body.has_method("morir"):
		body.morir()
