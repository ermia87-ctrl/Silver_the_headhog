extends CharacterBody3D

const WALK_SPEED := 11.0
const BOOST_SPEED := 25.0
const GROUND_ACCEL := 58.0
const AIR_ACCEL := 22.0
const JUMP_SPEED := 11.8
const GRAVITY := 27.0
const PSI_RANGE := 19.0

var visual: Node3D
var camera: Camera3D
var camera_pivot: Node3D
var held: RigidBody3D
var hud: Control
var controls: Dictionary = {}
var ring_count := 0
var run_time := 0.0
var is_sliding := false
var hover_fuel := 0.0
var psi_latched := false
var psi_cooldown := 0.0
var message_timer := 0.0
var move_dir := Vector3.ZERO
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var status_label: Label

func _ready() -> void:
    name = "Silver"
    _make_character()
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.43
    capsule.height = 1.95
    collision.shape = capsule
    collision.position.y = 0.98
    add_child(collision)
    camera_pivot = Node3D.new()
    camera_pivot.position = Vector3(0, 2.5, 0)
    add_child(camera_pivot)
    camera = Camera3D.new()
    camera.position = Vector3(0, 3.1, 9.2)
    camera.fov = 76.0
    camera.near = 0.08
    camera.current = true
    camera_pivot.add_child(camera)
    camera.look_at(global_position + Vector3(0, 1.4, -4.0))
    _make_touch_ui()

func _mat(color: Color, metal: float = 0.0, rough: float = 0.42, glow: bool = false) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.metallic = metal
    m.roughness = rough
    if glow:
        m.emission_enabled = true
        m.emission = color
        m.emission_energy_multiplier = 1.7
    return m

func _ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.scale = size
    node.position = pos
    node.material_override = material
    parent.add_child(node)
    return node

func _spike(parent: Node3D, pos: Vector3, size: Vector3, material: Material, tilt: Vector3) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.015
    mesh.bottom_radius = 0.34
    mesh.height = 1.0
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.scale = size
    node.position = pos
    node.rotation_degrees = tilt
    node.material_override = material
    parent.add_child(node)
    return node

func _make_character() -> void:
    visual = Node3D.new()
    add_child(visual)
    var fur := _mat(Color(0.76, 0.86, 0.94), 0.05, 0.36)
    var muzzle := _mat(Color(0.94, 0.96, 0.98), 0.0, 0.52)
    var cyan := _mat(Color(0.02, 0.76, 1.0), 0.35, 0.22, true)
    var gold := _mat(Color(1.0, 0.72, 0.12), 0.55, 0.22, true)
    var red := _mat(Color(0.78, 0.08, 0.14), 0.18, 0.28)
    var black := _mat(Color(0.018, 0.025, 0.04), 0.15, 0.18)
    var white := _mat(Color(1.0, 1.0, 1.0), 0.0, 0.2)

    # Body silhouette, chest and face.
    _ellipsoid(visual, Vector3(0, 1.05, 0.02), Vector3(0.78, 1.08, 0.62), fur)
    _ellipsoid(visual, Vector3(0, 1.20, -0.30), Vector3(0.57, 0.66, 0.28), muzzle)
    _ellipsoid(visual, Vector3(0, 2.02, -0.02), Vector3(1.0, 0.92, 0.86), fur)
    _ellipsoid(visual, Vector3(0, 1.76, -0.46), Vector3(0.67, 0.36, 0.28), muzzle)
    _ellipsoid(visual, Vector3(0, 1.91, -0.59), Vector3(0.15, 0.11, 0.12), black)

    # Large expressive eyes with cyan irises.
    for side in [-1.0, 1.0]:
        _ellipsoid(visual, Vector3(side * 0.22, 2.10, -0.48), Vector3(0.29, 0.39, 0.14), white)
        _ellipsoid(visual, Vector3(side * 0.19, 2.09, -0.605), Vector3(0.12, 0.25, 0.07), cyan)
        _ellipsoid(visual, Vector3(side * 0.19, 2.09, -0.66), Vector3(0.055, 0.18, 0.035), black)

    # Distinctive swept-back Silver quills and side tufts.
    _spike(visual, Vector3(0, 2.72, 0.30), Vector3(0.78, 1.52, 0.76), fur, Vector3(-53, 0, 0))
    _spike(visual, Vector3(-0.32, 2.58, 0.28), Vector3(0.66, 1.30, 0.68), fur, Vector3(-47, 0, -19))
    _spike(visual, Vector3(0.32, 2.58, 0.28), Vector3(0.66, 1.30, 0.68), fur, Vector3(-47, 0, 19))
    _spike(visual, Vector3(-0.62, 2.23, 0.12), Vector3(0.52, 1.00, 0.58), fur, Vector3(-8, 0, -48))
    _spike(visual, Vector3(0.62, 2.23, 0.12), Vector3(0.52, 1.00, 0.58), fur, Vector3(-8, 0, 48))

    # Separate articulated limbs, gloves, gold cuffs and hover shoes.
    left_arm = Node3D.new()
    right_arm = Node3D.new()
    left_arm.position = Vector3(-0.52, 1.50, 0)
    right_arm.position = Vector3(0.52, 1.50, 0)
    visual.add_child(left_arm)
    visual.add_child(right_arm)
    for arm in [left_arm, right_arm]:
        _ellipsoid(arm, Vector3(0, -0.25, 0), Vector3(0.30, 0.62, 0.32), fur)
        _ellipsoid(arm, Vector3(0, -0.57, -0.10), Vector3(0.34, 0.30, 0.34), muzzle)
        _ellipsoid(arm, Vector3(0, -0.04, 0), Vector3(0.40, 0.15, 0.40), gold)
        _ellipsoid(arm, Vector3(0, -0.04, 0), Vector3(0.43, 0.07, 0.43), cyan)

    left_leg = Node3D.new()
    right_leg = Node3D.new()
    left_leg.position = Vector3(-0.27, 0.56, 0.02)
    right_leg.position = Vector3(0.27, 0.56, 0.02)
    visual.add_child(left_leg)
    visual.add_child(right_leg)
    for leg in [left_leg, right_leg]:
        _ellipsoid(leg, Vector3(0, -0.13, 0), Vector3(0.31, 0.57, 0.32), fur)
        _ellipsoid(leg, Vector3(0, -0.40, -0.18), Vector3(0.57, 0.28, 0.78), red)
        _ellipsoid(leg, Vector3(0, -0.53, -0.20), Vector3(0.57, 0.10, 0.78), black)
        _ellipsoid(leg, Vector3(0, -0.29, -0.40), Vector3(0.36, 0.10, 0.16), muzzle)

func _make_touch_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(hud)
    var title := Label.new()
    title.text = "SILVER  |  CRISIS CITY"
    title.position = Vector2(22, 16)
    title.add_theme_font_size_override("font_size", 21)
    title.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
    hud.add_child(title)
    status_label = Label.new()
    status_label.text = "RINGS  0"
    status_label.position = Vector2(22, 48)
    status_label.add_theme_font_size_override("font_size", 20)
    status_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28))
    hud.add_child(status_label)
    var hint := Label.new()
    hint.text = "JUMP: hold to hover  •  PSI: lift / throw"
    hint.anchor_left = 0.5
    hint.anchor_right = 0.5
    hint.anchor_top = 1.0
    hint.anchor_bottom = 1.0
    hint.offset_left = -210
    hint.offset_right = 210
    hint.offset_top = -38
    hint.offset_bottom = -10
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
    hud.add_child(hint)
    _button("◀", Vector2(24, -108), Vector2(0, 1), "left")
    _button("▶", Vector2(112, -108), Vector2(0, 1), "right")
    _button("▲", Vector2(68, -192), Vector2(0, 1), "forward")
    _button("▼", Vector2(68, -24), Vector2(0, 1), "back")
    _button("JUMP", Vector2(-190, -108), Vector2(1, 1), "jump", Vector2(84, 66))
    _button("BOOST", Vector2(-286, -108), Vector2(1, 1), "boost", Vector2(88, 66))
    _button("PSI", Vector2(-190, -188), Vector2(1, 1), "psi", Vector2(84, 66))
    _button("SLIDE", Vector2(-286, -188), Vector2(1, 1), "slide", Vector2(88, 66))

func _button(caption: String, offset: Vector2, anchor: Vector2, action: String, size: Vector2 = Vector2(72, 72)) -> void:
    var b := Button.new()
    b.text = caption
    b.anchor_left = anchor.x
    b.anchor_right = anchor.x
    b.anchor_top = anchor.y
    b.anchor_bottom = anchor.y
    b.offset_left = offset.x
    b.offset_top = offset.y
    b.offset_right = offset.x + size.x
    b.offset_bottom = offset.y + size.y
    b.add_theme_font_size_override("font_size", 16)
    b.modulate = Color(0.82, 0.94, 1.0, 0.92)
    b.button_down.connect(func(): controls[action] = true)
    b.button_up.connect(func(): controls[action] = false)
    hud.add_child(b)

func add_ring() -> void:
    ring_count += 1
    status_label.text = "RINGS  %d" % ring_count

func show_message(message: String) -> void:
    status_label.text = message
    message_timer = 5.0

func _input_axis() -> Vector2:
    var x := float(controls.get("right", false)) - float(controls.get("left", false))
    var z := float(controls.get("back", false)) - float(controls.get("forward", false))
    if Input.is_key_pressed(KEY_A): x -= 1.0
    if Input.is_key_pressed(KEY_D): x += 1.0
    if Input.is_key_pressed(KEY_W): z -= 1.0
    if Input.is_key_pressed(KEY_S): z += 1.0
    return Vector2(x, z).limit_length()

func _physics_process(delta: float) -> void:
    run_time += delta
    psi_cooldown = maxf(0.0, psi_cooldown - delta)
    if message_timer > 0.0:
        message_timer -= delta
        if message_timer <= 0.0:
            status_label.text = "RINGS  %d" % ring_count

    var axis := _input_axis()
    var yaw := visual.rotation.y
    move_dir = Vector3(axis.x, 0, axis.y).normalized()
    var boosting := bool(controls.get("boost", false)) or Input.is_key_pressed(KEY_SHIFT)
    var target_speed := BOOST_SPEED if boosting else WALK_SPEED
    var target_velocity := move_dir * target_speed
    var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
    velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
    velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)

    is_sliding = bool(controls.get("slide", false)) or Input.is_key_pressed(KEY_CTRL)
    if is_sliding and is_on_floor():
        velocity.x *= 1.012
        velocity.z *= 1.012

    var jump_pressed := bool(controls.get("jump", false)) or Input.is_key_pressed(KEY_SPACE)
    if is_on_floor():
        hover_fuel = 0.85
        if jump_pressed:
            velocity.y = JUMP_SPEED
    else:
        velocity.y -= GRAVITY * delta
        if jump_pressed and hover_fuel > 0.0:
            velocity.y = maxf(velocity.y, 1.3)
            hover_fuel = maxf(0.0, hover_fuel - delta)

    if move_dir.length() > 0.08:
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-move_dir.x, -move_dir.z), delta * 9.0)

    var psi_pressed := bool(controls.get("psi", false)) or Input.is_key_pressed(KEY_E)
    if psi_pressed and not psi_latched and psi_cooldown <= 0.0:
        psi_latched = true
        _telekinesis()
        psi_cooldown = 0.25
    if not psi_pressed:
        psi_latched = false

    if held and is_instance_valid(held):
        var target := global_position + Vector3(0, 2.7, -3.2).rotated(Vector3.UP, visual.rotation.y)
        held.linear_velocity = (target - held.global_position) * 5.8
        held.angular_velocity = Vector3(0.4, 0.9, 0.25)

    move_and_slide()
    camera_pivot.global_position = camera_pivot.global_position.lerp(global_position + Vector3(0, 1.4, 0), minf(1.0, delta * 8.0))
    camera.look_at(global_position + Vector3(0, 1.2, -4.2), Vector3.UP)

    var speed := Vector2(velocity.x, velocity.z).length()
    var stride := sin(run_time * (19.0 if boosting else 12.0)) * minf(1.0, speed / 5.0)
    left_leg.rotation.x = stride * (0.75 if is_on_floor() else 0.2)
    right_leg.rotation.x = -stride * (0.75 if is_on_floor() else 0.2)
    left_arm.rotation.x = -stride * 0.38
    right_arm.rotation.x = stride * 0.38
    visual.position.y = absf(stride) * (0.07 if is_on_floor() else 0.02)
    visual.rotation.z = lerpf(visual.rotation.z, -0.22 if is_sliding else 0.0, delta * 8.0)

func _telekinesis() -> void:
    if held and is_instance_valid(held):
        held.freeze = false
        held.apply_central_impulse(-visual.global_transform.basis.z * 27.0 + Vector3.UP * 8.0)
        held = null
        return
    var forward := -visual.global_transform.basis.z
    var closest: RigidBody3D
    var best := PSI_RANGE
    for node in get_parent().get_children():
        if node is RigidBody3D and not node.freeze:
            var offset: Vector3 = node.global_position - global_position
            var distance := offset.length()
            if distance < best and distance > 1.0 and forward.dot(offset.normalized()) > 0.12:
                best = distance
                closest = node
    if closest:
        held = closest
        held.sleeping = false
        held.linear_velocity = Vector3.ZERO
