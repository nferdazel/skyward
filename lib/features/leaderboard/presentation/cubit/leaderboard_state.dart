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

class LeaderboardLoaded extends LeaderboardState {
  final List<LeaderboardEntry> rankings;
  final String? selectedCompetitorId;
  final CompetitorInsights? selectedInsights;
  final bool isLoadingInsights;

  const LeaderboardLoaded({
    required this.rankings,
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

class LeaderboardError extends LeaderboardState {
  final String message;
  const LeaderboardError({required this.message});
}

// Substates for Competitor Insights detail drawer / modal
abstract class CompetitorInsightsState {
  const CompetitorInsightsState();
}

class InsightsInitial extends CompetitorInsightsState {
  const InsightsInitial();
}

class InsightsLoading extends CompetitorInsightsState {
  const InsightsLoading();
}

class InsightsLoaded extends CompetitorInsightsState {
  final CompetitorInsights insights;
  const InsightsLoaded({required this.insights});
}

class InsightsError extends CompetitorInsightsState {
  final String message;
  const InsightsError({required this.message});
}
