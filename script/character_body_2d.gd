extends CharacterBody2D


var health = 100
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


func _physics_process(delta):
	var collision_info = move_and_collide(velocity)
	if collision_info:
		if collision_info.get_collider().get_class() == "CharacterBody2D":
			health -= 25
			print(health)
			


