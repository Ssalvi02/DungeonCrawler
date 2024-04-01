extends CharacterBody3D

var revolver = load("res://Scenes/Weapons/WeaponRevolver.tscn")
var pistol = load("res://Scenes/Weapons/WeaponPistol.tscn")
var sshotgun = load("res://Scenes/Weapons/WeaponSuperShotgun.tscn")
var autorifle = load("res://Scenes/Weapons/WeaponAutoRifle.tscn")

signal add_ammo(ammo_amount) 

@onready var raycastgun = $Camera3D/RayCast3D

@export_category("Attributes")
@export var move_speed = 5.0

@onready var weapons = {
	"pistol": pistol,
	"revolver": revolver,
	"supershotgun": sshotgun,
	"autorifle": autorifle
}
var gun
@export var current_gun = ""

const MOUSE_SENS = 0.1
const JOY_SENS = 0.05

var can_shoot = true
var dead = false

var pickups

func _ready():
	pickups = get_tree().get_nodes_in_group("pickup")
	
	for i in pickups:
		i.can_pickup.connect(_on_can_pickup)
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	instantiate_gun("pistol")

func _input(event):
	if(dead):
		return
	if event is InputEventMouseMotion:
		rotation_degrees.y -= event.relative.x * MOUSE_SENS
		$Camera3D.rotation_degrees.x -= event.relative.y * MOUSE_SENS

func _process(delta):
	if(Input.is_action_just_pressed("exit")):
		get_tree().quit()
	if dead:
		return
	
	joystick_controller_camera()

func joystick_controller_camera():
	$Camera3D.rotate_x(Input.get_action_strength("look_up") * JOY_SENS)
	$Camera3D.rotate_x(Input.get_action_strength("look_down") * JOY_SENS * -1)
	rotate_y(Input.get_action_strength("look_left") * JOY_SENS)
	rotate_y(Input.get_action_strength("look_right") * JOY_SENS * -1)
	pass

func _physics_process(delta):
	if dead:
		return
	var input_dir = Input.get_vector("move_left", "move_right", "move_foward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	move_and_slide()

func restart():
	get_tree().reload_current_scene()

func instantiate_gun(gunName):
	current_gun = gunName
	gun = weapons.get(gunName).instantiate()
	add_child(gun)

func shoot_anim_done():
	can_shoot = true

func kill():
	dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE 


func _on_can_pickup(pickup):
	
	if (pickup.is_in_group("consumables")):
		if(current_gun == pickup.pickup_name):
			add_ammo.emit(pickup.ammo_value)
			pickup.queue_free()

	if (pickup.is_in_group("weapons") and 
	Input.is_action_just_pressed("interact")):
		gun.queue_free()
		pickup.queue_free()
		instantiate_gun(pickup.pickup_name)
