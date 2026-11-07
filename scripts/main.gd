extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/silver.gd")
const ROAD := Color(0.105, 0.13, 0.17)
const CONCRETE := Color(0.34, 0.38, 0.42)
const DARK_GLASS := Color(0.025, 0.12, 0.18)
const GOLD := Color(1.0, 0.72, 0.12)

func _ready() -> void:
    _build_environment()
    _build_city()
    _build_route()
    var silver := CharacterBody3D.new()
    silver.name = "Silver"
    silver.set_script(PLAYER_SCRIPT)
    silver.position = Vector3(0, 0.15, 18)
    add_child(silver)

func _material(color: Color, metal: float = 0.0, rough: float = 0.65, glow: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    if glow:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.5
    return m

func _block(parent: Node3D, name: String, pos: Vector3, size: Vector3, color: Color, collision: bool = true, metal: float = 0.0) -> Node3D:
    var holder: Node3D = parent
    if collision:
        var body := StaticBody3D.new()
        body.name = name
        parent.add_child(body)
        holder = body
    var mesh := BoxMesh.new()
    mesh.size = size
    var visual := MeshInstance3D.new()
    visual.name = name + "Visual"
    visual.mesh = mesh
    visual.material_override = _material(color, metal)
    visual.position = pos
    holder.add_child(visual)
    if collision:
        var shape := CollisionShape3D.new()
        var box := BoxShape3D.new()
        box.size = size
        shape.shape = box
        shape.position = pos
        holder.add_child(shape)
    return holder if collision else visual

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.position = pos
    node.material_override = _material(color, 0.15, 0.8)
    parent.add_child(node)

func _environment() -> Environment:
    var env := Environment.new()
    env.background_mode = Environment.BG_SKY
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.012, 0.035, 0.09)
    sky_mat.sky_horizon_color = Color(0.38, 0.23, 0.19)
    sky_mat.ground_bottom_color = Color(0.035, 0.04, 0.055)
    sky_mat.ground_horizon_color = Color(0.24, 0.17, 0.16)
    sky_mat.sun_angle_max = 18.0
    sky.sky_material = sky_mat
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.56, 0.62, 0.78)
    env.ambient_light_energy = 0.65
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    env.glow_enabled = true
    env.glow_intensity = 0.45
    return env

func _build_environment() -> void:
    var world := WorldEnvironment.new()
    world.environment = _environment()
    add_child(world)
    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-34, -24, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)
    var fill := OmniLight3D.new()
    fill.position = Vector3(0, 18, -48)
    fill.light_color = Color(0.28, 0.48, 1.0)
    fill.light_energy = 2.0
    fill.omni_range = 65
    add_child(fill)
    # Distant skyline silhouettes make the city feel much larger than the playable street.
    for i in range(24):
        var side := -1.0 if i % 2 == 0 else 1.0
        var z := -float(i) * 12.0 - 12.0
        var h := 18.0 + float((i * 7) % 17)
        _block(self, "Distant tower", Vector3(side * (38.0 + float(i % 4) * 5.0), h * 0.5 - 2.0, z), Vector3(9.0, h, 8.0), Color(0.07, 0.09, 0.14), false)

func _building(x: float, z: float, width: float, height: float, depth: float, damaged: bool) -> void:
    var base := Vector3(x, height * 0.5 - 0.2, z)
    var tint := Color(0.22, 0.25, 0.31) if not damaged else Color(0.28, 0.24, 0.23)
    _block(self, "Ruined city building", base, Vector3(width, height, depth), tint, true)
    var rows := int(height / 3.0)
    var cols := int(width / 2.2)
    for row in range(rows):
        for col in range(cols):
            if damaged and ((row * 3 + col * 5 + int(absf(x))) % 7 == 0):
                continue
            var wx := x - width * 0.5 + 1.1 + float(col) * 2.2
            var wy := 1.8 + float(row) * 3.0
            var window_color := Color(0.08, 0.34, 0.48) if (row + col) % 3 else Color(0.72, 0.32, 0.16)
            _block(self, "Window", Vector3(wx, wy, z - depth * 0.5 - 0.035), Vector3(1.15, 1.65, 0.08), window_color, false)
    if damaged:
        _block(self, "Collapsed facade", Vector3(x + width * 0.28, height * 0.72, z - depth * 0.55), Vector3(width * 0.45, 1.2, 1.1), Color(0.12, 0.13, 0.16), false)
        _block(self, "Broken ledge", Vector3(x - width * 0.3, height * 0.48, z - depth * 0.56), Vector3(width * 0.55, 0.45, 1.4), CONCRETE, false)

func _build_city() -> void:
    for i in range(8):
        var z := -12.0 - float(i) * 21.0
        _building(-18.0 - float(i % 2) * 3.0, z, 12.0, 23.0 + float(i % 3) * 6.0, 12.0, i % 2 == 0)
        _building(18.0 + float((i + 1) % 2) * 3.0, z - 8.0, 13.0, 28.0 + float((i + 1) % 3) * 5.0, 13.0, i % 2 == 1)
    # Snapped elevated highway and broken overpass.
    _block(self, "Overpass left", Vector3(-9.5, 9.0, -64), Vector3(18.0, 1.2, 18.0), Color(0.26, 0.29, 0.34))
    _block(self, "Overpass right", Vector3(10.0, 10.0, -75), Vector3(15.0, 1.2, 16.0), Color(0.26, 0.29, 0.34))
    _block(self, "Broken highway slab", Vector3(0.0, 8.0, -69), Vector3(8.0, 0.8, 7.0), Color(0.31, 0.32, 0.34), false)
    # Smoke plumes in the far skyline.
    for p in [Vector3(-26, 12, -44), Vector3(27, 15, -91), Vector3(-31, 18, -130)]:
        _cylinder(self, p, 2.8, 17.0, Color(0.12, 0.13, 0.16, 0.38))

func _ring(pos: Vector3) -> void:
    var area := Area3D.new()
    area.position = pos
    add_child(area)
    var torus := TorusMesh.new()
    torus.inner_radius = 0.28
    torus.outer_radius = 0.43
    var mesh := MeshInstance3D.new()
    mesh.mesh = torus
    mesh.material_override = _material(GOLD, 0.8, 0.2, true)
    area.add_child(mesh)
    var shape := CollisionShape3D.new()
    var sphere := SphereShape3D.new()
    sphere.radius = 0.7
    shape.shape = sphere
    area.add_child(shape)
    area.body_entered.connect(func(body: Node3D):
        if body.has_method("add_ring"):
            body.add_ring()
            area.queue_free()
    )

func _boost_pad(pos: Vector3, direction: Vector3) -> void:
    var area := Area3D.new()
    area.position = pos
    add_child(area)
    var mesh := BoxMesh.new()
    mesh.size = Vector3(3.0, 0.16, 2.5)
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = _material(Color(0.05, 0.72, 1.0), 0.4, 0.2, true)
    area.add_child(visual)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(3.2, 1.0, 2.7)
    shape.shape = box
    area.add_child(shape)
    area.body_entered.connect(func(body: Node3D):
        if body is CharacterBody3D:
            body.velocity += direction.normalized() * 18.0 + Vector3.UP * 2.0
    )

func _psi_crate(pos: Vector3) -> void:
    var crate := RigidBody3D.new()
    crate.name = "PsiCrate"
    crate.position = pos
    crate.mass = 1.8
    crate.linear_damp = 1.3
    crate.angular_damp = 1.8
    add_child(crate)
    var mesh := BoxMesh.new()
    mesh.size = Vector3(1.5, 1.5, 1.5)
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = _material(Color(0.08, 0.48, 0.72), 0.45, 0.25, true)
    crate.add_child(visual)
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(1.5, 1.5, 1.5)
    shape.shape = box
    crate.add_child(shape)

func _build_route() -> void:
    _block(self, "Main asphalt road", Vector3(0, -0.65, -62), Vector3(17.0, 1.0, 170.0), ROAD)
    _block(self, "Left pavement", Vector3(-10.0, -0.28, -62), Vector3(3.0, 0.5, 170.0), CONCRETE)
    _block(self, "Right pavement", Vector3(10.0, -0.28, -62), Vector3(3.0, 0.5, 170.0), CONCRETE)
    for i in range(18):
        _block(self, "Road lane marking", Vector3(0, -0.12, 15.0 - float(i) * 9.0), Vector3(0.22, 0.035, 4.0), Color(0.82, 0.75, 0.54), false)
    # Barriers, broken cars, rubble and jumps create a recognisable ruined street.
    for z in [-12.0, -28.0, -47.0, -88.0, -112.0]:
        _block(self, "Concrete road barrier", Vector3(-6.7, 0.45, z), Vector3(1.0, 1.3, 5.0), Color(0.38, 0.35, 0.31))
    for z in [-20.0, -39.0, -58.0, -101.0]:
        _block(self, "Road wreck", Vector3(4.5, 0.65, z), Vector3(2.4, 1.25, 4.0), Color(0.24, 0.12, 0.1), true, 0.25)
        _block(self, "Wreck window", Vector3(4.5, 1.35, z - 0.2), Vector3(1.8, 0.4, 2.1), DARK_GLASS, false)
    # A collapsed ramp, elevated route and a long final jump.
    _block(self, "Ramp base", Vector3(-3.8, 0.45, -48), Vector3(5.5, 0.8, 8.0), Color(0.4, 0.43, 0.47))
    var ramp := _block(self, "Ramp", Vector3(-3.8, 1.5, -51), Vector3(5.5, 0.55, 7.0), Color(0.48, 0.49, 0.5))
    ramp.rotation.x = deg_to_rad(-17.0)
    _block(self, "High route platform", Vector3(5.0, 5.0, -82), Vector3(8.0, 0.7, 13.0), Color(0.38, 0.43, 0.49))
    _block(self, "High route landing", Vector3(0.0, 3.1, -103), Vector3(9.0, 0.7, 9.0), Color(0.38, 0.43, 0.49))
    for i in range(5):
        _ring(Vector3(0, 1.25, 8.0 - float(i) * 4.8))
    for p in [Vector3(-3.8, 2.5, -50), Vector3(5.0, 6.2, -82), Vector3(0, 4.2, -103), Vector3(0, 1.4, -128)]:
        _ring(p)
    for p in [Vector3(-2.0, 0.1, -8), Vector3(2.5, 0.1, -35), Vector3(-1.0, 0.1, -91)]:
        _boost_pad(p, Vector3(0, 0, -1))
    for p in [Vector3(-3.0, 1.5, -17), Vector3(3.5, 1.5, -43), Vector3(-4.0, 1.5, -72), Vector3(3.0, 1.5, -116)]:
        _psi_crate(p)
    # End gate is an actual arch made of two pillars and a lintel.
    _block(self, "Goal pillar L", Vector3(-3.5, 2.4, -137), Vector3(0.7, 4.8, 0.8), Color(0.05, 0.56, 0.88), true, 0.4)
    _block(self, "Goal pillar R", Vector3(3.5, 2.4, -137), Vector3(0.7, 4.8, 0.8), Color(0.05, 0.56, 0.88), true, 0.4)
    _block(self, "Goal lintel", Vector3(0, 4.7, -137), Vector3(7.7, 0.7, 0.8), Color(0.05, 0.56, 0.88), true, 0.4)
    var finish := Area3D.new()
    finish.position = Vector3(0, 2.0, -138)
    add_child(finish)
    var finish_shape := CollisionShape3D.new()
    var finish_box := BoxShape3D.new()
    finish_box.size = Vector3(7.0, 4.5, 1.5)
    finish_shape.shape = finish_box
    finish.add_child(finish_shape)
    finish.body_entered.connect(func(body: Node3D):
        if body.has_method("show_message"):
            body.show_message("CRISIS CITY  •  STAGE CLEAR")
    )
