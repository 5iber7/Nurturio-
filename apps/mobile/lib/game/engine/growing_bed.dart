import 'process_engine.dart';

class GrowingBed {
  final String plantId;
  final ProcessInstance process;
  DateTime? wateredAt;
  GrowingBed(this.plantId, this.process, {this.wateredAt});
  Map<String, dynamic> toJson() => {
    'plantId': plantId,
    'process': process.toJson(),
    'wateredAt': wateredAt?.toIso8601String(),
  };
  factory GrowingBed.fromJson(Map<String, dynamic> j) => GrowingBed(
    j['plantId'],
    ProcessInstance.fromJson(Map<String, dynamic>.from(j['process'])),
    wateredAt: DateTime.tryParse(j['wateredAt'] ?? ''),
  );
  bool needsCare(DateTime now) =>
      wateredAt == null || now.difference(wateredAt!).inHours >= 8;
}
