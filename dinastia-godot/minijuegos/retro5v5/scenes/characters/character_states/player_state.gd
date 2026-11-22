class_name PlayerState
extends Node

signal state_transition_requested(new_state: Player.State, state_data: PlayerStateData)

var ai_behavior : AIBehavior = null
var animation_player : AnimationPlayer = null
var ball : Ball = null
var player : Player = null
var state_data : PlayerStateData = PlayerStateData.new()
var teammate_detection_area : Area2D = null
var ball_detection_area : Area2D = null
var own_goal : Goal = null
var target_goal : Goal = null
var tackle_damage_emitter_area : Area2D = null

## `areas`: las áreas de detección, los arcos, la IA y el área de entrada (claves: teammate_detection_area, ball_detection_area,
## own_goal, target_goal, ai_behavior, tackle_damage_emitter_area). Se agrupan para no pasar 10 argumentos sueltos.
func setup(context_player: Player, context_data: PlayerStateData, context_animation_player: AnimationPlayer, context_ball: Ball, areas: Dictionary) -> void:
	player = context_player
	animation_player = context_animation_player
	state_data = context_data
	ball = context_ball
	teammate_detection_area = areas["teammate_detection_area"]
	ball_detection_area = areas["ball_detection_area"]
	own_goal = areas["own_goal"]
	target_goal = areas["target_goal"]
	ai_behavior = areas["ai_behavior"]
	tackle_damage_emitter_area = areas["tackle_damage_emitter_area"]


func transition_state(new_state: Player.State, new_state_data: PlayerStateData = PlayerStateData.new()) -> void:
	state_transition_requested.emit(new_state, new_state_data)

func on_animation_complete() -> void:
	pass

func can_carry_ball() -> bool:
	return false

func can_pass() -> bool:
	return false

func is_ready_for_kick() -> bool:
	return false
