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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	construir()

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
	pass

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
		print("bomberman se quemo") #aqui iria lo de quitar la vida
	elif cuerpo.is_in_group("jefe"):
		print("el jefe se quemo") #aqui va lo de bajarle la vida al jefe
