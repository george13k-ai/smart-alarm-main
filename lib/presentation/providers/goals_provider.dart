import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/user_goals.dart';
import '../../data/models/goals_model.dart';
import '../../core/constants/app_constants.dart';

class GoalsNotifier extends StateNotifier<UserGoals> {
  GoalsNotifier() : super(UserGoals.defaultGoals) {
    _load();
  }

  Box<GoalsModel> get _box => Hive.box<GoalsModel>(AppConstants.goalsBox);

  void _load() {
    final model = _box.get('goals');
    if (model != null) state = model.toEntity();
  }

  Future<void> save(UserGoals goals) async {
    await _box.put('goals', GoalsModel.fromEntity(goals));
    state = goals;
  }
}

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, UserGoals>((ref) => GoalsNotifier());
