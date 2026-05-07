part of 'dashboard_bloc.dart';

abstract class DashboardEvent {}

class DashboardLoadRequested extends DashboardEvent {}

class DashboardRefreshRequested extends DashboardEvent {}
