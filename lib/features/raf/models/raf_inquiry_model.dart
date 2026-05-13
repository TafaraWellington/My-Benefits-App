class RafInquiry {
  // Personal Details
  final String fullName;
  final String idNumber;
  final String phoneNumber;
  final String email;

  // Accident Details
  final DateTime accidentDate;
  final String accidentLocation;
  final String? policeStation;
  final String? caseNumber;
  final String accidentDescription;

  // Medical Details
  final String? hospitalName;
  final String? injuryDescription;
  final DateTime? treatmentDate;

  // Employment Details
  final String? employerName;
  final String? daysMissedWork;

  RafInquiry({
    required this.fullName,
    required this.idNumber,
    required this.phoneNumber,
    required this.email,
    required this.accidentDate,
    required this.accidentLocation,
    this.policeStation,
    this.caseNumber,
    required this.accidentDescription,
    this.hospitalName,
    this.injuryDescription,
    this.treatmentDate,
    this.employerName,
    this.daysMissedWork,
  });
}
