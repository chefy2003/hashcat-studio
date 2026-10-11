class_name Interactable3D
extends StaticBody3D

## Base interactive component for the 3D Cyber Deck.
## Inherits StaticBody3D so it provides native physical collision solidity,
## clean instantiation in Godot 4, and direct RayCast3D detection.

signal interacted(actor: Node3D)
signal focused()
signal unfocused()

# Текстът, който ще излиза динамично на екрана при поглед
@export var prompt_message: String = "Взаимодействие"

## Optional callable for fast signal-free hooking
var interact_callable: Callable

func get_prompt() -> String:
	return prompt_message

# Извиква се при натискане на [E]
func interact(actor: Node3D) -> void:
	if interact_callable.is_valid():
		interact_callable.call(actor)
	interacted.emit(actor)

# Визуален хайлайт (неон/шейдър) при насочване на погледа
func on_focus_entered() -> void:
	focused.emit()

func on_focus_exited() -> void:
	unfocused.emit()
