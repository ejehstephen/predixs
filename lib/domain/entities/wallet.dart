import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final String id;
  final String userId;
  final String currency;
  final double balance;
  final double reserved;

  const Wallet({
    required this.id,
    required this.userId,
    required this.currency,
    required this.balance,
    required this.reserved,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      currency: json['currency'] as String? ?? 'NGN',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      reserved: (json['reserved'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [id, userId, currency, balance, reserved];
}
