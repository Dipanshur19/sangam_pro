class StoreProfile {
  final String name;
  final String ownerName;
  final String location;
  final String? phone;
  final int creditDueDays;

  const StoreProfile({
    required this.name,
    this.ownerName = '',
    this.location = '',
    this.phone,
    this.creditDueDays = 7,
  });

  bool get isConfigured => name.trim().isNotEmpty;

  StoreProfile copyWith({
    String? name,
    String? ownerName,
    String? location,
    String? phone,
    int? creditDueDays,
  }) =>
      StoreProfile(
        name: name ?? this.name,
        ownerName: ownerName ?? this.ownerName,
        location: location ?? this.location,
        phone: phone ?? this.phone,
        creditDueDays: creditDueDays ?? this.creditDueDays,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerName': ownerName,
        'location': location,
        'phone': phone,
        'creditDueDays': creditDueDays,
      };

  factory StoreProfile.fromMap(Map<String, dynamic> m) => StoreProfile(
        name: m['name'] as String? ?? '',
        ownerName: m['ownerName'] as String? ?? '',
        location: m['location'] as String? ?? '',
        phone: m['phone'] as String?,
        creditDueDays: (m['creditDueDays'] as num?)?.toInt() ?? 7,
      );

  static const empty = StoreProfile(name: '');
}
