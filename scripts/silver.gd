extends CharacterBody3D

const WALK_SPEED := 9.0
const BOOST_SPEED := 18.0
const JUMP_SPEED := 9.5
const GRAVITY := 25.0
const PSI_RANGE := 16.0

var visual: Node3D
var camera: Camera3D
var held: RigidBody3D
var controls: Dictionary = {}
var hud: Control
var ring_count := 0
var run_time := 0.0
var boost_time := 0.0
var is_sliding := false
var psi_cooldown := 0.0
var base_camera_offset := Vector3(0, 4.2, 9.5)

func _ready() -> void:
    name = "Silver"
    _make_character()
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.9
    collision.shape = capsule
    collision.position.y = 0.95
    add_child(collision)

    camera = Camera3D.new()
    camera.position = base_camera_offset
    camera.current = true
    camera.fov = 78.0
    camera.near = 0.08
    add_child(camera)
    camera.look_at(global_position + Vector3(0, 1.2, -3.0))

    _make_touch_ui()

func _mat(c: Color, metal: float = 0.0, rough: float = 0.42) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = rough
    return m

func _ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, color: Color, metal: float = 0.0) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    var n := MeshInstance3D.new()
    n.mesh = mesh
    n.scale = size
    n.position = pos
    n.material_override = _mat(color, metal)
    parent.add_child(n)
    return n

func _cone(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rotation: Vector3) -> void:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.015
    mesh.bottom_radius = 0.34
    mesh.height = 1.0
    var n := MeshInstance3D.new()
    n.mesh = mesh
    n.scale = size
    n.position = pos
    n.rotation_degrees = rotation
    n.material_override = _mat(color)
    parent.add_child(n)

func _make_character() -> void:
    visual = Node3D.new()
    add_child(visual)
    var fur := Color(0.72, 0.83, 0.92)
    var pale := Color(0.94, 0.97, 1.0)
    var cyan := Color(0.04, 0.76, 1.0)
    var gold := Color(1.0, 0.73, 0.12)
    var red := Color(0.82, 0.12, 0.18)

    # Compact stylized hedgehog silhouette with a swept-back crest.
    _ellipsoid(visual, Vector3(0, 1.13, 0), Vector3(0.78, 1.05, 0.62), fur)
    _ellipsoid(visual, Vector3(0, 1.98, -0.02), Vector3(0.96, 0.94, 0.82), fur)
    _ellipsoid(visual, Vector3(0, 1.79, -0.40), Vector3(0.66, 0.30, 0.20), pale)
    _ellipsoid(visual, Vector3(0, 1.98, -0.405), Vector3(0.70, 0.37, 0.16), pale)
    _ellipsoid(visual, Vector3(-0.19, 2.08, -0.49), Vector3(0.25, 0.32, 0.09), Color.WHITE)
    _ellipsoid(visual, Vector3(0.19, 2.08, -0.49), Vector3(0.25, 0.32, 0.09), Color.WHITE)
    _ellipsoid(visual, Vector3(-0.17, 2.08, -0.555), Vector3(0.105, 0.23, 0.045), cyan)
    _ellipsoid(visual, Vector3(0.21, 2.08, -0.555), Vector3(0.105, 0.23, 0.045), cyan)
    _ellipsoid(visual, Vector3(0, 1.91, -0.59), Vector3(0.13, 0.10, 0.10), Color(0.12, 0.15, 0.2))

    # Five long swept quills and two side tufts.
    _cone(visual, Vector3(0, 2.62, 0.25), Vector3(0.85, 1.45, 0.8), fur, Vector3(-52, 0, 0))
    _cone(visual, Vector3(-0.35, 2.50, 0.26), Vector3(0.70, 1.20, 0.72), fur, Vector3(-48, 0, -23))
    _cone(visual, Vector3(0.35, 2.50, 0.26), Vector3(0.70, 1.20, 0.72), fur, Vector3(-48, 0, 23))
    _cone(visual, Vector3(-0.58, 2.18, 0.10), Vector3(0.56, 0.95, 0.62), fur, Vector3(-12, 0, -48))
    _cone(visual, Vector3(0.58, 2.18, 0.10), Vector3(0.56, 0.95, 0.62), fur, Vector3(-12, 0, 48))

    # Arms, gloves, cuffs, legs and red hover shoes.
    for side in [-1.0, 1.0]:
        _ellipsoid(visual, Vector3(side * 0.54, 1.34, -0.02), Vector3(0.28, 0.60, 0.30), fur)
        _ellipsoid(visual, Vector3(side * 0.62, 0.98, -0.12), Vector3(0.32, 0.34, 0.32), pale)
        _ellipsoid(visual, Vector3(side * 0.62, 1.55, -0.02), Vector3(0.38, 0.15, 0.38), gold, 0.35)
        _ellipsoid(visual, Vector3(side * 0.27, 0.39, 0.02), Vector3(0.30, 0.60, 0.30), fur)
        _ellipsoid(visual, Vector3(side * 0.27, 0.12, -0.18), Vector3(0.55, 0.25, 0.82), red)
        _ellipsoid(visual, Vector3(side * 0.27, 0.05, -0.22), Vector3(0.56, 0.10, 0.80), Color(0.16, 0.19, 0.25))
        _ellipsoid(visual, Vector3(side * 0.27, 0.30, -0.10), Vector3(0.46, 0.10, 0.34), pale)

    # Cyan psi cuffs glow against the gloves.
    for side in [-1.0, 1.0]:
        var cuff := _ellipsoid(visual, Vector3(side * 0.62, 1.55, -0.02), Vector3(0.40, 0.08, 0.40), cyan, 0.45)
        cuff.material_override.emission_enabled = true
        cuff.material_override.emission = cyan
        cuff.material_override.emission_energy_multiplier = 1.1

func _make_touch_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(hud)

    var title := Label.new()
    title.text = "SILVER  •  PSYCHIC HEDGEHOG"
    title.position = Vector2(24, 18)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
    hud.add_child(title)

    var rings := Label.new()
    rings.name = "RingCounter"
    rings.text = "RINGS  0"
    rings.position = Vector2(24, 52)
    rings.add_theme_font_size_override("font_size", 20)
    rings.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
    hud.add_child(rings)

    var hint := Label.new()
    hint.text = "PSI: tap to lift • tap again to throw"
    hint.anchor_left = 0.5
    hint.anchor_right = 0.5
    hint.anchor_top = 1.0
    hint.anchor_bottom = 1.0
    hint.offset_left = -190
    hint.offset_right = 190
    hint.offset_top = -42
    hint.offset_bottom = -12
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_font_size_override("font_size", 16)
    hint.add_theme_color_override("font_color", Color(0.78, 0.9, 1.0))
    hud.add_child(hint)

    _button("◀", Vector2(24, -112), Vector2(0, 1), Vector2(0, 1), "left")
    _button("▶", Vector2(112, -112), Vector2(0, 1), Vector2(0, 1), "right")
    _button("▲", Vector2(68, -200), Vector2(0, 1), Vector2(0, 1), "forward")
    _button("▼", Vector2(68, -24), Vector2(0, 1), Vector2(0, 1), "back")
    _button("JUMP", Vector2(-190, -112), Vector2(1, 1), Vector2(1, 1), "jump", Vector2(82, 66))
    _button("BOOST", Vector2(-282, -112), Vector2(1, 1), Vector2(1, 1), "boost", Vector2(82, 66))
    _button("PSI", Vector2(-190, -196), Vector2(1, 1), Vector2(1, 1), "psi", Vector2(82, 66))

func _button(text_value: String, offset: Vector2, anchor: Vector2, anchor2: Vector2, action: String, size: Vector2 = Vector2(72, 72)) -> void:
    var b := Button.new()
    b.text = text_value
    b.anchor_left = anchor.x
    b.anchor_right = anchor2.x
    b.anchor_top = anchor.y
    b.anchor_bottom = anchor2.y
    b.offset_left = offset.x
    b.offset_top = offset.y
    b.offset_right = offset.x + size.x
    b.offset_bottom = offset.y + size.y
    b.add_theme_font_size_override("font_size", 18)
    b.modulate = Color(0.8, 0.94, 1.0, 0.92)
    b.button_down.connect(func(): controls[action] = true)
    b.button_up.connect(func(): controls[action] = false)
    hud.add_child(b)

func add_ring() -> void:
    ring_count += 1
    var label := hud.get_node_or_null("RingCounter") as Label
    if label:
        label.text = "RINGS  %d" % ring_count

func _physics_process(delta: float) -> void:
    run_time += delta
    psi_cooldown = maxf(0.0, psi_cooldown - delta)
    var x := float(controls.get("right", false)) - float(controls.get("left", false))
    var z := float(controls.get("back", false)) - float(controls.get("forward", false))
    if Input.is_key_pressed(KEY_A): x -= 1.0
    if Input.is_key_pressed(KEY_D): x += 1.0
    if Input.is_key_pressed(KEY_W): z -= 1.0
    if Input.is_key_pressed(KEY_S): z += 1.0

    var direction := Vector2(x, z).limit_length()
    var boosting := bool(controls.get("boost", false)) or Input.is_key_pressed(KEY_SHIFT)
    var target_speed := BOOST_SPEED if boosting else WALK_SPEED
    var desired := Vector3(direction.x, 0, direction.y) * target_speed
    velocity.x = move_toward(velocity.x, desired.x, 36.0 * delta)
    velocity.z = move_toward(velocity.z, desired.z, 36.0 * delta)

    is_sliding = bool(controls.get("slide", false)) or Input.is_key_pressed(KEY_CTRL)
    if is_sliding:
        velocity.x *= 1.015
        velocity.z *= 1.015

    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif Input.is_key_pressed(KEY_SPACE) or bool(controls.get("jump", false)):
        velocity.y = JUMP_SPEED

    if direction.length() > 0.1:
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, -direction.y), delta * 10.0)

    if (Input.is_key_pressed(KEY_E) and not controls.get("psi_latched", false)) or (bool(controls.get("psi", false)) and not controls.get("psi_latched", false)):
        controls["psi_latched"] = true
        if psi_cooldown <= 0.0:
            _telekinesis()
            psi_cooldown = 0.28
    if not bool(controls.get("psi", false)) and not Input.is_key_pressed(KEY_E):
        controls["psi_latched"] = false

    if held and is_instance_valid(held):
        var target := global_position + Vector3(0, 2.35, -3.0).rotated(Vector3.UP, visual.rotation.y)
        held.linear_velocity = (target - held.global_position) * 5.5
        held.angular_velocity = Vector3(0.7, 1.0, 0.4)

    move_and_slide()
    var camera_target := global_position + base_camera_offset.rotated(Vector3.UP, visual.rotation.y)
    camera.global_position = camera.global_position.lerp(camera_target, minf(1.0, delta * 4.0))
    camera.look_at(global_position + Vector3(0, 1.1, -2.8).rotated(Vector3.UP, visual.rotation.y), Vector3.UP)

    var stride := sin(run_time * (17.0 if boosting else 11.0)) * minf(1.0, Vector2(velocity.x, velocity.z).length() / 4.0)
    if visual:
        visual.position.y = absf(stride) * (0.10 if is_on_floor() else 0.025)
        visual.rotation.z = lerpf(visual.rotation.z, -0.12 if is_sliding else 0.0, delta * 8.0)
        for i in range(visual.get_child_count()):
            var part := visual.get_child(i) as Node3D
            if part and i >= visual.get_child_count() - 12 and i < visual.get_child_count() - 8:
                part.rotation.x = stride * 0.22

func _telekinesis() -> void:
    if held and is_instance_valid(held):
        held.freeze = false
        held.apply_central_impulse(-visual.global_transform.basis.z * 22.0 + Vector3.UP * 7.0)
        held = null
        return

    var forward := -visual.global_transform.basis.z
    var closest: RigidBody3D
    var best := PSI_RANGE
    for node in get_parent().get_children():
        if node is RigidBody3D and not node.freeze:
            var offset: Vector3 = node.global_position - global_position
            var distance := offset.length()
            if distance < best and distance > 1.0 and forward.dot(offset.normalized()) > 0.15:
                best = distance
                closest = node
    if closest:
        held = closest
        held.sleeping = false
        held.linear_velocity = Vector3.ZERO
