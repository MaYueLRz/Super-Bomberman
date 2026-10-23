extends CharacterBody2D

var bomba_escena = preload("res://bomba.tscn")
var sfx_poner_bomba = preload("res://sounds/Place Bomb.wav")
var sfx_muerte = preload("res://sounds/Bomberman Dies.wav")
var sfx_paso = preload("res://sounds/Walking 1.wav")
var tiempo_paso := 0.0
const CELDA = 64.0

@export var velocidad = 250.0
@export var fuerza_centrado := 10.0
@export var vidas: int = 3

var direccion_actual = Vector2.ZERO
var inicio = Vector2.ZERO
var muriendo = false
var es_invulnerable = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var reproductor_audio = $AudioStreamPlayer2D if has_node("AudioStreamPlayer2D") else null
func _ready():
	inicio = position
	add_to_group("bomberman")
	dar_invulnerabilidad()
func sonar(stream: AudioStream):
	if stream:
		if reproductor_audio:
			reproductor_audio.stream = stream
			reproductor_audio.play()
		else:
			var player = AudioStreamPlayer.new()
			player.stream = stream
			get_tree().root.add_child(player)
			player.play()
			player.finished.connect(player.queue_free)
func _physics_process(_delta):
	if muriendo:
		return
	
	direccion_actual = leer_direccion()
	velocity = direccion_actual * velocidad 
	centrar_en_el_pasillo()

	if Input.is_action_just_pressed("Place_bomb") or Input.is_action_just_pressed("ui_accept"):
		poner_bomba()

	move_and_slide()
	animar()

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
	if direccion_actual.x != 0.0:
		velocity.y = clamp((centro.y - position.y) * fuerza_centrado, -velocidad, velocidad)
	elif direccion_actual.y != 0.0:
		velocity.x = clamp((centro.x - position.x) * fuerza_centrado, -velocidad, velocidad)

func poner_bomba() -> void:
	if bomba_escena:
		var bomba = bomba_escena.instantiate()
		bomba.position = centro_de_celda(position)
		get_parent().add_child(bomba)
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

func recibir_dano():
	morir()

func morir() -> void:
	if muriendo or es_invulnerable:
		return
	
	muriendo = true
	vidas -= 1
	velocity = Vector2.ZERO
	direccion_actual = Vector2.ZERO
	print("¡Bomberman fue alcanzado! Vidas restantes: ", vidas)
	sonar(sfx_muerte)
	# Opacidad normal para ver la animación
	sprite.modulate = Color.WHITE

	# Reproducir la animación 'morir' que está en tu editor
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("morir"):
		sprite.play("morir")
		await sprite.animation_finished
	else:
		await get_tree().create_timer(0.8).timeout

	if vidas > 0:
		reaparecer()
	else:
		print("¡GAME OVER!")

func reaparecer() -> void:
	position = inicio
	velocity = Vector2.ZERO
	direccion_actual = Vector2.ZERO
	muriendo = false
	
	# Colocar estado quieto al reaparecer
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
