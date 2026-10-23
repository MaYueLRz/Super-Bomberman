extends CharacterBody2D

signal sin_vidas
signal vidas_cambiaron(vidas)

# ==========================================
# 1. CONSTANTES Y CONFIGURACIÓN
# ==========================================
const CELDA: float = 64.0

@export_group("Parámetros de Bomberman")
@export var velocidad: float = 250.0
@export var fuerza_centrado: float = 10.0
@export var vidas: int = 3


@export_group("Escenas Recurso")
@export var bomba_escena: PackedScene = preload("res://bomba.tscn")

# ==========================================
# 2. RECURSOS DE AUDIO (SFX)
# ==========================================
var sfx_poner_bomba = preload("res://sounds/Place Bomb.wav")
var sfx_muerte = preload("res://sounds/Bomberman Dies.wav")
var sfx_paso = preload("res://sounds/Walking 1.wav")

# ==========================================
# 3. VARIABLES DE ESTADO Y CONTROL
# ==========================================
var direccion_actual: Vector2 = Vector2.ZERO
var inicio: Vector2 = Vector2.ZERO
var muriendo: bool = false
var es_invulnerable: bool = false
var tiempo_paso: float = 0.0

# ==========================================
# 4. REFERENCIAS A NODOS DE LA ESCENA
# ==========================================
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var reproductor_audio: AudioStreamPlayer2D = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null


# ==========================================
# 5. CICLO DE VIDA DEL NODO
# ==========================================
func _ready() -> void:
	inicio = position
	add_to_group("bomberman")
	dar_invulnerabilidad()

func _physics_process(_delta: float) -> void:
	if muriendo:
		return

	# Lectura de controles y velocidad
	direccion_actual = leer_direccion()
	velocity = direccion_actual * velocidad 
	centrar_en_el_pasillo()

	# Colocar bomba
	if Input.is_action_just_pressed("Place_bomb") or Input.is_action_just_pressed("ui_accept"):
		poner_bomba()

	move_and_slide()
	animar()

	# Lógica de sonido de pasos
	if velocity != Vector2.ZERO:
		tiempo_paso += _delta
		if tiempo_paso >= 0.25:
			sonar(sfx_paso)
			tiempo_paso = 0.0
	else:
		tiempo_paso = 0.0


# ==========================================
# 6. MOVIMIENTO Y NAVEGACIÓN
# ==========================================
func leer_direccion() -> Vector2:
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		return Vector2.UP
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		return Vector2.DOWN
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		return Vector2.LEFT
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		return Vector2.RIGHT
	return Vector2.ZERO

func centro_de_celda(p: Vector2) -> Vector2:
	return (p / CELDA).floor() * CELDA + Vector2(CELDA, CELDA) * 0.5

func centrar_en_el_pasillo() -> void:
	var centro := centro_de_celda(position)
	var vel_ajuste := velocidad * 0.35
	if direccion_actual.x != 0.0:
		velocity.y = clamp((centro.y - position.y) * fuerza_centrado, -vel_ajuste, vel_ajuste)
	elif direccion_actual.y != 0.0:
		velocity.x = clamp((centro.x - position.x) * fuerza_centrado, -vel_ajuste, vel_ajuste)


# ==========================================
# 7. MECÁNICAS DE JUEGO (BOMBAS Y ANIMACIÓN)
# ==========================================
func poner_bomba() -> void:
	if bomba_escena:
		var bomba = bomba_escena.instantiate()
		bomba.position = centro_de_celda(position)
		get_parent().add_child.call_deferred(bomba)
		sonar(sfx_poner_bomba)

func animar() -> void:
	if direccion_actual == Vector2.ZERO:
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("quieto"):
			sprite.play("quieto")
		else:
			sprite.pause()
			sprite.frame = 1
		return
		
	var animacion := "caminar_abajo"
	if direccion_actual == Vector2.UP:
		animacion = "caminar_arriba"
	elif direccion_actual == Vector2.DOWN:
		animacion = "caminar_abajo"
	elif direccion_actual == Vector2.LEFT:
		animacion = "caminar_izquierda"
	elif direccion_actual == Vector2.RIGHT:
		animacion = "caminar_derecha"
		
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animacion):
		if sprite.animation != animacion or not sprite.is_playing():
			sprite.play(animacion)


# ==========================================
# 8. SISTEMA DE SALUD Y REAPARICIÓN
# ==========================================
func recibir_dano() -> void:
	morir()

func morir() -> void:
	if muriendo or es_invulnerable:
		return

	muriendo = true
	vidas -= 1
	vidas_cambiaron.emit(vidas)
	velocity = Vector2.ZERO
	direccion_actual = Vector2.ZERO

	sonar(sfx_muerte)
	sprite.modulate = Color.WHITE

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("morir"):
		sprite.play("morir")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.8).timeout

	if vidas > 0:
		reaparecer()
	else:
		sin_vidas.emit()

func reaparecer() -> void:
	position = inicio
	velocity = Vector2.ZERO
	direccion_actual = Vector2.ZERO
	muriendo = false
	
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("quieto"):
		sprite.play("quieto")
	elif sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("caminar_abajo"):
		sprite.play("caminar_abajo")
		sprite.frame = 1
		sprite.pause()
		
	dar_invulnerabilidad()

func dar_invulnerabilidad() -> void:
	es_invulnerable = true
	
	var tween = create_tween().set_loops(3)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.2)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
	
	await tween.finished
	if sprite:
		sprite.modulate = Color.WHITE
	es_invulnerable = false


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
