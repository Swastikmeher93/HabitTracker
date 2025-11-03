import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habittracker/model/habit.dart';

const String HABIT_COLLECTION_REF = "habit";

class DatabaseService {
  final _firestore = FirebaseFirestore.instance;

  late final CollectionReference<Habit> _habitRef;

  DatabaseService() {
    _habitRef = _firestore
        .collection(HABIT_COLLECTION_REF)
        .withConverter<Habit>(
          fromFirestore: (snapshots, _) => Habit.fromJson(snapshots.data()!),
          toFirestore: (habit, _) => {
            'habit': habit.habit,
            'category': habit.category,
            'createdAt': habit.createdAt,
            'updatedAt': habit.updatedAt,
            'isDone': habit.isDone,
          },
        );
  }

  Stream<QuerySnapshot<Habit>> getHabits() {
    return _habitRef.snapshots();
  }

  void addHabit(Habit habit) async {
    _habitRef.add(habit);
  }

  void updateHabit(String habitId, Habit habit) {
    _habitRef.doc(habitId).update({
      'habit': habit.habit,
      'category': habit.category,
      'createdAt': habit.createdAt,
      'updatedAt': habit.updatedAt,
      'isDone': habit.isDone,
    });
  }

  Future<void> deleteHabit(String habitId) {
    return _habitRef.doc(habitId).delete();
  }
}
