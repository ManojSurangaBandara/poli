class Loan {
  final String id;
  final String borrowerId;
  final double amount;
  final DateTime date;
  final String status; // 'active', 'repaid', etc.
  final double interestPercentage;
  final double interest;
  final DateTime nextInterestDueDate;
  final DateTime? repaidDate;

  Loan({
    required this.id,
    required this.borrowerId,
    required this.amount,
    required this.date,
    this.status = 'active',
    required this.interestPercentage,
    required this.interest,
    required this.nextInterestDueDate,
    this.repaidDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'borrowerId': borrowerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
      'interestPercentage': interestPercentage,
      'interest': interest,
      'nextInterestDueDate': nextInterestDueDate.toIso8601String(),
      'repaidDate': repaidDate?.toIso8601String(),
    };
  }

  factory Loan.fromMap(Map<String, dynamic> map) {
    return Loan(
      id: map['id'] as String,
      borrowerId: map['borrowerId'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : DateTime.now(),
      status: map['status'] as String? ?? 'active',
      interestPercentage: (map['interestPercentage'] as num?)?.toDouble() ?? 0.0,
      interest: (map['interest'] as num?)?.toDouble() ?? (map['monthlyInterestAmount'] as num?)?.toDouble() ?? (map['installmentAmount'] as num?)?.toDouble() ?? 0.0,
      nextInterestDueDate: map['nextInterestDueDate'] != null && (map['nextInterestDueDate'] as String).isNotEmpty ? DateTime.parse(map['nextInterestDueDate'] as String) : (map['nextInstallmentDate'] != null && (map['nextInstallmentDate'] as String).isNotEmpty ? DateTime.parse(map['nextInstallmentDate'] as String) : DateTime.now().add(const Duration(days: 30))),
      repaidDate: map['repaidDate'] != null && (map['repaidDate'] as String).isNotEmpty ? DateTime.parse(map['repaidDate'] as String) : null,
    );
  }
}