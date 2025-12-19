# PlayerData.gd (Autoload)
extends Node

const DB_NAME = "res://User_Data/inventory.db" # Ruta en editor
const DB_PATH = "user://inventory.db"          # Ruta en PC del usuario

var db: SQLite = null
var global_inventory: Array[Resource] = []
var heroes_data = {}

const SLOTS = [
	"helmet", "amulet", "chest", "gloves", 
	"bracelet", "left_ring", "right_ring", 
	"belt", "pants", "boots","left_weapon", "right_weapon"
]

func _ready():
	# 1. Configurar Base de Datos
	db = SQLite.new()
	db.path = DB_PATH
	
	# Mover la BD de la carpeta res:// a user:// si es la primera vez
	# (godot-sqlite suele requerir esto para escribir)
	# Nota: Si el plugin no lo hace auto, simplemente creamos una nueva.
	
	db.open_db()
	
	# 2. Crear Tablas si no existen (Magia de SQL)
	var table_inv = {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true},
		"item_id": {"data_type": "text"} # Aquí guardamos "iron_sword"
	}
	db.create_table("global_inventory", table_inv)
	
	var table_hero = {
		"id": {"data_type": "int", "primary_key": true, "auto_increment": true},
		"hero_id": {"data_type": "text"}, # "BlackDragon"
		"slot": {"data_type": "text"},    # "helmet"
		"item_id": {"data_type": "text"}  # "iron_helmet"
	}
	db.create_table("hero_equipment", table_hero)
	
	# 3. Inicializar memoria
	initialize_heroes_memory()
	
	# 4. Cargar datos
	load_data_from_db()

func initialize_heroes_memory():
	# Estructura en RAM para que el juego funcione rápido
	var ids = ["BlackDragon", "MaleViking", "MaleKnight"]
	for h_id in ids:
		heroes_data[h_id] = {"inventory": {}}
		for slot in SLOTS:
			heroes_data[h_id]["inventory"][slot] = null

# --- LÓGICA DE GUARDADO INSTANTÁNEO (SQL) ---

func add_item_to_bag(item: ItemData):
	if item == null: return
	
	# 1. Añadir a RAM
	global_inventory.append(item)
	
	# 2. Añadir a SQL (INSERT)
	var text_id = ItemDatabase.get_id_by_item(item)
	if text_id != "":
		var row = {"item_id": text_id}
		db.insert_row("global_inventory", row)
		print("Guardado en BD: ", text_id)
	else:
		print("ERROR: El item ", item.name, " no está registrado en ItemDatabase.gd")

func equip_item_from_bag(hero_id, slot, item):
	# Validaciones básicas
	var item_real = item
	if item is dropData: item_real = item.item_data
	if item_real == null: return
	
	# 1. Lógica en RAM (Intercambio visual)
	var current_item = heroes_data[hero_id]["inventory"].get(slot)
	
	# Sacar item actual (si existe) -> A la bolsa
	if current_item:
		add_item_to_bag(current_item) # Esto ya guarda en SQL el item viejo
		
	# Poner item nuevo -> Al héroe
	heroes_data[hero_id]["inventory"][slot] = item_real
	
	# Quitar item nuevo de la bolsa global
	remove_item_from_bag_memory(item_real)
	
	# 2. GUARDAR EQUIPAMIENTO EN SQL (Upsert/Replace)
	var item_text_id = ItemDatabase.get_id_by_item(item_real)
	
	# Borrar lo que había en ese slot en la BD para ese héroe
	var query = "DELETE FROM hero_equipment WHERE hero_id='" + hero_id + "' AND slot='" + slot + "';"
	db.query(query)
	
	# Insertar lo nuevo
	var row = {
		"hero_id": hero_id,
		"slot": slot,
		"item_id": item_text_id
	}
	db.insert_row("hero_equipment", row)

func unequip_item(hero_id, slot):
	var item = heroes_data[hero_id]["inventory"].get(slot)
	if item:
		# 1. Mover a la bolsa (SQL Insert automático)
		add_item_to_bag(item)
		
		# 2. Quitar del héroe en RAM
		heroes_data[hero_id]["inventory"][slot] = null
		
		# 3. Quitar del héroe en SQL
		var query = "DELETE FROM hero_equipment WHERE hero_id='" + hero_id + "' AND slot='" + slot + "';"
		db.query(query)

# Función auxiliar para borrar de la bolsa SOLO en SQL y RAM (sin añadir nada)
func remove_item_from_bag_memory(item: ItemData):
	if item in global_inventory:
		global_inventory.erase(item)
	
	var text_id = ItemDatabase.get_id_by_item(item)
	# Borramos SOLO UNO (LIMIT 1) para no borrar todos los items iguales si tienes 2 espadas
	# SQLite en Godot a veces requiere trucos para borrar con LIMIT, 
	# pero lo más seguro es borrar por rowid si lo tuviéramos. 
	# Para simplificar, borramos el primero que coincida:
	
	var query = "DELETE FROM global_inventory WHERE id = (SELECT id FROM global_inventory WHERE item_id = '" + text_id + "' LIMIT 1);"
	db.query(query)

# --- CARGAR DATOS (SELECT) ---

func load_data_from_db():
	global_inventory.clear()
	
	# 1. Cargar Inventario Global
	db.query("SELECT * FROM global_inventory;")
	for row in db.query_result:
		var text_id = row["item_id"]
		var item_res = ItemDatabase.get_item_by_id(text_id)
		if item_res:
			global_inventory.append(item_res)
	
	# 2. Cargar Héroes
	db.query("SELECT * FROM hero_equipment;")
	for row in db.query_result:
		var h_id = row["hero_id"]
		var slot = row["slot"]
		var text_id = row["item_id"]
		
		var item_res = ItemDatabase.get_item_by_id(text_id)
		
		if heroes_data.has(h_id) and item_res:
			heroes_data[h_id]["inventory"][slot] = item_res

	print("Datos cargados desde SQLite exitosamente.")

func save_game():
	pass
	
# Stats Calculator (Igual que antes)
func calculate_hero_stats(hero_id: String, base_resource: Resource) -> Dictionary:
	var totals = {
		"attack_range": base_resource.attack_range,
		"health": base_resource.health,
		"attack": base_resource.attack,
		"defense": base_resource.defense,
		"accuracy": base_resource.accuracy,
		"speed": base_resource.speed,
		"evasion": base_resource.evasion,
		"block_rate": base_resource.block_rate,
		"defense_penetration": base_resource.defense_penetration,
		"critical_rate": base_resource.critical_rate,
		"critical_damage": base_resource.critical_damage,
		"attack_speed": base_resource.attack_speed,
		"bonus_attack_range": 0,
		"bonus_health": 0, 
		"bonus_attack": 0, 
		"bonus_defense": 0,
		"bonus_accuracy": 0,
		"bonus_critical_rate": 0,
		"bonus_critical_damage": 0,
		"bonus_defense_penetration": 0,
		"bonus_evasion": 0,
		"bonus_block_rate": 0		
	}
	if heroes_data.has(hero_id):
		var hero_inv = heroes_data[hero_id]["inventory"]
		for slot in hero_inv:
			var item = hero_inv[slot]
			if item is ItemData:
					totals["bonus_attack_range"] += totals["attack_range"]*item.range_mod
					totals["bonus_health"] += totals["health"]*item.health + item.health
					totals["bonus_attack"] += totals["attack"]*item.attack_mod + item.attack
					totals["bonus_defense"] += totals["defense"]*item.defense_mod + item.defense
					totals["bonus_accuracy"] += item.accuracy
					totals["bonus_critical_rate"] += item.critical_rate
					totals["bonus_critical_damage"] += item.critical_damage
					totals["bonus_defense_penetration"] += item.defense_penetration
					totals["bonus_evasion"] += item.evasion
					totals["bonus_block_rate"] += item.block_rate

	totals["attack_range"] += totals["bonus_attack_range"]
	totals["health"] += totals["bonus_health"]
	totals["attack"] += totals["bonus_attack"]
	totals["defense"] += totals["bonus_defense"]
	totals["accuracy"] += totals["bonus_accuracy"]
	totals["critical_rate"] += totals["bonus_critical_rate"]
	totals["critical_damage"] += totals["bonus_critical_damage"]
	totals["defense_penetration"] += totals["bonus_defense_penetration"]
	totals["evasion"] += totals["bonus_evasion"]
	totals["block_rate"] += totals["bonus_block_rate"]
	return totals
