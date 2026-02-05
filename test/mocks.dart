import 'package:mockito/annotations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:body_tracker/services/database_service.dart';
import 'package:body_tracker/services/goal_service.dart';
import 'package:body_tracker/services/photo_service.dart';
import 'package:body_tracker/services/notification_service.dart';

@GenerateMocks([
  Database,
  DatabaseService,
  GoalService,
  PhotoService,
  NotificationService,
])
void main() {}
