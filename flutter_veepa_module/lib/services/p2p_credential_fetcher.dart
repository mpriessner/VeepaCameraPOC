import 'package:dio/dio.dart';
import '../models/p2p_credentials.dart';

class P2PCredentialFetcher {
  final Dio _dio;
  final Duration _timeout;

  P2PCredentialFetcher({
    Dio? dio,
    Duration timeout = const Duration(seconds: 10),
  })  : _dio = dio ?? Dio(),
        _timeout = timeout;

  Future<FetchResult<String>> fetchClientId(String virtualUid) async {
    try {
      final url = 'https://vuid.eye4.cn?vuid=$virtualUid';
      final response = await _dio
          .get<Map<String, dynamic>>(
            url,
            options: Options(
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final uid = data['uid'] as String?;
        final supplier = data['supplier'] as String?;
        final cluster = data['cluster'] as String?;

        if (uid != null && uid.isNotEmpty) {
          return FetchResult.success(
            uid,
            metadata: {'supplier': supplier, 'cluster': cluster},
          );
        } else {
          return FetchResult.failure('Response missing uid field');
        }
      } else {
        return FetchResult.failure(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      return FetchResult.failure(_formatDioError(e));
    } catch (e) {
      return FetchResult.failure('Unexpected error: $e');
    }
  }

  Future<FetchResult<String>> fetchServiceParam(String uidPrefix) async {
    try {
      final url = 'https://authentication.eye4.cn/getInitstring';
      final response = await _dio
          .post<List<dynamic>>(
            url,
            data: {
              'uid': [uidPrefix]
            },
            options: Options(
              headers: {'Content-Type': 'application/json; charset=utf-8'},
              receiveTimeout: _timeout,
              sendTimeout: _timeout,
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        if (data.isNotEmpty && data[0] is String) {
          final serviceParam = data[0] as String;
          if (serviceParam.isNotEmpty) {
            return FetchResult.success(serviceParam);
          }
        }
        return FetchResult.failure('Response empty or invalid format');
      } else {
        return FetchResult.failure(
            'HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      return FetchResult.failure(_formatDioError(e));
    } catch (e) {
      return FetchResult.failure('Unexpected error: $e');
    }
  }

  Future<CredentialFetchResult> fetchAllCredentials(String cameraUid) async {
    final clientIdResult = await fetchClientId(cameraUid);
    if (!clientIdResult.isSuccess) {
      return CredentialFetchResult.failure(
        'Failed to fetch clientId: ${clientIdResult.error}',
        step: 'clientId',
      );
    }

    // Use prefix from REAL clientId, not the virtual UID
    final realClientId = clientIdResult.data!;
    final realPrefix = _extractPrefix(realClientId);

    final serviceParamResult = await fetchServiceParam(realPrefix);
    if (!serviceParamResult.isSuccess) {
      return CredentialFetchResult.failure(
        'Failed to fetch serviceParam for prefix $realPrefix: ${serviceParamResult.error}',
        step: 'serviceParam',
      );
    }

    final credentials = P2PCredentials(
      cameraUid: cameraUid,
      clientId: clientIdResult.data!,
      serviceParam: serviceParamResult.data!,
      cachedAt: DateTime.now(),
      supplier: clientIdResult.metadata?['supplier'] as String?,
      cluster: clientIdResult.metadata?['cluster'] as String?,
    );

    return CredentialFetchResult.success(credentials);
  }

  String _extractPrefix(String cameraUid) {
    if (cameraUid.length >= 4) {
      return cameraUid.substring(0, 4);
    }
    return cameraUid;
  }

  String _formatDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout - check internet';
      case DioExceptionType.sendTimeout:
        return 'Send timeout - server not responding';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout - server too slow';
      case DioExceptionType.badResponse:
        return 'Bad response: ${e.response?.statusCode}';
      case DioExceptionType.connectionError:
        return 'Connection error - no internet?';
      default:
        return 'Network error: ${e.message}';
    }
  }
}

class FetchResult<T> {
  final T? data;
  final String? error;
  final Map<String, dynamic>? metadata;

  FetchResult._({this.data, this.error, this.metadata});

  factory FetchResult.success(T data, {Map<String, dynamic>? metadata}) =>
      FetchResult._(data: data, metadata: metadata);

  factory FetchResult.failure(String error) => FetchResult._(error: error);

  bool get isSuccess => data != null && error == null;
}

class CredentialFetchResult {
  final P2PCredentials? credentials;
  final String? error;
  final String? failedStep;

  CredentialFetchResult._({this.credentials, this.error, this.failedStep});

  factory CredentialFetchResult.success(P2PCredentials credentials) =>
      CredentialFetchResult._(credentials: credentials);

  factory CredentialFetchResult.failure(String error, {String? step}) =>
      CredentialFetchResult._(error: error, failedStep: step);

  bool get isSuccess => credentials != null && error == null;
}
