extends Area2D

const CELDA = 64.0

@export var rango := 6
@export var mecha := 2.0

var llama_escena = preload("res://llama.tscn")

func _ready() -> void:
	$AnimatedSprite2D.play("bomba") 
	await get_tree().create_timer(mecha).timeout
	explotar()

func explotar() -> void:
	var mapa = get_tree().get_first_node_in_group("mapa")
	
	crear_llama(position, "centro", false, Vector2.ZERO, mapa)

	for direccion in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
		for paso in range(1, rango + 1):
			var destino = position + direccion * CELDA * paso
			if mapa.hay_solido(destino):
				break
			var siguiente = destino + direccion * CELDA
			var es_punta = paso == rango or mapa.hay_solido(siguiente)
			var tipo = "horizontal" if direccion.x != 0 else "vertical"
			crear_llama(destino, tipo, es_punta, direccion, mapa)

	queue_free()


func crear_llama(destino: Vector2, tipo: String, es_punta: bool, direccion: Vector2, mapa) -> void:
	var llama = llama_escena.instantiate()
	llama.position = destino
	llama.preparar(tipo, es_punta, direccion)
	llama.golpeo.connect(mapa._on_llama_golpeo)
	mapa.add_child(llama)


func _process(delta: float) -> void:
	pass
