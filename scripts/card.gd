extends Panel

signal card_clicked(data)
signal card_activated(data) # Novi signal za dupli klik

var card_data: Dictionary

@onready var title_label = $VBoxContainer/Title
@onready var description_label = $VBoxContainer/Description

func setup(data: Dictionary):
	card_data = data

	if title_label:
		title_label.text = data.get("name", "Nepoznata kartica")
	else:
		push_error("❌ title_label je null – proveri VBoxContainer/Title!")

	if description_label:
		description_label.text = data.get("description", "")
	else:
		push_error("❌ description_label je null – proveri VBoxContainer/Description!")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			emit_signal("card_activated", card_data)
		else:
			emit_signal("card_clicked", card_data)
