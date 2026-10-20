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
			var c = MAPA[fila][col]
			if c == "#" or c == "B":
				var nodo = solido_escena.instantiate()
				nodo.position = Vector2(col + 0.5, fila + 0.5) * CELDA
				$distribucion.add_child(nodo)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
