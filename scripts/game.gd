extends Control

@onready var patient_info_panel = $MarginContainer/VBoxContainer/TopBar/PatientInfoPanel
@onready var record_button = $MarginContainer/VBoxContainer/TopBar/MedicalRecordButton
@onready var card_zone = $MarginContainer/VBoxContainer/MainArea/CardZone
@onready var response_panel = $MarginContainer/VBoxContainer/MainArea/ResponsePanel
@onready var end_turn_button = $MarginContainer/VBoxContainer/ActionBar/EndTurnButton
@onready var confirm_diagnosis_button = $MarginContainer/VBoxContainer/ActionBar/ConfirmDiagnosisButton
@onready var refer_button = $MarginContainer/VBoxContainer/ActionBar/ReferButton

func _ready():
	print("🎮 Game scene loaded and ready!")

	# Test placeholder kartice - možeš kasnije obrisati
	card_zone.add_child(create_card_placeholder("Da li imate kašalj?"))
	card_zone.add_child(create_card_placeholder("Uradite EKG"))
	card_zone.add_child(create_card_placeholder("Uzmite uzorak krvi"))

func create_card_placeholder(text: String) -> Control:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 100)

	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	card.add_child(label)
	return card
