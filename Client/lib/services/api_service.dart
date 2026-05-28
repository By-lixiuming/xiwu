import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response;

class ApiService extends GetxService {
  late final Dio dio;
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  
  // TODO: 后续可以改成从设置读取或环境变量
  final String baseUrl = 'http://10.0.2.2:8000/api/v1';

  Future<ApiService> init() async {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: 'application/json',
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 尝试从安全存储获取 token
        final accessToken = await secureStorage.read(key: 'access_token');
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // 如果是 401 错误，尝试刷新 token
        if (e.response?.statusCode == 401) {
          final refreshToken = await secureStorage.read(key: 'refresh_token');
          if (refreshToken != null) {
            try {
              // 发起刷新请求
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final response = await refreshDio.post(
                '/auth/refresh',
                options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
              );

              if (response.statusCode == 200) {
                // 保存新 token
                final newAccessToken = response.data['access_token'];
                final newRefreshToken = response.data['refresh_token'];
                await secureStorage.write(key: 'access_token', value: newAccessToken);
                await secureStorage.write(key: 'refresh_token', value: newRefreshToken);

                // 重试原始请求
                final opts = Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                );
                opts.headers?['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await dio.request(
                  e.requestOptions.path,
                  options: opts,
                  data: e.requestOptions.data,
                  queryParameters: e.requestOptions.queryParameters,
                );
                return handler.resolve(cloneReq);
              }
            } catch (refreshErr) {
              // 刷新失败，强制退出登录
              await secureStorage.deleteAll();
              // TODO: 通知 Auth 控制器更新状态为未登录
              print('Refresh token expired or invalid');
            }
          }
        }
        return handler.next(e);
      },
    ));

    return this;
  }
}
