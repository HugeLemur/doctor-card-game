extends Panel

var card_data: Dictionary

@onready var title_label = $VBoxContainer/Title
@onready var description_label = $VBoxContainer/Description

func setup(data: Dictionary):
	card_data = data
	title_label.text = data.get("name", "Nepoznata kartica")
	description_label.text = data.get("description", "")