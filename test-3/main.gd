# main.gd
extends Node3D

@export var player_scene: PackedScene
@export var chunk_scene: PackedScene
@export var view_distance: int = 3
@export var chunk_size: int = 16
@export var chunk_height: int = 32

var player: CharacterBody3D
var terrain_generator: TerrainGenerator
var loaded_chunks: Dictionary = {}

func _ready():
	# Создаем генератор террейна
	terrain_generator = TerrainGenerator.new()
	
	# Создаем игрока
	player = player_scene.instantiate()
	add_child(player)
	player.position = Vector3(0, 20, 0)
	
	# Загружаем начальные чанки
	update_chunks()

func _process(_delta):
	update_chunks()

func _input(event):
	if event.is_action_pressed("save_all_chunks"):
		save_all_chunks()
	elif event.is_action_pressed("reload_chunks"):
		reload_chunks()

func update_chunks():
	var player_chunk_x = int(player.position.x / chunk_size)
	var player_chunk_z = int(player.position.z / chunk_size)
	
	# Удаляем дальние чанки
	var chunks_to_remove = []
	for key in loaded_chunks:
		var coords = key.split(",")
		var x = int(coords[0])
		var z = int(coords[1])
		
		if abs(x - player_chunk_x) > view_distance or abs(z - player_chunk_z) > view_distance:
			chunks_to_remove.append(key)
	
	for key in chunks_to_remove:
		# Сохраняем чанк перед удалением
		loaded_chunks[key].save_chunk_data()
		loaded_chunks[key].queue_free()
		loaded_chunks.erase(key)
	
	# Загружаем новые чанки
	for x in range(player_chunk_x - view_distance, player_chunk_x + view_distance + 1):
		for z in range(player_chunk_z - view_distance, player_chunk_z + view_distance + 1):
			var key = str(x) + "," + str(z)
			if not loaded_chunks.has(key):
				var chunk = chunk_scene.instantiate()
				chunk.initialize(x, z, chunk_size, chunk_height, terrain_generator)
				add_child(chunk)
				loaded_chunks[key] = chunk

func save_all_chunks():
	print("Сохранение всех чанков...")
	for chunk in loaded_chunks.values():
		chunk.save_chunk_data()
	print("Все чанки сохранены!")

func reload_chunks():
	print("Перезагрузка чанков...")
	for key in loaded_chunks:
		loaded_chunks[key].queue_free()
	loaded_chunks.clear()
	update_chunks()

func _exit_tree():
	# Автосохранение при выходе
	save_all_chunks()
