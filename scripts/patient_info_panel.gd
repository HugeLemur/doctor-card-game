extends PanelContainer

@onready var name_label = $VBoxContainer/NameLabel
@onready var age_gender_label = $VBoxContainer/AgeGenderLabel
@onready var visit_reason_label = $VBoxContainer/VisitReasonLabel

func set_patient_info(name: String, age: int, gender: String, reason: String):
	name_label.text = "Ime: %s" % name
	age_gender_label.text = "Starost: %d | Pol: %s" % [age, gender]
	visit_reason_label.text = "Povod dolaska: %s" % reason
