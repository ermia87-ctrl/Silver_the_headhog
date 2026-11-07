extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/silver.gd")
const GOLD := Color(1.0, 0.72, 0.12)
const STONE := Color(0.30, 0.39, 0.49)

func _ready() -> void:
    _build_world()
    var silver := CharacterBody3D.new()
    silver.name = "Silver"
    silver.set_script(PLAYER_SCRIPT)
    silver.position = Vector3(0, 1.2, 13)
    add_child(silver)

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.55) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metallic
    m.roughness = roughness
    return m

func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color, solid: bool = true, metal: float = 0.0) -> Node3D:
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
    visual.material_override = _mat(color, metal)
    visual.position = pos
    host.add_child(visual)
    if solid:
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = size
        shape.shape = box_shape
        shape.position = pos
        host.add_child(shape)
    return host if solid else visual

func _ring(parent: Node3D, pos: Vector3, spin: float = 1.0) -> void:
    var area := Area3D.new()
    area.position = pos
    area.set_meta("spin", spin)
    parent.add_child(area)
    var torus := TorusMesh.new()
    torus.inner_radius = 0.25
    torus.outer_radius = 0.43
    var visual := MeshInstance3D.new()
    visual.mesh = torus
    visual.material_override = _mat(GOLD, 0.72, 0.22)
    area.add_child(visual)
    var collision := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.65
    collision.shape = sphere
    area.add_child(collision)
    area.body_entered.connect(func(body: Node3D):
        if body.name == "Silver":
            var hud = body.get("hud")
            if hud:
                hud.add_ring()
            area.queue_free()
    )

func _pillar(pos: Vector3, height: float, color: Color = STONE) -> void:
    _box(self, "Ruins pillar", pos, Vector3(1.15, height, 1.15), color)
    _box(self, "Pillar capital", pos + Vector3(0, height * 0.5 + 0.18, 0), Vector3(1.65, 0.36, 1.65), Color(0.52, 0.62, 0.72))

func _build_world() -> void:
    var world := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.035, 0.12, 0.29)
    sky_mat.sky_horizon_color = Color(0.48, 0.68, 0.82)
    sky_mat.ground_bottom_color = Color(0.055, 0.11, 0.16)
    sky_mat.ground_horizon_color = Color(0.28, 0.43, 0.52)
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.62, 0.76, 0.92)
    env.ambient_light_energy = 0.85
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    world.environment = env
    add_child(world)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -28, 0)
    sun.light_energy = 1.35
    sun.shadow_enabled = true
    add_child(sun)

    # Wide floating island and the central ancient roadway.
    _box(self, "Floating island", Vector3(0, -1.15, -23), Vector3(54, 2.3, 112), Color(0.13, 0.27, 0.24))
    _box(self, "Main causeway", Vector3(0, 0.02, -22), Vector3(12, 0.35, 98), Color(0.34, 0.41, 0.49))
    _box(self, "Left verge", Vector3(-7.2, -0.02, -22), Vector3(2.4, 0.5, 98), Color(0.22, 0.35, 0.32))
    _box(self, "Right verge", Vector3(7.2, -0.02, -22), Vector3(2.4, 0.5, 98), Color(0.22, 0.35, 0.32))

    # Reflective water around the island.
    var water := _box(self, "Sky sea", Vector3(0, -3.0, -23), Vector3(180, 0.2, 180), Color(0.035, 0.28, 0.43), false)
    var water_mesh := water as MeshInstance3D
    water_mesh.material_override = _mat(Color(0.035, 0.28, 0.43, 0.82), 0.55, 0.18)
    water_mesh.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

    # Broken ruins frame the route.
    for i in range(9):
        var z := -4.0 - float(i) * 10.0
        _pillar(Vector3(-10.0, 1.2, z), 3.8 + float(i % 3) * 0.7)
        _pillar(Vector3(10.0, 1.0, z - 4.0), 3.2 + float((i + 1) % 3) * 0.8)
        _box(self, "Ruined wall", Vector3(-14.0, 0.6, z - 2.0), Vector3(0.5, 2.2, 5.5), Color(0.25, 0.34, 0.43))
        _box(self, "Ruined wall", Vector3(14.0, 0.6, z - 6.0), Vector3(0.5, 2.2, 5.5), Color(0.25, 0.34, 0.43))

    # Elevated side routes and jump platforms.
    _box(self, "Left sky platform", Vector3(-6.2, 2.0, -12), Vector3(5.0, 0.55, 8.0), Color(0.43, 0.55, 0.65))
    _box(self, "Right sky platform", Vector3(6.2, 3.1, -31), Vector3(5.0, 0.55, 8.0), Color(0.43, 0.55, 0.65))
    _box(self, "High bridge", Vector3(0, 4.3, -55), Vector3(9.0, 0.6, 13.0), Color(0.42, 0.53, 0.65))
    _box(self, "Final terrace", Vector3(0, 0.6, -72), Vector3(18.0, 1.0, 12.0), Color(0.39, 0.52, 0.62))

    # Glowing psi crystals: movable physics objects for telekinesis.
    var crystal_mat := _mat(Color(0.12, 0.78, 1.0), 0.45, 0.2)
    for p in [Vector3(-3.0, 1.0, -8), Vector3(3.0, 1.2, -19), Vector3(-4.0, 1.0, -39), Vector3(4.0, 1.0, -49)]:
        var crystal := RigidBody3D.new()
        crystal.name = "PsiCrystal"
        crystal.position = p
        crystal.mass = 1.0
        crystal.linear_damp = 1.2
        crystal.angular_damp = 1.5
        add_child(crystal)
        var mesh := PrismMesh.new()
        mesh.size = Vector3(1.0, 1.6, 1.0)
        var visual := MeshInstance3D.new()
        visual.mesh = mesh
        visual.material_override = crystal_mat
        crystal.add_child(visual)
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = Vector3(0.9, 1.4, 0.9)
        shape.shape = box_shape
        crystal.add_child(shape)

    # Golden collectibles guide the player through the level.
    for i in range(8):
        _ring(self, Vector3(0, 1.55, -4.0 - float(i) * 5.5))
    for p in [Vector3(-6.2, 3.0, -12), Vector3(6.2, 4.1, -31), Vector3(0, 5.3, -55)]:
        _ring(self, p)

    # A luminous goal gate at the end of the route.
    var gate := _box(self, "Goal gate", Vector3(0, 3.1, -77), Vector3(8.5, 6.0, 0.5), Color(0.08, 0.58, 0.86), false, 0.35)
    var gate_mesh := gate as MeshInstance3D
    gate_mesh.material_override.emission_enabled = true
    gate_mesh.material_override.emission = Color(0.05, 0.55, 1.0)
    gate_mesh.material_override.emission_energy_multiplier = 2.0
