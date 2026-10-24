extends Node2D

const CELDA = 64
const MAPA = [
	"###############",
	"#.............#",
	"#.B.B.B.B.B.B.#",
	"#.............#",
	"#.B.B.B.B.B.B.#",
	"#.............#",
	"#.B.B.B.B.B.B.#",
	"#.............#",
	"#.B.B.B.B.B.B.#",
	"#.............#",
	"#.B.B.B.B.B.B.#",
	"#.............#",
	"###############",
]

var solido_escena = preload("res://bloque_solido.tscn")
var sfx_intro = preload("res://sounds/Stage Intro.wav")

const PUNTOS_GOLPE = 100
const PUNTOS_VICTORIA = 1000

var vidas = 0
var puntaje = 0
var vida_jefe = 0
var vida_jefe_max = 0
var tiempo = 0.0
var segundo_actual = 0
var terminado = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	construir()
	reproducir_audio_mapa(sfx_intro)
	$bomberman.sin_vidas.connect(_on_bomberman_sin_vidas)
	$bomberman.vidas_cambiaron.connect(_on_bomberman_vidas_cambiaron)
	$jefe.vida_cambio.connect(_on_jefe_vida_cambio)
	$jefe.derrotado.connect(_on_jefe_derrotado)
	vidas = $bomberman.vidas
	vida_jefe_max = $jefe.vida
	vida_jefe = vida_jefe_max
	$HUD/BarraJefe.max_value = vida_jefe_max
	actualizar_hud()
func reproducir_audio_mapa(stream: AudioStream):
	if stream:
		var player = AudioStreamPlayer.new()
		player.stream = stream
		add_child(player)
		player.play()
func construir():
	for fila in MAPA.size():
		for col in MAPA[fila].length():
			var caracter = MAPA[fila][col]
			if caracter == "#" or caracter == "B":
				var nodo = solido_escena.instantiate()
				nodo.position = Vector2(col + 0.5, fila + 0.5) * CELDA
				$distribucion.add_child(nodo)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if terminado:
		return
	tiempo += delta
	if int(tiempo) != segundo_actual:
		segundo_actual = int(tiempo)
		actualizar_hud()

func actualizar_hud():
	$HUD/Vidas.text = "%d" % vidas
	$HUD/Puntaje.text = "%06d" % puntaje
	$HUD/Tiempo.text = "%d:%02d" % [segundo_actual / 60, segundo_actual % 60]
	$HUD/BarraJefe.value = vida_jefe

func hay_solido (posicion: Vector2)->bool:
	var celda = Vector2i(int(posicion.x / CELDA), int(posicion.y / CELDA))
	if celda.y < 0 or celda.y >= MAPA.size():
		return true
	if celda.x < 0 or celda.x >= MAPA[celda.y].length():
		return true
	var caracter = MAPA[celda.y][celda.x]
	return caracter == "#" or caracter == "B"

func _on_llama_golpeo(cuerpo):
	if cuerpo.is_in_group("bomberman"):
		print("bomberman se quemo") 
	elif cuerpo.is_in_group("jefe"):
		print("el jefe se quemo") 

func _on_bomberman_vidas_cambiaron(v):
	vidas = v
	actualizar_hud()

func _on_jefe_vida_cambio(v):
	vida_jefe = v
	puntaje += PUNTOS_GOLPE
	actualizar_hud()

func _on_jefe_derrotado():
	if terminado:
		return
	terminado = true
	puntaje += PUNTOS_VICTORIA
	actualizar_hud()
	$HUD/PanelFinal.visible = true
	$bomberman.set_physics_process(false)

func _on_bomberman_sin_vidas() -> void:
	if terminado:
		return
	terminado = true
	$game_over.visible = true
	$bomberman.set_physics_process(false)
	for jefe in get_tree().get_nodes_in_group("jefe"):
		jefe.set_physics_process(false)
		
func _unhandled_input(evento: InputEvent) -> void:
	if terminado and evento.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
