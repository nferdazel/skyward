import '../../domain/leaderboard_models.dart';

const Object _leaderboardUnset = Object();

abstract class LeaderboardState {
  const LeaderboardState();
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

/// Intermediate state that carries cached rankings.
/// Both [LeaderboardLoaded] and [LeaderboardError] extend this so that
/// views (and the dashboard overview) can access `rankings` even during errors.
abstract class LeaderboardDataState extends LeaderboardState {
  final List<LeaderboardEntry> rankings;
  const LeaderboardDataState({required this.rankings});
}

class LeaderboardLoaded extends LeaderboardDataState {
  final String? selectedCompetitorId;
  final CompetitorInsights? selectedInsights;
  final bool isLoadingInsights;

  const LeaderboardLoaded({
    required super.rankings,
    this.selectedCompetitorId,
    this.selectedInsights,
    this.isLoadingInsights = false,
  });

  LeaderboardLoaded copyWith({
    List<LeaderboardEntry>? rankings,
    Object? selectedCompetitorId = _leaderboardUnset,
    Object? selectedInsights = _leaderboardUnset,
    bool? isLoadingInsights,
  }) {
    return LeaderboardLoaded(
      rankings: rankings ?? this.rankings,
      selectedCompetitorId: identical(
        selectedCompetitorId,
        _leaderboardUnset,
      )
          ? this.selectedCompetitorId
          : selectedCompetitorId as String?,
      selectedInsights: identical(selectedInsights, _leaderboardUnset)
          ? this.selectedInsights
          : selectedInsights as CompetitorInsights?,
      isLoadingInsights: isLoadingInsights ?? this.isLoadingInsights,
    );
  }
}

class LeaderboardError extends LeaderboardDataState {
  final String message;

  const LeaderboardError({
    required this.message,
    super.rankings = const [],
  });
}
