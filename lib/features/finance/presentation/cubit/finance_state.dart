import '../../domain/finance_snapshot.dart';
import '../../domain/ledger_model.dart';

abstract class FinanceState {
  const FinanceState();
}

class FinanceDailySnapshot {
  final DateTime gameDate;
  final double revenue;
  final double expense;
  final double net;

  const FinanceDailySnapshot({
    required this.gameDate,
    required this.revenue,
    required this.expense,
    required this.net,
  });
}

abstract class FinanceDataState extends FinanceState {
  final FinanceSnapshot snapshot;
  final List<LedgerEntry> logs;
  final List<FinanceDailySnapshot> dailySnapshots;
  final double totalTicketSales;
  final double totalOperations;
  final double totalLease;
  final double totalRepair;
  final double totalPurchase;
  final double totalRevenue;
  final double totalExpense;
  final double netProfit;
  final double averageDailyNet;
  final double latestDailyNet;
  final double worstDailyNet;
  final double expenseConcentration;
  final double leaseExpenseShare;
  final double repairExpenseShare;

  const FinanceDataState({
    required this.snapshot,
    required this.logs,
    required this.dailySnapshots,
    required this.totalTicketSales,
    required this.totalOperations,
    required this.totalLease,
    required this.totalRepair,
    required this.totalPurchase,
    required this.totalRevenue,
    required this.totalExpense,
    required this.netProfit,
    required this.averageDailyNet,
    required this.latestDailyNet,
    required this.worstDailyNet,
    required this.expenseConcentration,
    required this.leaseExpenseShare,
    required this.repairExpenseShare,
  });
}

class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

class FinanceLoading extends FinanceDataState {
  const FinanceLoading({
    required super.snapshot,
    required super.logs,
    required super.dailySnapshots,
    required super.totalTicketSales,
    required super.totalOperations,
    required super.totalLease,
    required super.totalRepair,
    required super.totalPurchase,
    required super.totalRevenue,
    required super.totalExpense,
    required super.netProfit,
    required super.averageDailyNet,
    required super.latestDailyNet,
    required super.worstDailyNet,
    required super.expenseConcentration,
    required super.leaseExpenseShare,
    required super.repairExpenseShare,
  });
}

class FinanceLoaded extends FinanceDataState {
  const FinanceLoaded({
    required super.snapshot,
    required super.logs,
    required super.dailySnapshots,
    required super.totalTicketSales,
    required super.totalOperations,
    required super.totalLease,
    required super.totalRepair,
    required super.totalPurchase,
    required super.totalRevenue,
    required super.totalExpense,
    required super.netProfit,
    required super.averageDailyNet,
    required super.latestDailyNet,
    required super.worstDailyNet,
    required super.expenseConcentration,
    required super.leaseExpenseShare,
    required super.repairExpenseShare,
  });
}

class FinanceError extends FinanceDataState {
  final String message;

  final bool hasData;

  const FinanceError({
    required this.message,
    this.hasData = false,
    super.snapshot = const FinanceSnapshot.empty(),
    super.logs = const [],
    super.dailySnapshots = const [],
    super.totalTicketSales = 0.0,
    super.totalOperations = 0.0,
    super.totalLease = 0.0,
    super.totalRepair = 0.0,
    super.totalPurchase = 0.0,
    super.totalRevenue = 0.0,
    super.totalExpense = 0.0,
    super.netProfit = 0.0,
    super.averageDailyNet = 0.0,
    super.latestDailyNet = 0.0,
    super.worstDailyNet = 0.0,
    super.expenseConcentration = 0.0,
    super.leaseExpenseShare = 0.0,
    super.repairExpenseShare = 0.0,
  });
}
