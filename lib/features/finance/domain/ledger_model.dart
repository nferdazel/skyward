class LedgerEntry {
  final String id;
  final String transactionType; // 'revenue' or 'expense'
  final String category;        // 'ticket_sales', 'operations', 'aircraft_lease', 'aircraft_purchase', 'aircraft_repair'
  final double amount;
  final String description;
  final DateTime gameDate;
  final DateTime createdAt;

  LedgerEntry({
    required this.id,
    required this.transactionType,
    required this.category,
    required this.amount,
    required this.description,
    required this.gameDate,
    required this.createdAt,
  });

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      id: map['id'] ?? '',
      transactionType: map['transaction_type'] ?? 'expense',
      category: map['category'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.00,
      description: map['description'] ?? '',
      gameDate: map['game_date'] != null
          ? DateTime.parse(map['game_date'])
          : DateTime.now(),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}
