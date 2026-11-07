extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/silver.gd")

func _ready() -> void:
    _build_environment()
    var silver := CharacterBody3D.new()
    silver.set_script(PLAYER_SCRIPT)
    silver.position = Vector3(0, 1.2, 7)
    add_child(silver)

func _material(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = 0.55
    return m

func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
    var host: Node3D = parent
    if solid:
        var body := StaticBody3D.new()
        body.name = name
        parent.add_child(body)
        host = body
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = _material(color)
    visual.position = pos
    host.add_child(visual)
    if solid:
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = size
        shape.shape = box_shape
        shape.position = pos
        host.add_child(shape)

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.08, 0.2, 0.42)
    sky_mat.sky_horizon_color = Color(0.62, 0.76, 0.9)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.65, 0.75, 0.9)
    env.ambient_light_energy = 0.8
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -30, 0)
    sun.light_energy = 1.25
    add_child(sun)

    _box(self, "Island", Vector3(0, -0.65, -17), Vector3(36, 1.3, 78), Color(0.19, 0.38, 0.29))
    _box(self, "Stone path", Vector3(0, 0.04, -16), Vector3(8, 0.12, 62), Color(0.34, 0.4, 0.47), false)
    _box(self, "Floating platform one", Vector3(-5, 1.0, -12), Vector3(4, 0.5, 4), Color(0.46, 0.57, 0.68))
    _box(self, "Floating platform two", Vector3(5, 1.8, -25), Vector3(5, 0.5, 5), Color(0.46, 0.57, 0.68))
    _box(self, "Finish platform", Vector3(0, 2.6, -43), Vector3(12, 0.5, 8), Color(0.46, 0.57, 0.68))
    for i in range(7):
        var z := -4.0 - float(i) * 8.0
        _box(self, "Ancient pillar", Vector3(-8, 1.6, z), Vector3(1, 3.8, 1), Color(0.39, 0.48, 0.56))
        _box(self, "Ancient pillar", Vector3(8, 1.6, z - 3), Vector3(1, 3.8, 1), Color(0.39, 0.48, 0.56))
    var orb_mat := _material(Color(0.12, 0.82, 1.0), 0.3)
    for p in [Vector3(0, 1.1, -5), Vector3(-5, 2, -12), Vector3(5, 2.8, -25)]:
        var orb := RigidBody3D.new()
        orb.name = "PsiOrb"
        orb.position = p
        orb.mass = 0.8
        add_child(orb)
        var sphere := SphereMesh.new()
        sphere.radius = 0.48
        sphere.height = 0.96
        var mi := MeshInstance3D.new()
        mi.mesh = sphere
        mi.material_override = orb_mat
        orb.add_child(mi)
        var cs := CollisionShape3D.new()
        var shape := SphereShape3D.new()
        shape.radius = 0.48
        cs.shape = shape
        orb.add_child(cs)
