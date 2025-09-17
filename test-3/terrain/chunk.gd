# chunk.gd
class_name Chunk
extends StaticBody3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var chunk_x: int
var chunk_z: int
var chunk_size: int
var chunk_height: int
var terrain_generator: TerrainGenerator
var is_generated: bool = false

func _ready():
	# Убедимся, что узлы существуют
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
	
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		add_child(collision_shape)

func initialize(x: int, z: int, size: int, height: int, generator: TerrainGenerator):
	chunk_x = x
	chunk_z = z
	chunk_size = size
	chunk_height = height
	terrain_generator = generator
	
	position = Vector3(x * size, 0, z * size)
	
	# Проверяем, есть ли сохраненный меш
	if not try_load_mesh():
		generate_mesh()

# ИЗМЕНЕНО: Используем другое расширение
func try_load_mesh() -> bool:
	var filename = "res://world/mesh_%d_%d.data" % [chunk_x, chunk_z]  # .data вместо .res
	if FileAccess.file_exists(filename):
		var file = FileAccess.open(filename, FileAccess.READ)
		if file:
			var mesh_data = file.get_var()
			file.close()
			
			if mesh_data is Array:
				var mesh = ArrayMesh.new()
				mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_data)
				
				mesh_instance.mesh = mesh
				
				# Создаем коллизию
				var shape = mesh.create_trimesh_shape()
				collision_shape.shape = shape
				
				is_generated = true
				return true
	return false

func generate_mesh():
	# Убедимся, что узлы инициализированы
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		add_child(mesh_instance)
	
	if not collision_shape:
		collision_shape = CollisionShape3D.new()
		add_child(collision_shape)
	
	var heights = terrain_generator.generate_heights(chunk_x, chunk_z, chunk_size, chunk_height)
	
	# Создаем меш
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Вершины
	for x in range(chunk_size + 1):
		for z in range(chunk_size + 1):
			var y = heights[x][z]
			surface_tool.set_uv(Vector2(x / float(chunk_size), z / float(chunk_size)))
			surface_tool.add_vertex(Vector3(x, y, z))
	
	# Индексы для треугольников
	for x in range(chunk_size):
		for z in range(chunk_size):
			var i0 = x * (chunk_size + 1) + z
			var i1 = i0 + 1
			var i2 = i0 + (chunk_size + 1)
			var i3 = i2 + 1
			
			# Первый треугольник
			surface_tool.add_index(i0)
			surface_tool.add_index(i2)
			surface_tool.add_index(i1)
			
			# Второй треугольник
			surface_tool.add_index(i1)
			surface_tool.add_index(i2)
			surface_tool.add_index(i3)
	
	surface_tool.generate_normals()
	var mesh = surface_tool.commit()
	
	mesh_instance.mesh = mesh
	
	# Создаем коллизию
	var shape = mesh.create_trimesh_shape()
	collision_shape.shape = shape
	
	# Сохраняем меш
	save_mesh()
	
	is_generated = true

# ИЗМЕНЕНО: Используем другое расширение
func save_mesh() -> void:
	if mesh_instance and mesh_instance.mesh:
		var filename = "user://chunks/mesh_%d_%d.data" % [chunk_x, chunk_z]  # .data вместо .res
		var file = FileAccess.open(filename, FileAccess.WRITE)
		if file:
			var mesh_data = mesh_instance.mesh.surface_get_arrays(0)
			file.store_var(mesh_data)
			file.close()

func _exit_tree():
	# Автосохранение при удалении чанка
	if is_generated:
		save_mesh()

func save_chunk_data() -> void:
	if is_generated:
		save_mesh()
