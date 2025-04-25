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

	if patient_info_panel.has_method("set_patient_info"):
		patient_info_panel.set_patient_info("Petar Petrović", 45, "Muški", "Bol u grudima")
	else:
		push_error("❌ PatientInfoPanel nema funkciju 'set_patient_info'")

	add_card_to_zone({
		"name": "Postavite pitanje o bolu",
		"description": "Da li imate bol u grudima?",
		"type": "question"
	})

	add_card_to_zone({
		"name": "Uradite EKG",
		"description": "Proverava srčanu aktivnost pacijenta.",
		"type": "test"
	})

	add_card_to_zone({
		"name": "Prepišite paracetamol",
		"description": "Standardni tretman za temperaturu i bol.",
		"type": "treatment"
	})

func add_card_to_zone(data: Dictionary) -> void:
	var card_scene = preload("res://scenes/Card.tscn")
	var card = card_scene.instantiate()
	card.setup(data)
	card_zone.add_child(card)
