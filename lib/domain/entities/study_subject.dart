import 'study_enums.dart';

class StudySubjectValidationException implements Exception {
  final String message;
  const StudySubjectValidationException(this.message);

  @override
  String toString() => 'StudySubjectValidationException: $message';
}

class StudySubject {
  static final RegExp _hexPattern = RegExp(r'^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$');

  final String id;
  final String? userId;
  final String name;
  final String colorHex;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  const StudySubject({
    required this.id, this.userId, required this.name,
    this.colorHex = '#3F51B5', this.isArchived = false,
    required this.createdAt, required this.updatedAt,
    this.syncStatus = SyncStatus.localOnly,
  });

  static Never _fail(String msg) => throw StudySubjectValidationException(msg);

  factory StudySubject.validated({
    required String id, String? userId, required String name,
    String colorHex = '#3F51B5', bool isArchived = false,
    required DateTime createdAt, DateTime? updatedAt,
    SyncStatus syncStatus = SyncStatus.localOnly,
  }) {
    final String cleanId = id.trim();
    if (cleanId.isEmpty) _fail('Subject ID must not be empty.');
    final String cleanName = name.trim();
    if (cleanName.isEmpty) _fail('Subject name must not be empty.');
    final String cleanHex = colorHex.trim();
    if (!_hexPattern.hasMatch(cleanHex)) {
      _fail('Subject colorHex must match #RRGGBB or #AARRGGBB.');
    }
    final DateTime updated = updatedAt ?? createdAt;
    if (updated.isBefore(createdAt)) {
      _fail('Subject updatedAt must not be before createdAt.');
    }
    return StudySubject(
      id: cleanId,
      userId: (userId == null || userId.trim().isEmpty) ? null : userId.trim(),
      name: cleanName, colorHex: cleanHex, isArchived: isArchived,
      createdAt: createdAt, updatedAt: updated, syncStatus: syncStatus,
    );
  }

  StudySubject copyWith({
    String? id, String? userId, bool clearUserId = false,
    String? name, String? colorHex, bool? isArchived,
    DateTime? createdAt, DateTime? updatedAt, SyncStatus? syncStatus,
  }) => StudySubject(
    id: id ?? this.id,
    userId: clearUserId ? null : (userId ?? this.userId),
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySubject &&
          other.id == id && other.userId == userId &&
          other.name == name && other.colorHex == colorHex &&
          other.isArchived == isArchived && other.createdAt == createdAt &&
          other.updatedAt == updatedAt && other.syncStatus == syncStatus);

  @override
  int get hashCode =>
      Object.hash(id, userId, name, colorHex, isArchived, createdAt, updatedAt, syncStatus);
}
