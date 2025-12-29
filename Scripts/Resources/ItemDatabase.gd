# ItemDatabase.gd
extends Node

# DICCIONARIO MAESTRO: Aquí registras TODOS los items de tu juego.
# La clave es el ID que guardaremos en la BD.
# El valor es la ruta al archivo .tres
var db = {
	"iron_boots": preload("res://Resources/Data/items/IronBoots.tres")
	# ... AGREGA AQUÍ TODOS LOS ITEMS ...
}

func get_item_by_id(id: String) -> ItemData:
	if db.has(id):
		return db[id]
	return null

func get_id_by_item(item: ItemData) -> String:
	# Buscamos qué ID corresponde a este recurso
	for key in db:
		if db[key] == item:
			return key
	return ""
