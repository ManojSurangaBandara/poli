class Borrower {
  final String id;
  final String name;
  final String mobileNumber;
  final String? profilePicturePath;
  final String bankName;
  final String accountNumber;
  final String accountHolderName;
  final String branchName;

  Borrower({
    required this.id,
    required this.name,
    required this.mobileNumber,
    this.profilePicturePath,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolderName,
    required this.branchName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'mobileNumber': mobileNumber,
      'profilePicturePath': profilePicturePath,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountHolderName': accountHolderName,
      'branchName': branchName,
    };
  }

  factory Borrower.fromMap(Map<String, dynamic> map) {
    return Borrower(
      id: map['id'],
      name: map['name'],
      mobileNumber: map['mobileNumber'],
      profilePicturePath: map['profilePicturePath'],
      bankName: map['bankName'] ?? '',
      accountNumber: map['accountNumber'] ?? '',
      accountHolderName: map['accountHolderName'] ?? '',
      branchName: map['branchName'] ?? '',
    );
  }
}