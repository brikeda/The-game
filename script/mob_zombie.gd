extends CharacterBody2D
signal mob_death

var health
var speed
# Início das variáveis de controle do engatinhar do zombie:
# As hitboxes se movem junto das animações.
var crawl_speed = null
var crawl_timer_off = true
var getting_up
# Fim das variáveis de controle do engatinhar do zombie
var stunned = false
# Como não dá pra declarar delta, essa variável serve pra apontar para delta,
# pois têm funções que precisam dela
var deltaN

func _ready():
	health = 100
	speed = 100
	position = Vector2(2000, 500)
	$AnimatedSprite2D.play("walk")
	# Este signal faz o player avisar a sua posição para o mob a cada frame
	var player = get_node("/root/Main/Player_with_pistol/Player")
	player.player_position.connect(self._player_position)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	deltaN = delta
	
	if velocity.x < 0:
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
		
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		# Gambiarra alert: quando o zombie deita para engatinhar, na verdade é outro corpo,
		# que herda as propriedades anteriores então não tem problema
		$zombie_skeleton.visible = true
		$AnimatedSprite2D.visible = false
		$World_hitbox.set_deferred("disabled", true)
		$zombie_skeleton/AnimationPlayer2.play("lay_down")


func _on_body_entered(body):
	# body nesse caso é a bullet, que deixa de existir quando atinge o mob
	if body is RigidBody2D:
		body.queue_free()
		health -= 25
		print(health)


	# A mecânica de stun pode ser melhorada
	if health <= 50 and health > 0:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.play("hurt")
		stunned = true
		$Stun_timer.start()


	# Se morrer:
	if health <= 0:
		$AnimatedSprite2D.stop()
		$LightOccluder2D.visible = false
		$AnimationPlayer.play("dying")
		$Area2D/Shot_hitbox.set_deferred("disabled", true)
		$World_hitbox.set_deferred("disabled", true)


func _on_dying_animation_finish(anim_name):
	if anim_name == "dying":
		$AnimationPlayer.stop()
		self.queue_free()
		mob_death.emit()


func _player_position(pos):
	# O código abaixo tem que ser refatorado, tá uma bagunça
	if health > 0:
		# Se não estiver stunado, segue o player e se move
		if !stunned:
			var angle_to_player = self.get_angle_to(pos)
			velocity = Vector2(cos(angle_to_player), sin(angle_to_player))
			if velocity.length() > 0: 
				velocity = velocity.normalized()
			# deltaN no primeiro frame é null, por isso esse if
			if deltaN is float:
				# crawl_speed = null quando está de pé
				if crawl_speed is int:
					position += velocity * deltaN * crawl_speed
				# Pra não ficar resetando o timer:
				if crawl_speed is int and crawl_timer_off:
					$zombie_skeleton/Crawl_timer.start()
					crawl_timer_off = false
				# Pra quando não estiver engatinhando:
				elif !crawl_speed is int:  # else não funciona aqui por algum motivo
					position += velocity * deltaN * speed


func _on_stun_timer_timeout():
	stunned = false
	if health > 0:
		$AnimatedSprite2D.play("walk")


func _on_animation_player_2_animation_finished(anim_name):
	if anim_name == "lay_down" and !getting_up:
		crawl_speed = 10
		$zombie_skeleton/AnimationPlayer2.stop()
		$zombie_skeleton/AnimationPlayer2.play("crawl")
	elif anim_name == "lay_down" and getting_up:
		$zombie_skeleton.visible = false
		$AnimatedSprite2D.visible = true


func _on_crawl_timer_timeout():
	# Para parar de engatinhar:
	crawl_speed = null
	$zombie_skeleton/AnimationPlayer2.stop()
	# A animação de se levantar é a de deitar tocado ao contrário
	$zombie_skeleton/AnimationPlayer2.play_backwards("lay_down")
	# Variável para saber se está deitando ou levantando
	getting_up = true
