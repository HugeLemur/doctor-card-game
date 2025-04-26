extends Control

# --- UI Node References ---
@onready var patient_info_panel = $MarginContainer/VBoxContainer/TopBar/PatientInfoPanel
@onready var record_button = $MarginContainer/VBoxContainer/TopBar/MedicalRecordButton
@onready var card_zone_tabs = $MarginContainer/VBoxContainer/MainArea/CardZone/TabContainer
@onready var communicate_tab = card_zone_tabs.get_node("CommunicateTab")
@onready var test_tab = card_zone_tabs.get_node("TestTab")
@onready var treatment_tab = card_zone_tabs.get_node("TreatmentTab")
@onready var response_panel = $MarginContainer/VBoxContainer/MainArea/ResponsePanel
@onready var end_turn_button = $MarginContainer/VBoxContainer/ActionBar/EndTurnButton
@onready var confirm_diagnosis_button = $MarginContainer/VBoxContainer/ActionBar/ConfirmDiagnosisButton
@onready var refer_button = $MarginContainer/VBoxContainer/ActionBar/ReferButton
@onready var diagnosis_popup = $MarginContainer/VBoxContainer/DiagnosisPopup
@onready var diagnosis_line_edit = $MarginContainer/VBoxContainer/DiagnosisPopup/PopupMargin/VBoxContainer/DiagnosisLineEdit
@onready var diagnosis_confirm_button = $MarginContainer/VBoxContainer/DiagnosisPopup/PopupMargin/VBoxContainer/DiagnosisConfirmButton

# --- Gameplay Variables ---
var selected_card: Control = null
var medical_record: Array = []

# --- Game Lifecycle ---
func _ready():
	print("🎮 Game scene loaded and ready!")

	confirm_diagnosis_button.pressed.connect(_on_confirm_diagnosis_pressed)
	diagnosis_confirm_button.pressed.connect(_on_diagnosis_confirmed)
	record_button.pressed.connect(show_medical_record)

	if patient_info_panel.has_method("set_patient_info"):
		patient_info_panel.set_patient_info("Petar Petrović", 45, "Muški", "Bol u grudima")
	else:
		push_error("❌ PatientInfoPanel nema funkciju 'set_patient_info'")

	# Dodavanje testnih kartica
	add_card_to_zone({
		"name": "Postavite pitanje o kašlju",
		"description": "Da li imate suv kašalj?",
		"type": "communicate"
	})

	add_card_to_zone({
		"name": "Uradite krvnu sliku",
		"description": "Proverava osnovne parametre u krvi.",
		"type": "test"
	})

	add_card_to_zone({
		"name": "Prepišite antibiotik",
		"description": "Tretman za bakterijske infekcije.",
		"type": "treatment"
	})

# --- Card Management ---
func add_card_to_zone(data: Dictionary) -> void:
	var card_scene = preload("res://scenes/Card.tscn")
	var card = card_scene.instantiate()

	match data.get("type", ""):
		"communicate":
			communicate_tab.add_child(card)
		"test":
			test_tab.add_child(card)
		"treatment":
			treatment_tab.add_child(card)
		_:
			print("⚠️ Nepoznat tip kartice:", data)

	card.setup(data)

	card.connect("card_clicked", Callable(self, "_on_card_clicked").bind(card))
	card.connect("card_activated", Callable(self, "_on_card_activated").bind(card))

# --- Card Interaction ---
func _on_card_clicked(data: Dictionary, card: Control) -> void:
	print("🖱️ Kliknuta kartica:", data)

	if selected_card and selected_card.is_inside_tree():
		selected_card.modulate = Color(1, 1, 1)

	selected_card = card
	if selected_card:
		selected_card.modulate = Color(0.7, 0.85, 1.0)

func _on_card_activated(data: Dictionary, card: Control) -> void:
	print("⚡ Duplo kliknuta kartica:", data)

	match data.get("type", ""):
		"communicate":
			print("💬 Postavljamo pitanje pacijentu:", data.get("name"))
			_ask_patient(data.get("name"))

		"test":
			print("🧪 Pokrećemo test:", data.get("name"))
			_run_test(data.get("name"))

		"treatment":
			print("💊 Primena terapije:", data.get("name"))

			medical_record.append("Terapija: \"" + data.get("name") + "\" primenjena.")

			if card and card.is_inside_tree():
				card.queue_free()

	if selected_card == card:
		selected_card = null

func _run_test(test_name: String) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var roll = rng.randi_range(1, 100)
	var result: String

	if roll <= 70:
		result = "normalan"
		response_panel.push_color(Color(0, 0.6, 0))
		response_panel.append_text("✅ Test \"" + test_name + "\" pokazuje normalne rezultate.\n\n")
	else:
		result = "abnormalan"
		response_panel.push_color(Color(0.8, 0, 0))
		response_panel.append_text("⚠️ Test \"" + test_name + "\" pokazuje abnormalnosti!\n\n")

	response_panel.pop()

	medical_record.append("Test: \"" + test_name + "\" ➔ Rezultat: " + result)

func _ask_patient(question: String) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var answer: String
	var roll = rng.randi_range(1, 100)

	if roll <= 50:
		answer = "DA"
	else:
		answer = "NE"

	response_panel.push_color(Color(0.2, 0.4, 0.8))
	response_panel.append_text("💬 Na pitanje \"" + question + "\": ✅ Pacijent odgovara: " + answer + "\n\n")
	response_panel.pop()

	medical_record.append("Pitanje: \"" + question + "\" ➔ Odgovor pacijenta: " + answer)

func show_medical_record():
	var record_text = "📋 Pacijentov karton:\n\n"
	for entry in medical_record:
		record_text += "- " + entry + "\n"

	response_panel.clear()
	response_panel.append_text(record_text)

func _on_confirm_diagnosis_pressed() -> void:
	diagnosis_line_edit.text = ""
	diagnosis_popup.popup_centered()

func _on_diagnosis_confirmed() -> void:
	var entered_diagnosis = diagnosis_line_edit.text.strip_edges()
	if entered_diagnosis != "":
		medical_record.append("📋 Postavljena dijagnoza: " + entered_diagnosis)
		response_panel.clear()
		response_panel.append_text("✅ Dijagnoza \"" + entered_diagnosis + "\" je zabeležena u karton.\n")
	diagnosis_popup.hide()
