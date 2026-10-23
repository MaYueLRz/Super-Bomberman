extends CharacterBody2D
class_name Jefe

# ==========================================
# 1. CONSTANTES Y CONFIGURACIÓN
# ==========================================
const CELDA: float = 64.0

@export_group("Parámetros del Jefe")
@export var velocidad: float = 50.0
@export var multiplicador_vertical: float = 0.85
@export var vida: int = 10
@export var tiempo_entre_ataques: float = 7.0

@export_group("Escenas Recurso")
@export var explosion_escena: PackedScene = preload("res://llama.tscn")

# ==========================================
# 2. RECURSOS DE AUDIO (SFX)
# ==========================================
var sfx_martillo = preload("res://sounds/Bigaron's Hammer.wav")
var sfx_dano = preload("res://sounds/Enemy Dies.wav")
var sfx_victoria = preload("res://sounds/Stage Clear.wav")

# ==========================================
# 3. VARIABLES DE ESTADO Y CONTROL
# ==========================================
var direccion_actual: Vector2 = Vector2.DOWN
var jugador: Node2D = null

var muriendo: bool = false
var atacando: bool = false
var puede_recibir_dano: bool = true

# ==========================================
# 4. REFERENCIAS A NODOS DE LA ESCENA
# ==========================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_martillo: Area2D = $AreaMartillo if has_node("AreaMartillo") else null
@onready var colision_martillo: CollisionShape2D = $AreaMartillo/CollisionShape2D if has_node("AreaMartillo/CollisionShape2D") else null
@onready var reproductor_audio: AudioStreamPlayer2D = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null


# ==========================================
# 5. CICLO DE VIDA DEL NODO
# ==========================================
func _ready() -> void:
	add_to_group("jefe")
	jugador = get_tree().get_first_node_in_group("bomberman")
	
	if jugador == null:
		print("⚠️ ALERTA: No se encontró al personaje en el grupo 'bomberman'.")

	# Ignorar paredes
	collision_mask = 0

	# Desactivar colisión de forma diferida segura
	desactivar_martillo(true)
	
	if area_martillo and not area_martillo.body_entered.is_connected(_on_area_martillo_body_entered):
		area_martillo.body_entered.connect(_on_area_martillo_body_entered)
	
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("movimiento"):
		sprite.play("movimiento")
	
	iniciar_ciclo_ataque()

func _physics_process(delta: float) -> void:
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


# ==========================================
# 6. MOVIMIENTO DIRECTO
# ==========================================
func calcular_direccion() -> Vector2:
	if jugador == null or not is_instance_valid(jugador):
		return direccion_actual

	var diff = jugador.global_position - global_position
	
	if abs(diff.x) > abs(diff.y):
		return Vector2(sign(diff.x), 0)
	else:
		return Vector2(0, sign(diff.y))

func revisar_contacto_jugador() -> void:
	if jugador and is_instance_valid(jugador):
		if global_position.distance_to(jugador.global_position) < 36.0:
			if jugador.has_method("morir"):
				jugador.morir()


# ==========================================
# 7. SISTEMA DE ATAQUE (MARTILLO)
# ==========================================
func iniciar_ciclo_ataque() -> void:
	await get_tree().create_timer(3.0).timeout
	while not muriendo:
		if not muriendo and not atacando:
			await ejecutar_ataque()
		await get_tree().create_timer(tiempo_entre_ataques).timeout

func ejecutar_ataque() -> void:
	if muriendo:
		return
		
	atacando = true
	velocity = Vector2.ZERO

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("ataque"):
		sprite.play("ataque")
		
		await get_tree().create_timer(0.4).timeout
		if muriendo: return
		
		sonar(sfx_martillo)
		desactivar_martillo(false) # Activar colisión
		
		if area_martillo:
			for cuerpo in area_martillo.get_overlapping_bodies():
				if cuerpo.is_in_group("bomberman") and cuerpo.has_method("morir"):
					cuerpo.morir()
		
		await get_tree().create_timer(0.3).timeout
		if muriendo: return
		desactivar_martillo(true) # Desactivar colisión

		await get_tree().create_timer(0.5).timeout
		if muriendo: return

	atacando = false
	if not muriendo and sprite.sprite_frames and sprite.sprite_frames.has_animation("movimiento"):
		sprite.play("movimiento")

func desactivar_martillo(desactivado: bool) -> void:
	if colision_martillo:
		colision_martillo.set_deferred("disabled", desactivado)

func _on_area_martillo_body_entered(body: Node2D) -> void:
	if body.is_in_group("bomberman") and body.has_method("morir"):
		body.morir()


# ==========================================
# 8. DAÑO Y MUERTE
# ==========================================
func recibir_dano(cantidad: int = 1) -> void:
	if not puede_recibir_dano or muriendo:
		return
		
	vida -= cantidad
	puede_recibir_dano = false
	print("Vida del jefe: ", vida)

	sonar(sfx_dano)

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

func morir() -> void:
	muriendo = true
	atacando = false
	velocity = Vector2.ZERO
	
	desactivar_martillo(true)

	sprite.modulate = Color.WHITE

	if sprite.sprite_frames and sprite.sprite_frames.has_animation("muerte"):
		sprite.sprite_frames.set_animation_loop("muerte", true)
		sprite.sprite_frames.set_animation_speed("muerte", 12.0)
		sprite.play("muerte")

	var tiempo_explosiones := 2.2
	var tiempo_acumulado := 0.0
	while tiempo_acumulado < tiempo_explosiones:
		generar_explosion_aleatoria()
		await get_tree().create_timer(0.12).timeout
		tiempo_acumulado += 0.12

	z_index = 20
	sonar(sfx_victoria)
	
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

func generar_explosion_aleatoria() -> void:
	if explosion_escena:
		var instancia_exp = explosion_escena.instantiate()
		var offset = Vector2(randf_range(-45.0, 45.0), randf_range(-45.0, 45.0))
		instancia_exp.position = global_position + offset
		get_parent().add_child.call_deferred(instancia_exp)


# ==========================================
# 9. REPRODUCTOR DE AUDIO SEGURO
# ==========================================
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
