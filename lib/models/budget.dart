class Budget {
  final String id;
  final String userId;
  final String category;
  final double limitAmount;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.userId,
    required this.category,
    required this.limitAmount,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    category: json['category'] as String,
    limitAmount: double.parse(json['limit_amount'].toString()),
    month: json['month'] as int,
    year: json['year'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category': category,
    'limit_amount': limitAmount,
    'month': month,
    'year': year,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? limitAmount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Budget(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    category: category ?? this.category,
    limitAmount: limitAmount ?? this.limitAmount,
    month: month ?? this.month,
    year: year ?? this.year,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
