extends Panel

var card_data: Dictionary

@onready var title_label = $VBoxContainer/Title
@onready var description_label = $VBoxContainer/Description

func setup(data: Dictionary):
	card_data = data

	if title_label == null:
		push_error("❌ title_label je null – proveri VBoxContainer/Title!")
	else:
		title_label.text = data.get("name", "Nepoznata kartica")

	if description_label == null:
		push_error("❌ description_label je null – proveri VBoxContainer/Description!")
	else:
		description_label.text = data.get("description", "")
