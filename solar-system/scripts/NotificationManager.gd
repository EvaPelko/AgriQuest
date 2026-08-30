class_name NotificationManager
extends Control

@export var notification_label: Label
@export var animation_player: AnimationPlayer


func show_notification(message: String) -> void:
	notification_label.text = message
	notification_label.visible = true

	animation_player.stop()
	animation_player.play("notification")
