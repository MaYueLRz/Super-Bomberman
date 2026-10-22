extends CharacterBody2D

var bomba_escena = preload("res://bomba.tscn")

const CELDA = 64.0

@export var velocidad = 400.0
@export var fuerza_centrado := 10.0
@export var ancho_mapa = 704.0  # 11 columnas × 64

var direccion_actual = Vector2.ZERO

var inicio = Vector2.ZERO
var muriendo = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D



func _ready():
	inicio = position


func _physics_process(_delta):
	direccion_actual = leer_direccion()
	velocity = direccion_actual * velocidad 
	centrar_en_el_pasillo()
	if Input.is_action_just_pressed("Place_bomb"):
		var bomba = bomba_escena.instantiate()
		bomba.position = centro_de_celda(position)
		get_parent().add_child(bomba)
	move_and_slide()
	animar()


func leer_direccion() -> Vector2:
	if Input.is_action_pressed("move_up"):
		return Vector2.UP
	if Input.is_action_pressed("move_down"):
		return Vector2.DOWN
	if Input.is_action_pressed("move_left"):
		return Vector2.LEFT
	if Input.is_action_pressed("move_right"):
		return Vector2.RIGHT
	return Vector2.ZERO

func centro_de_celda(p: Vector2) -> Vector2:
	return (p / CELDA).floor() * CELDA + Vector2(CELDA, CELDA) * 0.5

func centrar_en_el_pasillo() -> void:
	var centro := centro_de_celda(position)
	if direccion_actual.x != 0.0:
		velocity.y = clamp((centro.y - position.y) * fuerza_centrado, -velocidad, velocidad)
	elif direccion_actual.y != 0.0:
		velocity.x = clamp((centro.x - position.x) * fuerza_centrado, -velocidad, velocidad)

func animar() -> void:
	if direccion_actual == Vector2.ZERO:
		sprite.pause()
		sprite.frame = 1
		return
	var animacion := "caminar_abajo"
	if direccion_actual == Vector2.UP:
		animacion = "caminar_arriba"
	if direccion_actual == Vector2.DOWN:
		animacion = "caminar_abajo"
	if direccion_actual == Vector2.LEFT:
		animacion = "caminar_izquierda"
	if direccion_actual == Vector2.RIGHT:
		animacion = "caminar_derecha"
	if sprite.animation != animacion or not sprite.is_playing():
		sprite.play(animacion)
