class Responder {
  final int id;
  final String uuid;
  final String? type;
  final String? instituteName;
  final String? addressName;
  final String? status;

  const Responder({
    required this.id,
    required this.uuid,
    this.type,
    this.instituteName,
    this.addressName,
    this.status,
  });

  factory Responder.fromJson(Map<String, dynamic> json) {
    return Responder(
      id: (json['id'] as num).toInt(),
      uuid: (json['uuid'] ?? '').toString(),
      type: json['type']?.toString(),
      instituteName: json['institute_name']?.toString(),
      addressName: json['address_name']?.toString(),
      status: json['status']?.toString(),
    );
  }
}
