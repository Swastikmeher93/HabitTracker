import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:habittracker/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:habittracker/screen/home_detail_view.dart';
import 'package:habittracker/screen/profile_view.dart';
import 'package:habittracker/model/habit.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final int _daysToShow = 30; // Days before and after today
  bool _hasScrolledToToday = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> _getDatesAroundToday() {
    final List<DateTime> dates = [];
    final today = DateTime.now();
    // Generate dates from _daysToShow days before to _daysToShow days after today
    for (int i = -_daysToShow; i <= _daysToShow; i++) {
      dates.add(today.add(Duration(days: i)));
    }
    return dates;
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEE').format(date);
  }

  String _getMonthAbbr(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.health_and_safety;
      case 'Fitness':
        return Icons.fitness_center;
      case 'Learning':
        return Icons.school;
      case 'Productivity':
        return Icons.work_outline;
      case 'Gym':
        return Icons.sports_gymnastics;
      case 'Work':
        return Icons.business;
      case 'Other':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _scrollToToday(double screenWidth) {
    if (!_hasScrolledToToday && _scrollController.hasClients && mounted) {
      _hasScrolledToToday = true;
      final itemWidth = 68.0; // 60 width + 8 margin
      final centerOffset = (screenWidth - itemWidth) / 2;
      final todayOffset = _daysToShow * itemWidth - centerOffset;
      _scrollController.animateTo(
        todayOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dates = _getDatesAroundToday();
    // final screenWidth = MediaQuery.of(context).size.width; // not used

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            iconSize: 24,
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date and Day Slider Bar
          Container(
            height: 100,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Scroll to center after layout is built - only once
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToToday(constraints.maxWidth);
                });

                return ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(
                    horizontal: (constraints.maxWidth - 68) / 2,
                    vertical: 8,
                  ),
                  itemCount: dates.length,
                  itemBuilder: (context, index) {
                    final currentDate = dates[index];
                    final isSelectedDate =
                        _selectedDate.year == currentDate.year &&
                        _selectedDate.month == currentDate.month &&
                        _selectedDate.day == currentDate.day;
                    final isCurrentDateToday = _isToday(currentDate);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = currentDate;
                        });
                      },
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelectedDate
                              ? Theme.of(context).primaryColor
                              : isCurrentDateToday
                              ? Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDayName(currentDate),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelectedDate
                                    ? Colors.white
                                    : isCurrentDateToday
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${currentDate.day}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelectedDate
                                    ? Colors.white
                                    : isCurrentDateToday
                                    ? Theme.of(context).primaryColor
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              _getMonthAbbr(currentDate),
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelectedDate
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Habits list area
          Expanded(
            child: StreamBuilder<QuerySnapshot<Habit>>(
              stream: _databaseService.getHabits(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Habits Yet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Filter habits for the selected date
                final filteredDocs = docs.where((doc) {
                  final habit = doc.data();
                  return habit.createdAt.toDate().year == _selectedDate.year &&
                      habit.createdAt.toDate().month == _selectedDate.month &&
                      habit.createdAt.toDate().day == _selectedDate.day;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt_rounded,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Habits for ${DateFormat('MMM d, y').format(_selectedDate)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'SF Pro Display',
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredDocs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final habit = doc.data();
                    return ListTile(
                      leading: Icon(_getCategoryIcon(habit.category)),
                      title: Text(habit.habit),
                      subtitle: Text(habit.category),
                      trailing: IconButton(
                        icon: Icon(
                          habit.isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: habit.isDone ? Colors.green : Colors.grey,
                        ),
                        onPressed: () {
                          if (!habit.isDone) {
                            // Mark as done first
                            final updated = habit.copyWith(
                              isDone: true,
                              updatedAt: Timestamp.now(),
                            );
                            _databaseService.updateHabit(doc.id, updated);

                            // Delete after 5 seconds
                            Future.delayed(const Duration(seconds: 3), () {
                              _databaseService.deleteHabit(doc.id);
                            });
                          }
                        },
                      ),
                      onTap: () async {
                        final controller = TextEditingController(
                          text: habit.habit,
                        );
                        await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Edit Habit'),
                              content: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  labelText: 'Habit name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(context).pop();
                                    await _databaseService.deleteHabit(doc.id);
                                  },
                                  child: const Text('Delete'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final updated = habit.copyWith(
                                      habit: controller.text.trim(),
                                      updatedAt: Timestamp.now(),
                                    );
                                    Navigator.of(context).pop();
                                    _databaseService.updateHabit(
                                      doc.id,
                                      updated,
                                    );
                                  },
                                  child: const Text('Update'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeDetailView()),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// End of file
