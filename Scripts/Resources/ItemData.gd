extends Resource
class_name ItemData

@export_group("Visuals")
@export var name: String = "Item Name"
@export var icon: Texture2D
@export var rarity: String = "Common"
#@export var price: int = 0

@export_group("System")
# Tipos: boots, chestplate, gloves, helmet, weapon, ring, amulet
@export_enum("helmet", "chestplate", "gloves", "pants", "boots", "weapon", "ring", "amulet") var slot_type: String = "helmet"

@export_group("Generated Stats")
# Attack modifyers
@export var attack_mod: float = 0.0
@export var physical_attack: int = 0
@export var magical_attack: int = 0
@export var critical_rate: float = 0.0
@export var critical_damage: int = 0
@export var defense_penetration: float = 0.0

# Defense modifyers
@export var physical_defense: int = 0
@export var magical_defense: int = 0
@export var defense_mod: float = 0.0
@export var health: int = 0
@export var health_mod: float = 0.0

# ==============================================================================
# TABLA DE CONFIGURACIÓN DE RANGOS (AQUÍ SE EDITARÁ EL BALANCE)
# Formato: "NombreStat": [ValorMinimo, ValorMaximo]
# ==============================================================================
const RARITY_RANGES = {
	"Common": {
		"attack_mod": [0.1, 0.5],
		"physical_attack": [2, 7],
		"magical_attack": [2, 9],
		"critical_rate": [0.05, 0.10],
		"critical_damage": [50, 120],
		"physical_defense": [6, 10],
		"magical_defense": [6, 10],
		"defense_mod": [0.3, 0.5],
		"defense_penetration": [0.05, 0.10],
		"health": [20, 35],
		"health_mod": [0.3, 0.6]
	},
	"Uncommon": {
		"attack_mod": [0.8, 1.2],
		"physical_attack": [10, 19],
		"magical_attack": [13, 24],
		"critical_rate": [0.10, 0.20],
		"critical_damage": [140, 180],
		"physical_defense": [15, 21],
		"magical_defense": [16, 24],
		"defense_mod": [0.5, 0.8],
		"defense_penetration": [0.09, 0.16],
		"health": [40, 60],
		"health_mod": [0.7, 1.3]
	},
	"Rare": {
		"attack_mod": [1.4, 1.8],
		"physical_attack": [28, 41],
		"magical_attack": [25, 50],
		"critical_rate": [0.2, 0.3],
		"critical_damage": [180, 200],
		"physical_defense": [35, 45],
		"magical_defense": [50, 60],
		"defense_mod": [1.0, 1.3],
		"defense_penetration": [0.2, 0.3],
		"health": [60, 90],
		"health_mod": [1.1, 1.8]
	},
	"Epic": {
		"attack_mod": [2.0, 2.5],
		"physical_attack": [50, 67],
		"magical_attack": [67, 71],
		"critical_rate": [0.32, 0.45],
		"critical_damage": [250, 310],
		"physical_defense": [55, 63],
		"magical_defense": [64, 76],
		"defense_mod": [1.4, 1.9],
		"defense_penetration": [0.35, 0.45],
		"health": [101, 165],
		"health_mod": [2.2, 2.7]
	},
	"Legendary": {
		"attack_mod": [2.9, 3.4],
		"physical_attack": [85, 100],
		"magical_attack": [98, 115],
		"critical_rate": [0.50, 0.63],
		"critical_damage": [350, 400],
		"physical_defense": [76, 89],
		"magical_defense": [90, 122],
		"defense_mod": [2.0, 2.8],
		"defense_penetration": [0.55, 0.65],
		"health": [200, 276],
		"health_mod": [3.0, 3.9]
	}
}

# --- CONSTANTES DE GRUPOS DE STATS ---
const STATS_ATTACK = ["attack_mod", "physical_attack", "magical_attack", "critical_rate", "critical_damage", "defense_penetration"]
const STATS_DEFENSE = ["physical_defense", "magical_defense", "defense_mod", "health", "health_mod"]

# Grupos de Slots
const SLOTS_ARMOR = ["boots", "chestplate", "helmet"] # Gloves tiene reglas especiales en Uncommon
const SLOTS_JEWELRY_WEAPON = ["weapon", "ring", "amulet"]

func create_instance(rarity_level: String) -> ItemData:
	var new_item = self.duplicate()
	new_item.rarity = rarity_level
	new_item._reset_stats()
	
	# 1. Determinar cuántos stats necesitamos
	var stat_count = 1
	match rarity_level:
		"Common": stat_count = 1
		"Uncommon": stat_count = 2
		"Rare": stat_count = 3
		"Epic": stat_count = 4
		"Legendary": stat_count = 5
	
	# 2. Seleccionar QUÉ stats vamos a subir (Nombres de las variables)
	var selected_stats: Array[String] = _pick_stats_based_on_rules(new_item.slot_type, rarity_level, stat_count)
	
	# 3. Asignar valores a esos stats
	new_item._apply_values_from_config(selected_stats, rarity_level)
	
	return new_item

func _reset_stats():
	attack_mod = 0.0
	physical_attack = 0
	magical_attack = 0
	critical_rate = 0.0
	critical_damage = 0
	physical_defense = 0
	magical_defense = 0
	defense_mod = 0.0
	defense_penetration = 0.0
	health = 0
	health_mod = 0.0
	
@warning_ignore("shadowed_variable")
func _pick_stats_based_on_rules(slot: String, rarity: String, count: int) -> Array[String]:
	var picked: Array[String] = []
	
	# --- REGLAS PARA COMMON (1 Stat) ---
	if rarity == "Common":
		if slot in SLOTS_ARMOR or slot == "gloves":
			picked.append(STATS_DEFENSE.pick_random()) # Regla 6
		elif slot in SLOTS_JEWELRY_WEAPON:
			picked.append(STATS_ATTACK.pick_random()) # Regla 7
			
	# --- REGLAS PARA UNCOMMON (2 Stats) ---
	elif rarity == "Uncommon":
		if slot in SLOTS_ARMOR: # Boots, Chest, Helmet (Regla 8)
			picked = _pick_unique_from_pool(STATS_DEFENSE, 2)
			
		elif slot in SLOTS_JEWELRY_WEAPON: # Weapon, Ring, Amulet (Regla 9)
			picked = _pick_unique_from_pool(STATS_ATTACK, 2)
			
		elif slot == "gloves": # Regla 10 (Especial)
			# 1er stat: Defensa
			var stat_1 = STATS_DEFENSE.pick_random()
			picked.append(stat_1)
			
			# 2do stat: Defensa (diferente) O Ataque
			var pool_mixed = STATS_ATTACK.duplicate()
			pool_mixed.append_array(STATS_DEFENSE)
			pool_mixed.erase(stat_1) # Asegurar que no se repita el primero
			
			picked.append(pool_mixed.pick_random())

	# --- REGLAS PARA RARE (3 Stats) O SUPERIOR ---
	else: 
		# "Rare": Todos tendrán las mismas propiedades de Uncommon + 3er modificador random (Regla 11)
		# Para Epic (4) y Legendary (5) extendemos esta lógica agregando más randoms.
		
		# Paso A: Cumplir la base Uncommon
		var base_uncommon = _pick_stats_based_on_rules(slot, "Uncommon", 2)
		picked.append_array(base_uncommon)
		
		# Paso B: Rellenar los huecos restantes (1 para Rare, 2 para Epic, etc.)
		var slots_needed = count - picked.size()
		
		# Pool total (Ataque + Defensa)
		var full_pool = STATS_ATTACK.duplicate()
		full_pool.append_array(STATS_DEFENSE)
		
		# Quitamos los que ya elegimos en la fase Uncommon para no repetir
		for p in picked:
			if p in full_pool: full_pool.erase(p)
			
		# Elegimos el resto al azar
		picked.append_array(_pick_unique_from_pool(full_pool, slots_needed))
	
	return picked

func _pick_unique_from_pool(pool: Array, quantity: int) -> Array[String]:
	var p_copy = pool.duplicate()
	p_copy.shuffle()
	
	var result: Array[String] = []
	var limit = min(quantity, p_copy.size())
	for i in range(limit):
		result.append(str(p_copy[i]))
		
	return result

# Helper para dar valores numéricos
func _apply_values_from_config(stats_list: Array[String], rarity_level: String):
	# 1. Obtener la configuración de esta rareza (o fallback a Common)
	var config = RARITY_RANGES.get(rarity_level, RARITY_RANGES["Common"])
	
	for stat_name in stats_list:
		# 2. Verificar si tenemos rango definido para este stat
		if config.has(stat_name):
			var range_vals = config[stat_name] # Es un Array [min, max]
			var min_val = range_vals[0]
			var max_val = range_vals[1]
			
			# 3. Generar valor aleatorio
			var val = randf_range(min_val, max_val)
			
			# 4. Asignar (Detectar si es entero o float automáticamente)
			# Usamos 'typeof' en el valor actual (que es 0 o 0.0) para saber el tipo correcto
			if typeof(self.get(stat_name)) == TYPE_INT:
				self.set(stat_name, int(val))
			else:
				self.set(stat_name, val)
		else:
			print("ADVERTENCIA: No hay rango configurado para ", stat_name, " en rareza ", rarity_level)
