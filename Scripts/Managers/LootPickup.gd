extends Area2D
class_name LootPickup

# Arrastra aquí el recurso ItemData (creado con create_instance) al spawnearlo
var item_data: ItemData 

# Si usas DropData como wrapper, úsalo. Si no, usaremos un diccionario simple.
# Para ajustarnos a tu GameManager que espera algo con propiedad .item_data:
class DropWrapper:
	var item_data: ItemData
	func _init(res: ItemData):
		item_data = res

func initialize(data: ItemData, start_pos: Vector2):
	item_data = data
	global_position = start_pos
	# Aquí puedes añadir tu animación de "salto" igual que en XPDrop si quieres

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"): # Asegúrate que tu Player esté en este grupo
		_collect_item()

func _collect_item():
	if item_data == null:
		print("ERROR: LootPickup recogido sin ItemData asignado")
		queue_free()
		return

	# 1. Creamos el envoltorio que espera tu GameManager 
	# (ya que tu código hace 'if data.item_data:')
	var drop_wrapper = DropWrapper.new(item_data)
	
	# 2. Llamamos al grupo "gamemanager". 
	# Esto busca el nodo GameManager de la escena actual y ejecuta la función.
	get_tree().call_group("gamemanager", "register_drop", drop_wrapper)
	
	print("LOG: Ítem enviado al GameManager: ", item_data.name)
	
	# 3. Efectos de sonido o visuales aquí
	
	queue_free()
