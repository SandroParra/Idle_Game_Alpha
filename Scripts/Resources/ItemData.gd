extends Resource
class_name ItemData

@export_group("Visuals")
@export var name: String = "Item Name"
@export var icon: Texture2D
@export var rarity: String = "Common"

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
@export var slot: bool = false

@export_group("Upgrade System")
@export var level: int = 0 # Nivel de mejora (Ej: +1, +2...)
@export var buffed_stats: Array[String] = [] # Guarda qué stats recibieron el bono del 25%
@export var has_gem_slot: bool = false
const LEVEL_GROWTH_RATE = 1.05 # 5%

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
const STATS_ATTACK = ["attack_mod", "physical_attack", "magical_attack", 
"critical_rate", "critical_damage", "defense_penetration"]
const STATS_DEFENSE = ["physical_defense", "magical_defense", "defense_mod", 
"health", "health_mod"]

# Grupos de Slots
const SLOTS_ARMOR = ["boots", "chestplate", "helmet"]
const SLOTS_JEWELRY_WEAPON = ["weapon", "ring", "amulet"]
const SLOTS_MIXED = ["pants", "gloves"]

# Listas de referencia
const POOL_PHYSICAL = ["physical_attack", "physical_defense", "defense_penetration"]
const POOL_MAGICAL = ["magical_attack", "magical_defense", "health"]
const ALL_STATS_POOL = ["physical_attack", "magical_attack", "physical_defense", "magical_defense", 
"health", "critical_rate", "critical_damage", "defense_penetration"]

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
		if slot in SLOTS_ARMOR or slot in SLOTS_MIXED:
			picked.append(STATS_DEFENSE.pick_random()) # Regla 6
		elif slot in SLOTS_JEWELRY_WEAPON:
			picked.append(STATS_ATTACK.pick_random()) # Regla 7
			
	# --- REGLAS PARA UNCOMMON (2 Stats) ---
	elif rarity == "Uncommon":
		if slot in SLOTS_ARMOR: # Boots, Chest, Helmet (Regla 8)
			picked = _pick_unique_from_pool(STATS_DEFENSE, 2)
			
		elif slot in SLOTS_JEWELRY_WEAPON: # Weapon, Ring, Amulet (Regla 9)
			picked = _pick_unique_from_pool(STATS_ATTACK, 2)
			
		elif slot in SLOTS_MIXED: # Regla 10 (Especial)
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

# --- FUNCIÓN PRINCIPAL DE SUBIDA DE NIVEL ---
func apply_level_up():
	level += 1
	
	# 1. Crecimiento Base (5%) para todos los stats numéricos existentes
	_apply_base_growth()
	
	# 2. Hitos de Nivel (Milestones)
	match level:
		5:
			_apply_prefix("Tempered")
			_apply_random_bonus(0.25) # 25% a un stat al azar
		10:
			_replace_prefix("Tempered", "Ascended")
			_apply_random_bonus(0.25) # 25% a OTRO stat diferente
			has_gem_slot = true
		15:
			_add_new_random_stat()
		20:
			_replace_prefix("Ascended", "Perfect")
			_maximize_stats_to_perfect()

# --- HELPERS DE LÓGICA ---

func _apply_base_growth():
	# Lista de todas las variables que son estadísticas
	for stat in ALL_STATS_POOL:
		var val = self.get(stat)
		# Si el stat existe (es mayor a 0), aplicamos el 5%
		if typeof(val) == TYPE_INT and val > 0:
			self.set(stat, int(val * LEVEL_GROWTH_RATE))
		elif typeof(val) == TYPE_FLOAT and val > 0.0:
			self.set(stat, val * LEVEL_GROWTH_RATE)

func _apply_prefix(prefix: String):
	# Ej: "Iron Sword" -> "Tempered Iron Sword"
	if not name.begins_with(prefix):
		name = prefix + " " + name

func _replace_prefix(old_prefix: String, new_prefix: String):
	# Ej: "Tempered Iron Sword" -> "Ascended Iron Sword"
	name = name.replace(old_prefix, new_prefix)

func _apply_random_bonus(percentage: float):
	# Buscar stats que tengan valor > 0
	var available_stats = []
	for stat in ALL_STATS_POOL:
		if self.get(stat) > 0 and not stat in buffed_stats:
			available_stats.append(stat)
	
	if available_stats.is_empty(): return
	
	var picked_stat = available_stats.pick_random()
	buffed_stats.append(picked_stat) # Registrar para no repetir en nivel 10
	
	var current_val = self.get(picked_stat)
	if typeof(current_val) == TYPE_INT:
		self.set(picked_stat, int(current_val * (1.0 + percentage)))
	else:
		self.set(picked_stat, current_val * (1.0 + percentage))

func _add_new_random_stat():
	# Buscar stats que el item NO tenga (valor 0)
	var candidates = []
	for stat in ALL_STATS_POOL:
		if self.get(stat) == 0: # Stats que no tenemos
			candidates.append(stat)
	
	if candidates.is_empty(): return
	
	var new_stat = candidates.pick_random()
	
	# Asignar un valor base inicial basado en la rareza (Usamos Common como base genérica)
	# O podríamos usar la configuración de RARITY_RANGES si es accesible.
	# Por simplicidad, damos un valor base "decente" y aplicamos el crecimiento de nivel 15 niveles.
	var base_val = 10 # Valor arbitrario inicial
	if "rate" in new_stat or "penetration" in new_stat:
		base_val = 0.05 # 5% inicial para porcentajes
		
	# Simular crecimiento hasta nivel 15
	var grown_val = base_val * pow(LEVEL_GROWTH_RATE, 15)
	
	if typeof(base_val) == TYPE_INT:
		self.set(new_stat, int(grown_val))
	else:
		self.set(new_stat, grown_val)

func _maximize_stats_to_perfect():
	# Aquí necesitamos acceder a la tabla de rangos. 
	# Asumimos que RARITY_RANGES es accesible (static o const en ItemData).
	var config_ranges = RARITY_RANGES.get(rarity)
	if not config_ranges: return
	
	for stat in ALL_STATS_POOL:
		var current_val = self.get(stat)
		if current_val > 0:
			# 1. Obtener el MAX posible base para esta rareza
			var range_vals = config_ranges.get(stat)
			if range_vals:
				var max_base = range_vals[1] # El segundo valor es el máximo
				
				# 2. Recalcular: MaxBase * (1.05 ^ 20)
				var perfect_val = max_base * pow(LEVEL_GROWTH_RATE, 20)
				
				# 3. Si este stat tenía bonos de nivel 5 o 10 (Tempered/Ascended), reaplicarlos
				if stat in buffed_stats:
					perfect_val = perfect_val * 1.25
				
				# 4. Asignar
				if typeof(current_val) == TYPE_INT:
					self.set(stat, int(perfect_val))
				else:
					self.set(stat, perfect_val)
