class StoreProfile {
  final String name;
  final String ownerName;
  final String location;
  final String? phone;
  final int creditDueDays;

  // Business information (OkCredit-style profile)
  final String gst;
  final String businessType;
  final String category;
  final String address;
  final String email;
  final String upiId;

  const StoreProfile({
    required this.name,
    this.ownerName = '',
    this.location = '',
    this.phone,
    this.creditDueDays = 7,
    this.gst = '',
    this.businessType = '',
    this.category = '',
    this.address = '',
    this.email = '',
    this.upiId = '',
  });

  bool get isConfigured => name.trim().isNotEmpty;

  StoreProfile copyWith({
    String? name,
    String? ownerName,
    String? location,
    String? phone,
    int? creditDueDays,
    String? gst,
    String? businessType,
    String? category,
    String? address,
    String? email,
    String? upiId,
  }) =>
      StoreProfile(
        name: name ?? this.name,
        ownerName: ownerName ?? this.ownerName,
        location: location ?? this.location,
        phone: phone ?? this.phone,
        creditDueDays: creditDueDays ?? this.creditDueDays,
        gst: gst ?? this.gst,
        businessType: businessType ?? this.businessType,
        category: category ?? this.category,
        address: address ?? this.address,
        email: email ?? this.email,
        upiId: upiId ?? this.upiId,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'ownerName': ownerName,
        'location': location,
        'phone': phone,
        'creditDueDays': creditDueDays,
        'gst': gst,
        'businessType': businessType,
        'category': category,
        'address': address,
        'email': email,
        'upiId': upiId,
      };

  factory StoreProfile.fromMap(Map<String, dynamic> m) => StoreProfile(
        name: m['name'] as String? ?? '',
        ownerName: m['ownerName'] as String? ?? '',
        location: m['location'] as String? ?? '',
        phone: m['phone'] as String?,
        creditDueDays: (m['creditDueDays'] as num?)?.toInt() ?? 7,
        gst: m['gst'] as String? ?? '',
        businessType: m['businessType'] as String? ?? '',
        category: m['category'] as String? ?? '',
        address: m['address'] as String? ?? '',
        email: m['email'] as String? ?? '',
        upiId: m['upiId'] as String? ?? '',
      );

  static const empty = StoreProfile(name: '');
}
