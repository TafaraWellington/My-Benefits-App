class EnquirerDetails {
  final String names;
  final String surname;
  final String cellNumber;
  final String email;
  final bool consentGiven;

  EnquirerDetails({
    required this.names,
    required this.surname,
    required this.cellNumber,
    required this.email,
    required this.consentGiven,
  });

  Map<String, dynamic> toJson() => {
    'names': names,
    'surname': surname,
    'cellNumber': cellNumber,
    'email': email,
    'consentGiven': consentGiven,
  };
}

class TargetDetails {
  final String idNumber;
  final DateTime dateOfBirth;
  final String surname;
  final String? employerName;
  final String? fundName;

  TargetDetails({
    required this.idNumber,
    required this.dateOfBirth,
    required this.surname,
    this.employerName,
    this.fundName,
  });

  Map<String, dynamic> toJson() => {
    'idNumber': idNumber,
    'dateOfBirth': dateOfBirth.toIso8601String(),
    'surname': surname,
    'employerName': employerName,
    'fundName': fundName,
  };
}

class BenefitResult {
  final String fundName;
  final String status;
  final String administrator;
  final String contactDetails;

  BenefitResult({
    required this.fundName,
    required this.status,
    required this.administrator,
    required this.contactDetails,
  });

  factory BenefitResult.fromJson(Map<String, dynamic> json) {
    return BenefitResult(
      fundName: json['fundName'] ?? '',
      administrator: json['administrator'] ?? '',
      contactDetails: json['contactDetails'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
