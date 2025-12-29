# PlayerData.gd (Autoload)
extends Node

const SAVE_PATH = "user://savegame.tres"

# Referencia a los datos en memoria (Instancia de SaveGame)
var saved_data: SaveGame

const SLOTS = [
	"helmet", "amulet", "chestplate", "gloves", 
	"bracelet", "left_ring", "right_ring", 
	"belt", "pants", "boots","left_weapon", "right_weapon"
]

# Acceso rápido para compatibilidad con tu código UI existente
var global_inventory: Array[ItemData]:
	get: return saved_data.global_inventory
	
var heroes_data: Dictionary:
	get: return saved_data.hero_equipment

func _ready():
	load_game()

func save_game():
	# ResourceSaver escribe el archivo .tres binario con toda la data
	var error = ResourceSaver.save(saved_data, SAVE_PATH)
	if error != OK:
		print("Error al guardar la partida: ", error)
	else:
		print("Partida guardada exitosamente.")

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		# Cargamos el recurso existente
		saved_data = ResourceLoader.load(SAVE_PATH)
		if saved_data == null:
			# Si falla la carga (archivo corrupto), creamos uno nuevo
			create_new_save()
	else:
		create_new_save()
	
	verify_data_integrity()

func create_new_save():
	saved_data = SaveGame.new()
	# Inicializar estructura de héroes
	saved_data.hero_equipment = {
		"BlackDragon": {"inventory": {}},
		"MaleViking": {"inventory": {}},
		"MaleKnight": {"inventory": {}}
	}
	# Inicializar inventarios vacíos para evitar null pointers
	for h_id in saved_data.hero_equipment:
		saved_data.hero_equipment[h_id]["inventory"] = {}
		for slot in SLOTS:
			saved_data.hero_equipment[h_id]["inventory"][slot] = null

func verify_data_integrity():
	# Asegura que si agregaste nuevos héroes en una actualización, existan en el save viejo
	var ids = ["BlackDragon", "MaleViking", "MaleKnight"]
	for h_id in ids:
		if not saved_data.hero_equipment.has(h_id):
			saved_data.hero_equipment[h_id] = {"inventory": {}}

# --- GESTIÓN DE INVENTARIO ---

func add_item_to_bag(item: ItemData):
	if item == null: return
	
	# Simplemente agregamos el recurso al Array. 
	# Al guardar el Resource SaveGame, este item se serializará dentro.
	saved_data.global_inventory.append(item)
	save_game()
	print("Item añadido y guardado: ", item.name)

func equip_item_from_bag(hero_id, slot, item: ItemData):
	if item == null: return
	
	# Referencia al inventario del héroe
	var hero_inv = saved_data.hero_equipment[hero_id].get("inventory", {})
	var current_equipped = hero_inv.get(slot)
	
	# 1. Si hay algo equipado, lo devolvemos a la bolsa
	if current_equipped:
		saved_data.global_inventory.append(current_equipped)
		
	# 2. Equipamos el nuevo
	hero_inv[slot] = item
	
	# 3. Quitamos el nuevo de la bolsa
	# NOTA: erase() borra la primera coincidencia exacta del objeto memoria
	saved_data.global_inventory.erase(item)
	
	saved_data.hero_equipment[hero_id]["inventory"] = hero_inv
	save_game()

func unequip_item(hero_id, slot):
	var hero_inv = saved_data.hero_equipment[hero_id].get("inventory", {})
	var item = hero_inv.get(slot)
	
	if item:
		saved_data.global_inventory.append(item)
		hero_inv[slot] = null
		save_game()

	
# Stats Calculator (Igual que antes)
func calculate_hero_stats(hero_id: String, base_resource: Resource) -> Dictionary:
	var totals = {
		"health": base_resource.health,
		"physical_attack": base_resource.physical_attack,
		"magical_attack": base_resource.magical_attack,
		"physical_defense": base_resource.physical_defense,
		"magical_defense": base_resource.magical_defense,
		"defense_penetration": base_resource.defense_penetration,
		"critical_rate": base_resource.critical_rate,
		"critical_damage": base_resource.critical_damage,
		"bonus_health": 0, 
		"bonus_physical_attack": 0,
		"bonus_magical_attack": 0,
		"bonus_physical_defense": 0,
		"bonus_magical_defense": 0,
		"bonus_critical_rate": 0,
		"bonus_critical_damage": 0,
		"bonus_defense_penetration": 0
	}
	if saved_data.hero_equipment.has(hero_id):
		var hero_inv = saved_data.hero_equipment[hero_id]["inventory"]
		for slot in hero_inv:
			var item = hero_inv[slot]
			if item is ItemData:
					totals["bonus_health"] += totals["health"]*item.health_mod + item.health
					totals["bonus_physical_attack"] += totals["physical_attack"]*item.attack_mod + item.physical_attack
					totals["bonus_magical_attack"] += totals["magical_attack"]*item.attack_mod + item.magical_attack
					totals["bonus_physical_defense"] += totals["physical_defense"]*item.defense_mod + item.physical_defense
					totals["bonus_magical_defense"] += totals["magical_defense"]*item.defense_mod + item.magical_defense
					totals["bonus_critical_rate"] += item.critical_rate
					totals["bonus_critical_damage"] += item.critical_damage
					totals["bonus_defense_penetration"] += item.defense_penetration

	totals["health"] += totals["bonus_health"]
	totals["physical_attack"] += totals["bonus_physical_attack"]
	totals["magical_attack"] += totals["bonus_magical_attack"]
	totals["physical_defense"] += totals["bonus_physical_defense"]
	totals["magical_defense"] += totals["bonus_magical_defense"]
	totals["critical_rate"] += totals["bonus_critical_rate"]
	totals["critical_damage"] += totals["bonus_critical_damage"]
	totals["defense_penetration"] += totals["bonus_defense_penetration"]
	return totals
