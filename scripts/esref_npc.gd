extends CharacterBody3D

# Cihanşah - Teşkilât Reisi Eşref Bey NPC Kontrolcüsü
# Oyuncu yaklaştığında etkileşim ışıldaması ve diyalog başlatıcı

@onready var label: Label3D = $NameLabel
@onready var visual: Node3D = $Visual
var anim_player: AnimationPlayer = null

const CharacterStyler = preload("res://scripts/character_styler.gd")

var is_player_near: bool = false

func _ready() -> void:
	add_to_group("interactables")
	update_label(false)
	CharacterStyler.style_character(self, "pasha")
	
	if has_node("Visual/SoldierModel/AnimationPlayer"):
		anim_player = get_node("Visual/SoldierModel/AnimationPlayer")
		if anim_player.has_animation("Idle"):
			anim_player.play("Idle")

func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		var dist = global_position.distance_to(p.global_position)
		if dist < 4.8:
			if not is_player_near:
				is_player_near = true
				update_label(true)
		else:
			if is_player_near:
				is_player_near = false
				update_label(false)

func update_label(active: bool) -> void:
	if not label:
		return
	if active:
		label.text = "★ Eşref Bey (Teşkilât Reisi) ★\n[ 'E' veya 'Konuş' Butonuna Dokun ]"
		label.modulate = Color(1.0, 0.9, 0.2)
		label.outline_modulate = Color(0.4, 0.1, 0.0)
	else:
		label.text = "Eşref Bey (Teşkilât Reisi)\n[Konuşmak için yaklaş]"
		label.modulate = Color(0.9, 0.82, 0.6)
		label.outline_modulate = Color(0.1, 0.1, 0.1)

func interact(_player: Node3D) -> void:
	var gm = get_tree().get_first_node_in_group("game_manager")
	if gm and gm.has_method("open_esref_bey_dialogue"):
		gm.open_esref_bey_dialogue()
