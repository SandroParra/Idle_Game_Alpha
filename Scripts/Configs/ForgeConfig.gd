extends Resource
class_name ForgeConfig

# --- CONFIGURACIÓN DE RECICLAJE ---
# Estructura: { "RarityItem": { "RarityStone": [Chance(0-1), Min, Max] } }
@export var recycle_table = {
	"Common": {
		"Common": [1.0, 2, 3] # 100% chance, 2 a 3 piedras
	},
	"Uncommon": {
		"Uncommon": [1.0, 1, 2],
		"Common": [0.8, 2, 4]
	},
	"Rare": {
		"Rare": [1.0, 1, 2],
		"Uncommon": [0.7, 2, 3],
		"Common": [0.5, 3, 5]
	},
	"Epic": {
		"Epic": [1.0, 1, 2],
		"Rare": [0.6, 2, 3],
		"Uncommon": [0.4, 3, 5],
		"Common": [0.2, 5, 8]
	},
	"Legendary": {
		"Legendary": [1.0, 1, 1],
		"Epic": [0.5, 2, 3],
		"Rare": [0.3, 3, 5],
		"Uncommon": [0.2, 5, 8],
		"Common": [0.1, 8, 12]
	}
}

# --- CONFIGURACIÓN DE MEJORA ---
# Chance base por NIVEL ACTUAL (índice 0 = nivel 0 pasando a 1)
# Array de 20 elementos (Nivel 0 al 19)
@export var base_success_chance: Array[float] = [
	1.00, 0.80, 0.70, 0.60, 0.50, 0.45, 0.40, 0.35, 0.30, 0.25, # 0->1 hasta 9->10
	0.20, 0.20, 0.15, 0.15, 0.10, 0.10, 0.08, 0.08, 0.05, 0.05, 0.05  # 10->11 hasta 19->20
]

# Bonus de chance extra por usar una piedra DE MEJOR RAREZA (por cada nivel de diferencia)
# Ejemplo: Item Common usando Piedra Rare (Diferencia +2). Bonus = 0.05 * 2 = +10%
@export var rarity_bonus_per_tier: float = 0.05

# Cantidad de piedras necesarias según el NIVEL DESTINO
func get_stone_cost(target_level: int) -> Dictionary:
	var result = {"stone_count": 0, "special_item": ""}
	
	if target_level >= 1 and target_level <= 3:
		result["stone_count"] = 1
	elif target_level >= 4 and target_level <= 9:
		result["stone_count"] = 3
	elif target_level == 10:
		result["stone_count"] = 5
		result["special_item"] = "BlessStone"
	elif target_level >= 11 and target_level <= 19:
		result["stone_count"] = 7
	elif target_level == 20:
		result["stone_count"] = 7
		result["special_item"] = "SoulStone"
		
	return result

# Helper para comparar rarezas (Common=0, Uncommon=1...)
func get_rarity_value(rarity: String) -> int:
	match rarity:
		"Common": return 0
		"Uncommon": return 1
		"Rare": return 2
		"Epic": return 3
		"Legendary": return 4
	return 0
