extends Control

# --- UI Node References ---
@onready var card_zone_tabs = $MarginContainer/VBoxContainer/MainHBox/CardZoneScroll/CardZone
@onready var communicate_tab = card_zone_tabs.get_node("CommunicateTab")
@onready var test_tab = card_zone_tabs.get_node("TestTab")
@onready var treatment_tab = card_zone_tabs.get_node("TreatmentTab")
@onready var response_panel = $MarginContainer/VBoxContainer/MainHBox/ResponsePanelScroll/ResponsePanel
@onready var diagnosis_button = $MarginContainer/VBoxContainer/ActionBar/DiagnosisButton
@onready var diagnosis_popup = $MarginContainer/VBoxContainer/DiagnosisPopup
@onready var diagnosis_suggestions_vbox = $MarginContainer/VBoxContainer/DiagnosisPopup/PopupMargin/VBoxContainer/DiagnosisSuggestionsVBox
@onready var diagnosis_line_edit = $MarginContainer/VBoxContainer/DiagnosisPopup/PopupMargin/VBoxContainer/DiagnosisLineEdit
@onready var diagnosis_confirm_button = $MarginContainer/VBoxContainer/DiagnosisPopup/PopupMargin/VBoxContainer/DiagnosisConfirmButton
@onready var patient_info_panel = $MarginContainer/VBoxContainer/TopBar/PatientInfoPanel

# --- Gameplay Variables ---
var possible_diagnoses = []
var selected_card: Control = null
var medical_record: Array = []
var discovered_symptoms: Array = []
var discovered_tests: Array = []

# --- Game Lifecycle ---
func _ready():
	load_diagnoses_from_json()
	generate_cards_from_diagnoses()

	if possible_diagnoses.size() > 0:
		generate_random_patient()
	else:
		print("❌ Nema učitanih dijagnoza, ne generišem pacijenta.")



	diagnosis_button.pressed.connect(_on_diagnosis_button_pressed)
	diagnosis_confirm_button.pressed.connect(_on_diagnosis_confirmed)
	diagnosis_popup.close_requested.connect(func(): diagnosis_popup.hide())

func load_diagnoses_from_json():
	generate_random_patient()
	var file = FileAccess.open("res://data/diagnoses.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var result = JSON.parse_string(content)
		if result:
			possible_diagnoses = result
		else:
			push_error("❌ JSON parsing error in diagnoses.json")
	else:
		push_error("❌ Cannot open diagnoses.json file")

func generate_cards_from_diagnoses():
	var added_symptoms = {}
	var added_tests = {}

	for diag in possible_diagnoses:
		for symptom in diag.get("symptoms", []):
			var symptom_key = symptom.to_lower()
			if not added_symptoms.has(symptom_key):
				add_card_to_zone({
					"name": "Ask about " + symptom.capitalize(),
					"description": "Ask the patient about " + symptom + ".",
					"type": "communicate"
				})
				added_symptoms[symptom_key] = true

		for test in diag.get("test_results", []):
			var test_key = test.to_lower()
			if not added_tests.has(test_key):
				add_card_to_zone({
					"name": "Run test: " + test.capitalize(),
					"description": "Perform the test: " + test + ".",
					"type": "test"
				})
				added_tests[test_key] = true

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
			print("⚠️ Unknown card type:", data)

	card.setup(data)
	card.connect("card_clicked", Callable(self, "_on_card_clicked").bind(card))
	card.connect("card_activated", Callable(self, "_on_card_activated").bind(card))

func _on_card_clicked(data: Dictionary, card: Control) -> void:
	if selected_card and selected_card.is_inside_tree():
		selected_card.modulate = Color(1, 1, 1)
	selected_card = card
	if selected_card:
		selected_card.modulate = Color(0.7, 0.85, 1.0)

func _on_card_activated(data: Dictionary, card: Control) -> void:
	match data.get("type", ""):
		"communicate":
			_ask_patient(data.get("name"), card)
		"test":
			_run_test(data.get("name"), card)
		"treatment":
			_apply_treatment(data.get("name"), card)

	if selected_card == card:
		selected_card = null

# --- Gameplay Actions ---
func _ask_patient(question: String, card: Control) -> void:
	var cleaned = question.replace("Ask about ", "").to_lower()

	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var answer = "YES" if rng.randi_range(0, 1) == 0 else "NO"

	response_panel.push_color(Color(0.2, 0.4, 0.8))
	response_panel.append_text("💬 Question: \"" + cleaned + "\" ➔ Answer: " + answer + "\n\n")
	response_panel.pop()

	medical_record.append("Question: " + cleaned + " ➔ Answer: " + answer)

	if answer == "YES":
		if not discovered_symptoms.has(cleaned):
			discovered_symptoms.append(cleaned)

		if card and card.is_inside_tree():
			card.queue_free()

		suggest_test_for_symptom(cleaned)

func suggest_test_for_symptom(symptom: String):
	for diag in possible_diagnoses:
		if symptom in diag.get("symptoms", []):
			for test in diag.get("test_results", []):
				var test_name = "Run test: " + test.capitalize()
				if not has_test_card(test_name):
					add_card_to_zone({
						"name": test_name,
						"description": "Perform the test: " + test + ".",
						"type": "test"
					})
					return

func _run_test(test_name: String, card: Control) -> void:
	var cleaned = test_name.replace("Run test: ", "").to_lower()

	var abnormality_found = false
	for diag in possible_diagnoses:
		for test_result in diag.get("test_results", []):
			if cleaned in test_result.to_lower():
				response_panel.push_color(Color(0.8, 0, 0))
				response_panel.append_text("⚠️ Abnormal test: " + test_result + "\n\n")
				response_panel.pop()

				medical_record.append("Test: " + cleaned + " ➔ Abnormality: " + test_result)

				if not discovered_tests.has(test_result.strip_edges().to_lower()):
					discovered_tests.append(test_result.strip_edges().to_lower())

				suggest_treatment_for_test_result(test_result)

				abnormality_found = true
				break
		if abnormality_found:
			break

	if not abnormality_found:
		response_panel.push_color(Color(0, 0.6, 0))
		response_panel.append_text("✅ Test \"" + cleaned + "\" is normal.\n\n")
		response_panel.pop()

		medical_record.append("Test: " + cleaned + " ➔ Normal")

	if card and card.is_inside_tree():
		card.queue_free()

func suggest_treatment_for_test_result(test_result: String):
	for diag in possible_diagnoses:
		for tr in diag.get("test_results", []):
			if test_result.strip_edges().to_lower() in tr.strip_edges().to_lower():
				for treatment in diag.get("treatments", []):
					var treatment_name = "Treat with " + treatment.capitalize()

					if not has_treatment_card(treatment_name):
						add_card_to_zone({
							"name": treatment_name,
							"description": "Apply treatment: " + treatment + ".",
							"type": "treatment"
						})
				return

func has_test_card(test_name: String) -> bool:
	for child in test_tab.get_children():
		if child.has_method("get_title") and child.get_title() == test_name:
			return true
	return false

func has_treatment_card(treatment_name: String) -> bool:
	for child in treatment_tab.get_children():
		if child.has_method("get_title") and child.get_title() == treatment_name:
			return true
	return false

func _apply_treatment(treatment_name: String, card: Control) -> void:
	medical_record.append("Treatment applied: " + treatment_name)

	response_panel.push_color(Color(0, 0.6, 0))
	response_panel.append_text("💊 Treatment \"" + treatment_name + "\" applied successfully.\n\n")
	response_panel.pop()

	if card and card.is_inside_tree():
		card.queue_free()

# --- Diagnosis System ---
func _on_diagnosis_button_pressed() -> void:
	for child in diagnosis_suggestions_vbox.get_children():
		child.queue_free()

	var suggestions = get_diagnosis_suggestions()

	for diagnosis_name in suggestions:
		var button = Button.new()
		button.text = diagnosis_name
		button.pressed.connect(func():
			_confirm_suggested_diagnosis(diagnosis_name)
		)
		diagnosis_suggestions_vbox.add_child(button)

	diagnosis_line_edit.text = ""
	diagnosis_popup.popup_centered()

func get_diagnosis_suggestions() -> Array:
	var diagnosis_scores = {}

	for diag in possible_diagnoses:
		var score = 0

		for symptom in diag.get("symptoms", []):
			if discovered_symptoms.has(symptom.strip_edges().to_lower()):
				score += 1

		for test in diag.get("test_results", []):
			if discovered_tests.has(test.strip_edges().to_lower()):
				score += 1

		if score > 0:
			diagnosis_scores[diag.name] = score

	var sorted_diagnoses = diagnosis_scores.keys()
	sorted_diagnoses.sort_custom(func(a, b):
		return diagnosis_scores[b] - diagnosis_scores[a]
	)

	return sorted_diagnoses

func _confirm_suggested_diagnosis(diagnosis: String) -> void:
	medical_record.append("📋 Final Diagnosis: " + diagnosis)
	response_panel.clear()
	response_panel.append_text("✅ Final diagnosis \"" + diagnosis + "\" recorded.\n")
	diagnosis_popup.hide()

func _on_diagnosis_confirmed() -> void:
	var entered_diagnosis = diagnosis_line_edit.text.strip_edges()
	if entered_diagnosis != "":
		medical_record.append("📋 Final Diagnosis: " + entered_diagnosis)
		response_panel.clear()
		response_panel.append_text("✅ Final diagnosis \"" + entered_diagnosis + "\" recorded.\n")
	diagnosis_popup.hide()
# --- Random Patient Generator ---

var male_first_names = ["Petar", "Marko", "Nikola", "Milan", "Stefan"]
var female_first_names = ["Ana", "Marija", "Jovana", "Milica", "Teodora"]
var last_names = ["Petrović", "Jovanović", "Nikolić", "Popović", "Stanković"]

func generate_random_patient():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	if possible_diagnoses.size() == 0:
		push_error("❌ Nema učitanih dijagnoza za random pacijenta!")
		return

	var gender = "Male" if rng.randi_range(0, 1) == 0 else "Female"
	var first_name = male_first_names[rng.randi_range(0, male_first_names.size() - 1)] if gender == "Male" else female_first_names[rng.randi_range(0, female_first_names.size() - 1)]
	var last_name = last_names[rng.randi_range(0, last_names.size() - 1)]
	var age = rng.randi_range(1, 99)
	var name = first_name + " " + last_name

	var all_symptoms = get_all_possible_symptoms()
	if all_symptoms.size() == 0:
		push_error("❌ Nema dostupnih simptoma za random pacijenta!")
		return

	var main_symptom = all_symptoms[rng.randi_range(0, all_symptoms.size() - 1)].capitalize()

	if patient_info_panel.has_method("set_patient_info"):
		patient_info_panel.set_patient_info(name, age, gender, main_symptom)
	else:
		push_error("❌ PatientInfoPanel nema funkciju 'set_patient_info'")

func get_all_possible_symptoms() -> Array:
	var symptoms = []

	for diag in possible_diagnoses:
		for symptom in diag.get("symptoms", []):
			if not symptoms.has(symptom):
				symptoms.append(symptom)

	return symptoms
