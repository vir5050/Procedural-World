# terrain_generator.gd
class_name TerrainGenerator
extends RefCounted

var noise: FastNoiseLite
var save_path: String = "res://world/"

func _init():
	noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = 12345
	noise.frequency = 0.05
	
	# Создаем папку для сохранения чанков
	DirAccess.make_dir_recursive_absolute(save_path)

func get_height_at(x: float, z: float) -> float:
	var height = noise.get_noise_2d(x, z) * 10
	return height

# ИСПРАВЛЕНО: Добавлен префикс _ к неиспользуемому параметру
func generate_heights(chunk_x: int, chunk_z: int, size: int, _height: int) -> Array:
	# Пытаемся загрузить из файла
	var loaded_data = load_chunk(chunk_x, chunk_z)
	if loaded_data != null and loaded_data is Array:
		return loaded_data
	
	# Генерируем новые данные
	var heights = []
	for x in range(size + 1):
		heights.append([])
		for z in range(size + 1):
			var world_x = chunk_x * size + x
			var world_z = chunk_z * size + z
			heights[x].append(get_height_at(world_x, world_z))
	
	# Сохраняем сгенерированные данные
	save_chunk(chunk_x, chunk_z, heights)
	
	return heights

func get_chunk_filename(chunk_x: int, chunk_z: int) -> String:
	return save_path + "chunk_%d_%d.data" % [chunk_x, chunk_z]

func save_chunk(chunk_x: int, chunk_z: int, heights: Array) -> void:
	var file = FileAccess.open(get_chunk_filename(chunk_x, chunk_z), FileAccess.WRITE)
	if file:
		file.store_var(heights)
		file.close()

func load_chunk(chunk_x: int, chunk_z: int):
	var filename = get_chunk_filename(chunk_x, chunk_z)
	if FileAccess.file_exists(filename):
		var file = FileAccess.open(filename, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			if data is Array:
				return data
	return null

func chunk_exists(chunk_x: int, chunk_z: int) -> bool:
	return FileAccess.file_exists(get_chunk_filename(chunk_x, chunk_z))

func delete_chunk(chunk_x: int, chunk_z: int) -> void:
	var filename = get_chunk_filename(chunk_x, chunk_z)
	if FileAccess.file_exists(filename):
		DirAccess.remove_absolute(filename)

func get_all_saved_chunks() -> Array:
	var chunks = []
	var dir = DirAccess.open(save_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".data"):
				var parts = file_name.replace("chunk_", "").replace(".data", "").split("_")
				if parts.size() == 2:
					chunks.append(Vector2i(int(parts[0]), int(parts[1])))
			file_name = dir.get_next()
	return chunks

func cleanup_old_files():
	var dir = DirAccess.open(save_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".res"):
				DirAccess.remove_absolute(save_path + file_name)
			file_name = dir.get_next()
