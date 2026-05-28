import 'package:hive/hive.dart';

part 'sync_queue_item.g.dart';

@HiveType(typeId: 4)
enum SyncAction {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

@HiveType(typeId: 5)
class SyncQueueItem extends HiveObject {
  @HiveField(0)
  String id; // UUID for the queue item itself

  @HiveField(1)
  SyncAction action;

  @HiveField(2)
  int clientId;

  @HiveField(3)
  String? serverId;

  @HiveField(4)
  Map<String, dynamic>? data; // JSON representation of the asset if needed

  @HiveField(5)
  DateTime clientUpdatedAt;

  SyncQueueItem({
    required this.id,
    required this.action,
    required this.clientId,
    this.serverId,
    this.data,
    required this.clientUpdatedAt,
  });
}
