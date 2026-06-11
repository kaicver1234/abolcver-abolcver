import 'package:dio/dio.dart';

/// Thin Cloudflare speed-test client over a raw [Dio] instance.
///
/// This is the hand-written equivalent of the reference project's Retrofit
/// interface — same endpoints, same query params, same progress callbacks —
/// but with no code generation (no build_runner / .g.dart) so it drops into a
/// plain `provider` app with only `dio` as a dependency.
///
/// Protocol: https://speed.cloudflare.com
///   GET  /__down?bytes=N&measId=…   → N bytes of data (also used for latency
///                                      with bytes=0)
///   POST /__up?measId=…             → sink for upload bytes
class SpeedTestApi {
  final Dio _dio;
  static const String baseUrl = 'https://speed.cloudflare.com';

  SpeedTestApi(this._dio);

  /// Download `bytes` from Cloudflare. Returns the response so the caller can
  /// measure wall-clock duration and read `response.data.length`.
  Future<Response<List<int>>> downloadTest({
    required int bytes,
    required String measurementId,
    String? during,
    ProgressCallback? onReceiveProgress,
    CancelToken? cancelToken,
  }) {
    return _dio.get<List<int>>(
      '$baseUrl/__down',
      queryParameters: {
        'bytes': bytes,
        'measId': measurementId,
        if (during != null) 'during': during,
      },
      options: Options(
        responseType: ResponseType.bytes,
        headers: const {
          'Cache-Control': 'no-cache, no-store',
          'Accept-Encoding': 'identity',
        },
      ),
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
  }

  /// Upload a stream of bytes to Cloudflare. `contentLength` must match the
  /// total number of bytes the stream will emit so the server accepts it as a
  /// fixed-size body (this is what makes the upload measurement reliable).
  Future<Response<dynamic>> uploadTest(
    Stream<List<int>> data, {
    required int contentLength,
    required String measurementId,
    String? during,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) {
    return _dio.post(
      '$baseUrl/__up',
      data: data,
      queryParameters: {
        'measId': measurementId,
        if (during != null) 'during': during,
      },
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Length': contentLength,
          'Cache-Control': 'no-cache, no-store',
        },
      ),
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
    );
  }

  /// Minimal ping: download zero bytes and time the round-trip.
  Future<Response<dynamic>> latencyTest({
    int bytes = 0,
    required String measurementId,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      '$baseUrl/__down',
      queryParameters: {'bytes': bytes, 'measId': measurementId},
      options: Options(
        headers: const {'Cache-Control': 'no-cache, no-store'},
      ),
      cancelToken: cancelToken,
    );
  }
}
