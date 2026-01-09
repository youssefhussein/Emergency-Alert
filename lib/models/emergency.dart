import 'package:flutter/material.dart';

enum FormFieldType {
  text,
  textarea,
  select,
  photo, // camera/gallery picker
  voiceNote, // audio recorder
  toggle, // switch
}

class FormFieldModel {
  final String id;
  final String label;
  final FormFieldType type;

  final String? placeholder;
  final List<String> options;
  final bool requiredField;

  final String? helperText; // subtitle under label (for toggles)
  final Object? initialValue; // bool for toggle, String for text, etc.
  final IconData? leadingIcon; // icon for cards

  const FormFieldModel({
    required this.id,
    required this.label,
    required this.type,
    this.placeholder,
    this.options = const [],
    required this.requiredField,
    this.helperText,
    this.initialValue,
    this.leadingIcon,
  });
}

class Emergency {
  final String id;
  final String type;
  final String name;
  final String primaryNumber;
  final String? secondaryNumber;
  final String address;
  final String description;
  final Color color;
  final Color bgColor;
  final IconData icon;
  final String calmingMessage;
  final List<String> availableServices;
  final List<FormFieldModel> formFields;

  const Emergency({
    required this.id,
    required this.type,
    required this.name,
    required this.primaryNumber,
    this.secondaryNumber,
    required this.address,
    required this.description,
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.calmingMessage,
    required this.availableServices,
    required this.formFields,
  });
}

/// Common fields added to EVERY emergency request form.
/// IDs chosen to match your DB columns where possible.
const List<FormFieldModel> commonEmergencyExtras = [
  FormFieldModel(
    id: "notes",
    label: "What's happening? (Optional)",
    type: FormFieldType.textarea,
    placeholder: "Brief description to help responders prepare...",
    requiredField: false,
  ),
  FormFieldModel(
    id: "photo_url", // store STORAGE PATH or URL in DB
    label: "Add Photo (Optional)",
    type: FormFieldType.photo,
    requiredField: false,
    leadingIcon: Icons.camera_alt_outlined,
  ),
  FormFieldModel(
    id: "voice_note_url", // store STORAGE PATH or URL in DB
    label: "Add Voice Note (Optional)",
    type: FormFieldType.voiceNote,
    requiredField: false,
    leadingIcon: Icons.mic_none,
  ),
  FormFieldModel(
    id: "share_location",
    label: "Share Location",
    type: FormFieldType.toggle,
    requiredField: false,
    helperText: "Help responders find you faster",
    initialValue: true,
    leadingIcon: Icons.location_on_outlined,
  ),
  FormFieldModel(
    id: "notify_contacts",
    label: "Notify Trusted Contacts",
    type: FormFieldType.toggle,
    requiredField: false,
    helperText: "Alert your emergency contacts",
    initialValue: false,
    leadingIcon: Icons.group_outlined,
  ),
  FormFieldModel(
    id: "location_details",
    label: "Edit location details (building, floor, etc.)",
    type: FormFieldType.text,
    placeholder: "Building / floor / landmark...",
    requiredField: false,
    leadingIcon: Icons.edit_location_alt_outlined,
  ),
  FormFieldModel(
    id: "phone",
    label: "Contact phone (Optional)",
    type: FormFieldType.text,
    placeholder: "Your phone number",
    requiredField: false,
    leadingIcon: Icons.phone_outlined,
  ),
];

//helper to avoid repeating extras for police/fire/hospital.
//write the specific fields once per emergency type.
List<FormFieldModel> buildFields(List<FormFieldModel> specificFields) => [
  ...specificFields,
  ...commonEmergencyExtras,
];

final List<Emergency> emergencies = [
  Emergency(
    id: "1",
    type: "ambulance",
    name: "Ambulance",
    primaryNumber: "123",
    secondaryNumber: "(555) 456-7890",
    address: "321 Rescue Road, Emergency Hub",
    description:
        "Help is arriving soon. You are not alone. We are here for you.",
    color: Colors.red.shade600,
    bgColor: const Color(0xFFFFEBEE),
    icon: Icons.local_hospital_outlined,
    calmingMessage:
        "An ambulance is coming to you now. Stay calm and keep the patient comfortable.",
    availableServices: [
      "Fast Transport",
      "Paramedic Care",
      "Life Support",
      "Medical Assistance",
    ],
    formFields: buildFields([
      FormFieldModel(
        id: "location",
        label: "Pickup Location",
        type: FormFieldType.text,
        placeholder: "Exact address",
        requiredField: true,
      ),
      FormFieldModel(
        id: "urgency",
        label: "Urgency Level",
        type: FormFieldType.select,
        options: ["Life-threatening", "Urgent", "Non-urgent transport"],
        requiredField: true,
      ),
      FormFieldModel(
        id: "patient",
        label: "Patient Condition",
        type: FormFieldType.textarea,
        placeholder: "Brief description of condition...",
        requiredField: true,
      ),
      FormFieldModel(
        id: "access",
        label: "Access Information",
        type: FormFieldType.text,
        placeholder: "Floor number, building entrance, etc.",
        requiredField: false,
      ),
    ]),
  ),

  Emergency(
    id: "2",
    type: "police",
    name: "Police",
    primaryNumber: "122",
    secondaryNumber: "(555) 123-4567",
    address: "123 Main Street, Downtown",
    description:
        "We are here to help you. Please stay calm and provide your location.",
    color: Colors.blue.shade600,
    bgColor: const Color(0xFFE3F2FD),
    icon: Icons.shield_outlined,
    calmingMessage: "Help is on the way. You are safe now. Take a deep breath.",
    availableServices: [
      "Emergency Response",
      "Crime Reporting",
      "Traffic Assistance",
      "Public Safety",
    ],
    formFields: buildFields([
      FormFieldModel(
        id: "location",
        label: "Your Location",
        type: FormFieldType.text,
        placeholder: "Street address or landmark",
        requiredField: true,
      ),
      FormFieldModel(
        id: "emergency",
        label: "What happened?",
        type: FormFieldType.select,
        options: [
          "Accident",
          "Crime in progress",
          "Suspicious activity",
          "Traffic incident",
          "Other",
        ],
        requiredField: true,
      ),
      FormFieldModel(
        id: "details",
        label: "Additional Details",
        type: FormFieldType.textarea,
        placeholder: "Describe the situation calmly...",
        requiredField: false,
      ),
      FormFieldModel(
        id: "injuries",
        label: "Anyone injured?",
        type: FormFieldType.select,
        options: ["No", "Yes - Minor", "Yes - Serious"],
        requiredField: true,
      ),
    ]),
  ),

  Emergency(
    id: "3",
    type: "fire",
    name: "Fire Department",
    primaryNumber: "111",
    secondaryNumber: "(555) 234-5678",
    address: "456 Oak Avenue, Central District",
    description:
        "Stay calm. Help is coming quickly. Follow safety instructions.",
    color: Colors.orange.shade600,
    bgColor: const Color(0xFFFFF3E0),
    icon: Icons.local_fire_department_outlined,
    calmingMessage:
        "Firefighters are on their way. Stay safe and follow evacuation procedures.",
    availableServices: [
      "Fire Response",
      "Rescue Operations",
      "Hazmat",
      "Emergency Medical",
    ],
    formFields: buildFields([
      FormFieldModel(
        id: "location",
        label: "Fire Location",
        type: FormFieldType.text,
        placeholder: "Exact address or building name",
        requiredField: true,
      ),
      FormFieldModel(
        id: "type",
        label: "Emergency Type",
        type: FormFieldType.select,
        options: [
          "Fire",
          "Gas leak",
          "Trapped person",
          "Hazardous material",
          "Other",
        ],
        requiredField: true,
      ),
      FormFieldModel(
        id: "people",
        label: "People inside?",
        type: FormFieldType.select,
        options: ["No one inside", "Yes - evacuated", "Yes - still inside"],
        requiredField: true,
      ),
      FormFieldModel(
        id: "details",
        label: "Additional Information",
        type: FormFieldType.textarea,
        placeholder: "Building floor, smoke visibility, etc.",
        requiredField: false,
      ),
    ]),
  ),

  Emergency(
    id: "4",
    type: "hospital",
    name: "Hospital",
    primaryNumber: "125",
    secondaryNumber: "(555) 345-6789",
    address: "789 Health Plaza, Medical Center",
    description:
        "You are doing great. Medical help is coming. Stay with the person.",
    color: Colors.green.shade600,
    bgColor: const Color(0xFFE8F5E9),
    icon: Icons.local_hospital_outlined,
    calmingMessage:
        "Medical professionals are on their way. Keep breathing slowly and steadily.",
    availableServices: [
      "Emergency Care",
      "Ambulance",
      "Trauma Care",
      "24/7 Support",
    ],
    formFields: buildFields([
      FormFieldModel(
        id: "location",
        label: "Patient Location",
        type: FormFieldType.text,
        placeholder: "Where is the patient?",
        requiredField: true,
      ),
      FormFieldModel(
        id: "condition",
        label: "Medical Condition",
        type: FormFieldType.select,
        options: [
          "Breathing difficulty",
          "Chest pain",
          "Unconscious",
          "Severe bleeding",
          "Fall or injury",
          "Other",
        ],
        requiredField: true,
      ),
      FormFieldModel(
        id: "age",
        label: "Patient Age",
        type: FormFieldType.select,
        options: [
          "Child (0-12)",
          "Teen (13-17)",
          "Adult (18-64)",
          "Senior (65+)",
        ],
        requiredField: true,
      ),
      FormFieldModel(
        id: "conscious",
        label: "Is patient conscious?",
        type: FormFieldType.select,
        options: ["Yes - Alert", "Yes - Confused", "No - Unconscious"],
        requiredField: true,
      ),
      FormFieldModel(
        id: "details",
        label: "Symptoms",
        type: FormFieldType.textarea,
        placeholder: "Describe symptoms...",
        requiredField: false,
      ),
    ]),
  ),
];
