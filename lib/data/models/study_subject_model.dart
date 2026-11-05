import '../../domain/entities/study_enums.dart';
import '../../domain/entities/study_subject.dart';

class StudySubjectModel {
  final String id;
  final String? userId;
  final String name;
  final String colorHex;
  final bool isArchived;
  final String createdAtIso8601;
  final String updatedAtIso8601;
  final String syncStatus;

  const StudySubjectModel({
    required this.id,
    this.userId,
    required this.name,
    required this.colorHex,
    required this.isArchived,
    required this.createdAtIso8601,
    required this.updatedAtIso8601,
    required this.syncStatus,
  });

  static String _reqStr(Map<String, Object?> m, String k) {
    final Object? v = m[k];
    if (v is! String || v.trim().isEmpty) {
      throw FormatException('Invalid or missing subject "$k" field.');
    }
    return v.trim();
  }

  static String? _optStr(Map<String, Object?> m, String k) {
    final Object? v = m[k];
    if (v == null) return null;
    if (v is! String) throw FormatException('Invalid subject "$k" field.');
    return v.trim().isEmpty ? null : v.trim();
  }

  static bool _reqBool(Object? raw, String k) {
    if (raw is bool) return raw;
    if (raw is int && (raw == 0 || raw == 1)) return raw == 1;
    throw FormatException('Invalid or missing subject "$k" field.');
  }

  static DateTime _reqDate(Object? raw, String k) {
    if (raw is! String || raw.trim().isEmpty) {
      throw FormatException('Invalid or missing subject "$k" field.');
    }
    return DateTime.tryParse(raw.trim()) ??
        (throw FormatException('Malformed ISO-8601 subject "$k" field.'));
  }

  factory StudySubjectModel.fromEntity(StudySubject e) {
    final StudySubject v = StudySubject.validated(
      id: e.id,
      userId: e.userId,
      name: e.name,
      colorHex: e.colorHex,
      isArchived: e.isArchived,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      syncStatus: e.syncStatus,
    );
    return StudySubjectModel(
      id: v.id,
      userId: v.userId,
      name: v.name,
      colorHex: v.colorHex,
      isArchived: v.isArchived,
      createdAtIso8601: v.createdAt.toIso8601String(),
      updatedAtIso8601: v.updatedAt.toIso8601String(),
      syncStatus: v.syncStatus.name,
    );
  }

  factory StudySubjectModel.fromMap(Map<String, Object?> m) {
    final bool archived = _reqBool(m['isArchived'], 'isArchived');
    try {
      return StudySubjectModel.fromEntity(
        StudySubject.validated(
          id: _reqStr(m, 'id'),
          userId: _optStr(m, 'userId'),
          name: _reqStr(m, 'name'),
          colorHex: _reqStr(m, 'colorHex'),
          isArchived: archived,
          createdAt: _reqDate(
            m['createdAt'] ?? m['createdAtIso8601'],
            'createdAt',
          ),
          updatedAt: _reqDate(
            m['updatedAt'] ?? m['updatedAtIso8601'],
            'updatedAt',
          ),
          syncStatus: SyncStatus.fromStorageString(_reqStr(m, 'syncStatus')),
        ),
      );
    } on StudySubjectValidationException catch (e) {
      throw FormatException(e.message);
    }
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'userId': userId,
    'name': name,
    'colorHex': colorHex,
    'isArchived': isArchived,
    'createdAt': createdAtIso8601,
    'updatedAt': updatedAtIso8601,
    'syncStatus': syncStatus,
  };

  Map<String, Object?> toSqlMap() => <String, Object?>{
    'id': id,
    'user_id': userId,
    'name': name,
    'color_hex': colorHex,
    'is_archived': isArchived ? 1 : 0,
    'created_at': createdAtIso8601,
    'updated_at': updatedAtIso8601,
    'sync_status': syncStatus,
  };

  factory StudySubjectModel.fromSqlMap(Map<String, Object?> row) =>
      StudySubjectModel.fromMap(<String, Object?>{
        'id': row['id'],
        'userId': row['user_id'],
        'name': row['name'],
        'colorHex': row['color_hex'],
        'isArchived': row['is_archived'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
        'syncStatus': row['sync_status'],
      });

  StudySubject toEntity() => StudySubject.validated(
    id: id,
    userId: userId,
    name: name,
    colorHex: colorHex,
    isArchived: isArchived,
    createdAt: _reqDate(createdAtIso8601, 'createdAtIso8601'),
    updatedAt: _reqDate(updatedAtIso8601, 'updatedAtIso8601'),
    syncStatus: SyncStatus.fromStorageString(syncStatus),
  );

  StudySubjectModel copyWith({
    String? id,
    String? userId,
    bool clearUserId = false,
    String? name,
    String? colorHex,
    bool? isArchived,
    String? createdAtIso8601,
    String? updatedAtIso8601,
    String? syncStatus,
  }) => StudySubjectModel(
    id: id ?? this.id,
    userId: clearUserId ? null : (userId ?? this.userId),
    name: name ?? this.name,
    colorHex: colorHex ?? this.colorHex,
    isArchived: isArchived ?? this.isArchived,
    createdAtIso8601: createdAtIso8601 ?? this.createdAtIso8601,
    updatedAtIso8601: updatedAtIso8601 ?? this.updatedAtIso8601,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  List<Object?> get _props => <Object?>[
    id,
    userId,
    name,
    colorHex,
    isArchived,
    createdAtIso8601,
    updatedAtIso8601,
    syncStatus,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StudySubjectModel) return false;
    final List<Object?> a = _props, b = other._props;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}
