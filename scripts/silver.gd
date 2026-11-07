extends CharacterBody3D

const SPEED := 8.0
const JUMP_SPEED := 8.5
const GRAVITY := 22.0
const PSI_RANGE := 12.0

var visual: Node3D
var camera: Camera3D
var held: RigidBody3D
var controls: Dictionary = {}

func _ready() -> void:
    _make_character()
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.9
    collision.shape = capsule
    collision.position.y = 0.95
    add_child(collision)

    camera = Camera3D.new()
    camera.position = Vector3(0, 4.0, 8.0)
    camera.current = true
    add_child(camera)
    camera.look_at(global_position + Vector3(0, 1.0, -2.0))

    _make_touch_ui()

func _mat(c: Color, metal: float = 0.0) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.metallic = metal
    m.roughness = 0.48
    return m

func _ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    var n := MeshInstance3D.new()
    n.mesh = mesh
    n.scale = size
    n.position = pos
    n.material_override = _mat(color)
    parent.add_child(n)

func _make_character() -> void:
    visual = Node3D.new()
    add_child(visual)
    var silver := Color(0.72, 0.82, 0.9)
    var white := Color(0.94, 0.97, 1.0)
    var cyan := Color(0.08, 0.78, 1.0)
    var gold := Color(1.0, 0.72, 0.12)
    var red := Color(0.8, 0.12, 0.17)
    _ellipsoid(visual, Vector3(0, 1.15, 0), Vector3(0.9, 1.2, 0.68), silver)
    _ellipsoid(visual, Vector3(0, 2.0, 0), Vector3(1.0, 1.0, 0.88), silver)
    _ellipsoid(visual, Vector3(0, 1.86, -0.39), Vector3(0.7, 0.34, 0.22), white)
    _ellipsoid(visual, Vector3(-0.2, 2.08, -0.39), Vector3(0.27, 0.36, 0.12), white)
    _ellipsoid(visual, Vector3(0.2, 2.08, -0.39), Vector3(0.27, 0.36, 0.12), white)
    _ellipsoid(visual, Vector3(-0.2, 2.08, -0.49), Vector3(0.11, 0.24, 0.05), cyan)
    _ellipsoid(visual, Vector3(0.2, 2.08, -0.49), Vector3(0.11, 0.24, 0.05), cyan)
    for i in range(5):
        var quill := MeshInstance3D.new()
        var cone := CylinderMesh.new()
        cone.top_radius = 0.015
        cone.bottom_radius = 0.32
        cone.height = 1.0
        quill.mesh = cone
        quill.scale = Vector3(0.65, 0.95, 0.65)
        quill.position = Vector3((float(i) - 2.0) * 0.22, 2.55, 0.28 + absf(float(i) - 2.0) * 0.08)
        quill.rotation_degrees = Vector3(-38, 0, (float(i) - 2.0) * -15.0)
        quill.material_override = _mat(silver)
        visual.add_child(quill)
    for side in [-1.0, 1.0]:
        _ellipsoid(visual, Vector3(side * 0.62, 1.28, 0), Vector3(0.32, 0.72, 0.32), white)
        _ellipsoid(visual, Vector3(side * 0.62, 1.62, 0), Vector3(0.42, 0.16, 0.42), gold)
        _ellipsoid(visual, Vector3(side * 0.28, 0.38, 0), Vector3(0.34, 0.72, 0.34), silver)
        _ellipsoid(visual, Vector3(side * 0.28, 0.1, -0.12), Vector3(0.55, 0.22, 0.8), red)

func _make_touch_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    _button(layer, "◀", Vector2(30, 560), "left")
    _button(layer, "▶", Vector2(110, 560), "right")
    _button(layer, "▲", Vector2(70, 480), "forward")
    _button(layer, "▼", Vector2(70, 640), "back")
    _button(layer, "JUMP", Vector2(1030, 560), "jump")
    _button(layer, "PSI", Vector2(1140, 480), "psi")
    var info := Label.new()
    info.text = "SILVER  |  MOVE • JUMP • TELEKINESIS"
    info.position = Vector2(20, 18)
    info.add_theme_font_size_override("font_size", 20)
    layer.add_child(info)

func _button(layer: CanvasLayer, text_value: String, pos: Vector2, action: String) -> void:
    var b := Button.new()
    b.text = text_value
    b.position = pos
    b.custom_minimum_size = Vector2(72, 64)
    b.button_down.connect(func(): controls[action] = true)
    b.button_up.connect(func(): controls[action] = false)
    layer.add_child(b)

func _physics_process(delta: float) -> void:
    var x := float(controls.get("right", false)) - float(controls.get("left", false))
    var z := float(controls.get("back", false)) - float(controls.get("forward", false))
    if Input.is_key_pressed(KEY_A): x -= 1.0
    if Input.is_key_pressed(KEY_D): x += 1.0
    if Input.is_key_pressed(KEY_W): z -= 1.0
    if Input.is_key_pressed(KEY_S): z += 1.0
    var direction := Vector2(x, z).limit_length()
    velocity.x = direction.x * SPEED
    velocity.z = direction.y * SPEED
    if not is_on_floor():
        velocity.y -= GRAVITY * delta
    elif Input.is_key_pressed(KEY_SPACE) or bool(controls.get("jump", false)):
        velocity.y = JUMP_SPEED
    if direction.length() > 0.1:
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, -direction.y), delta * 8.0)
    if (Input.is_key_pressed(KEY_E) and not controls.get("psi_latched", false)) or (bool(controls.get("psi", false)) and not controls.get("psi_latched", false)):
        controls["psi_latched"] = true
        _telekinesis()
    if not bool(controls.get("psi", false)):
        controls["psi_latched"] = false
    if held and is_instance_valid(held):
        var target := global_position + Vector3(0, 2.2, -2.8).rotated(Vector3.UP, visual.rotation.y)
        held.linear_velocity = (target - held.global_position) * 5.0
    move_and_slide()
    camera.global_position = camera.global_position.lerp(global_position + Vector3(0, 4.0, 8.0), delta * 3.0)
    camera.look_at(global_position + Vector3(0, 1.0, -1.5), Vector3.UP)

func _telekinesis() -> void:
    if held and is_instance_valid(held):
        held.apply_central_impulse(-global_transform.basis.z * 18.0 + Vector3.UP * 5.0)
        held = null
        return
    var closest: RigidBody3D
    var best := PSI_RANGE
    for node in get_parent().get_children():
        if node is RigidBody3D:
            var d := global_position.distance_to(node.global_position)
            if d < best:
                best = d
                closest = node
    held = closest
