extends CharacterBody2D

signal sin_vidas
signal vidas_cambiaron(vidas)

@export var velocidad = 250.0
@export var fuerza_centrado = 10.0
@export var vidas = 3
@export var bomba_escena: PackedScene = preload("res://bomba.tscn")

var CELDA = 64.0

var sfx_poner_bomba = preload("res://sounds/Place Bomb.wav")
var sfx_muerte = preload("res://sounds/Bomberman Dies.wav")
var sfx_paso = preload("res://sounds/Walking 1.wav")

var direccion_actual = Vector2.ZERO
var inicio = Vector2.ZERO
var muriendo = false
var es_invulnerable = false
var tiempo_paso = 0.0

@onready var sprite = $AnimatedSprite2D
@onready var reproductor_audio = $AudioStreamPlayer2D

func _ready():
	inicio = position
	add_to_group("bomberman")
	dar_invulnerabilidad()

func _physics_process(delta):
	if muriendo:
		return

	direccion_actual = leer_direccion()
	velocity = direccion_actual * velocidad 
	centrar_en_el_pasillo()

	if Input.is_action_just_pressed("Place_bomb") or Input.is_action_just_pressed("ui_accept"):
		poner_bomba()

	move_and_slide()
	animar()

	# Control de pasos
	if velocity != Vector2.ZERO:
		tiempo_paso += delta
		if tiempo_paso >= 0.25:
			sonar(sfx_paso)
			tiempo_paso = 0.0
	else:
		tiempo_paso = 0.0

func leer_direccion():
	if Input.is_action_pressed("move_up") or Input.is_action_pressed("ui_up"):
		return Vector2.UP
	if Input.is_action_pressed("move_down") or Input.is_action_pressed("ui_down"):
		return Vector2.DOWN
	if Input.is_action_pressed("move_left") or Input.is_action_pressed("ui_left"):
		return Vector2.LEFT
	if Input.is_action_pressed("move_right") or Input.is_action_pressed("ui_right"):
		return Vector2.RIGHT
	return Vector2.ZERO

func centro_de_celda(p):
	return (p / CELDA).floor() * CELDA + Vector2(CELDA, CELDA) * 0.5

func centrar_en_el_pasillo():
	var centro = centro_de_celda(position)
	var vel_ajuste = velocidad * 0.35
	if direccion_actual.x != 0.0:
		velocity.y = clamp((centro.y - position.y) * fuerza_centrado, -vel_ajuste, vel_ajuste)
	elif direccion_actual.y != 0.0:
		velocity.x = clamp((centro.x - position.x) * fuerza_centrado, -vel_ajuste, vel_ajuste)

func poner_bomba():
	if bomba_escena:
		var bomba = bomba_escena.instantiate()
		bomba.position = centro_de_celda(position)
		get_parent().add_child.call_deferred(bomba)
		sonar(sfx_poner_bomba)

func animar():
	if direccion_actual == Vector2.ZERO:
		sprite.play("quieto")
		return
		
	var animacion = "caminar_abajo"
	if direccion_actual == Vector2.UP:
		animacion = "caminar_arriba"
	elif direccion_actual == Vector2.DOWN:
		animacion = "caminar_abajo"
	elif direccion_actual == Vector2.LEFT:
		animacion = "caminar_izquierda"
	elif direccion_actual == Vector2.RIGHT:
		animacion = "caminar_derecha"
		
	if sprite.animation != animacion or not sprite.is_playing():
		sprite.play(animacion)

func recibir_dano():
	morir()

func morir():
	if muriendo or es_invulnerable:
		return

	muriendo = true
	vidas -= 1
	vidas_cambiaron.emit(vidas)
	velocity = Vector2.ZERO
	direccion_actual = Vector2.ZERO

	sonar(sfx_muerte)
	sprite.modulate = Color.WHITE

	sprite.play("morir")
	await sprite.animation_finished

	if vidas > 0:
		reaparecer()
	else:
		sin_vidas.emit()

func reaparecer():
	position = inicio
	velocity = Vector2.ZERO
	direccion_actual = Vector2.ZERO
	muriendo = false
	sprite.play("quieto")
	dar_invulnerabilidad()

func dar_invulnerabilidad():
	es_invulnerable = true
	
	var tween = create_tween().set_loops(3)
	tween.tween_property(sprite, "modulate:a", 0.3, 0.2)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.2)
	
	await tween.finished
	sprite.modulate = Color.WHITE
	es_invulnerable = false

func celebrar_victoria():
	muriendo = true
	velocity = Vector2.ZERO
	sprite.play("gana")

func sonar(stream):
	if reproductor_audio and stream:
		reproductor_audio.stream = stream
		reproductor_audio.play()
