import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  String habit;
  String category;
  Timestamp createdAt;
  Timestamp updatedAt;
  bool isDone;

  Habit({
    required this.habit,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.isDone,
  });

  Habit.fromJson(Map<String, dynamic> json)
    : this(
        habit: json['habit']! as String,
        category: json['category']! as String,
        createdAt: json['createdAt']! as Timestamp,
        updatedAt: json['updatedAt']! as Timestamp,
        isDone: json['isDone']! as bool,
      );

  Habit copyWith({
    String? habit,
    String? category,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isDone,
  }) {
    return Habit(
      habit: habit ?? this.habit,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDone: isDone ?? this.isDone,
    );
  }
}
