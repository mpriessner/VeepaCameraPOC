import 'dart:convert';

class P2PCredentials {
  final String cameraUid;
  final String clientId;
  final String serviceParam;
  final String? password;
  final DateTime cachedAt;
  final String? supplier;
  final String? cluster;

  P2PCredentials({
    required this.cameraUid,
    required this.clientId,
    required this.serviceParam,
    this.password,
    required this.cachedAt,
    this.supplier,
    this.cluster,
  });

  bool get isValid =>
      cameraUid.isNotEmpty &&
      clientId.isNotEmpty &&
      serviceParam.isNotEmpty;

  String? validate() {
    if (cameraUid.isEmpty) return 'Camera UID is empty';
    if (clientId.isEmpty) return 'Client ID is empty';
    if (clientId.length < 5) return 'Client ID too short';
    if (serviceParam.isEmpty) return 'Service param is empty';
    if (serviceParam.length < 20) return 'Service param too short';
    return null;
  }

  Duration get cacheAge => DateTime.now().difference(cachedAt);

  String get cacheAgeDescription {
    final age = cacheAge;
    if (age.inSeconds < 60) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes} min ago';
    if (age.inHours < 24) return '${age.inHours} hours ago';
    return '${age.inDays} days ago';
  }

  String get maskedClientId {
    if (clientId.length <= 8) return '****';
    return '${clientId.substring(0, 4)}...${clientId.substring(clientId.length - 4)}';
  }

  String get maskedServiceParam {
    if (serviceParam.length <= 8) return '****';
    return '${serviceParam.substring(0, 4)}...${serviceParam.substring(serviceParam.length - 4)}';
  }

  Map<String, dynamic> toJson() => {
        'cameraUid': cameraUid,
        'clientId': clientId,
        'serviceParam': serviceParam,
        'password': password,
        'cachedAt': cachedAt.toIso8601String(),
        'supplier': supplier,
        'cluster': cluster,
      };

  factory P2PCredentials.fromJson(Map<String, dynamic> json) => P2PCredentials(
        cameraUid: json['cameraUid'] as String,
        clientId: json['clientId'] as String,
        serviceParam: json['serviceParam'] as String,
        password: json['password'] as String?,
        cachedAt: DateTime.parse(json['cachedAt'] as String),
        supplier: json['supplier'] as String?,
        cluster: json['cluster'] as String?,
      );

  String toJsonString() => jsonEncode(toJson());

  factory P2PCredentials.fromJsonString(String jsonString) =>
      P2PCredentials.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  P2PCredentials copyWith({
    String? cameraUid,
    String? clientId,
    String? serviceParam,
    String? password,
    DateTime? cachedAt,
    String? supplier,
    String? cluster,
  }) =>
      P2PCredentials(
        cameraUid: cameraUid ?? this.cameraUid,
        clientId: clientId ?? this.clientId,
        serviceParam: serviceParam ?? this.serviceParam,
        password: password ?? this.password,
        cachedAt: cachedAt ?? this.cachedAt,
        supplier: supplier ?? this.supplier,
        cluster: cluster ?? this.cluster,
      );

  @override
  String toString() =>
      'P2PCredentials(cameraUid: $cameraUid, clientId: $maskedClientId, cached: $cacheAgeDescription)';
}
