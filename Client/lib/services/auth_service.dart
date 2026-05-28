import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'api_service.dart';

class AuthService extends GetxService {
  final ApiService _apiService = Get.find<ApiService>();
  
  // 响应式状态
  final RxBool isLoggedIn = false.obs;
  final Rx<Map<String, dynamic>?> currentUser = Rx<Map<String, dynamic>?>(null);

  Future<AuthService> init() async {
    // 启动时检查是否有有效的 token
    await _checkAuthStatus();
    return this;
  }

  Future<void> _checkAuthStatus() async {
    try {
      final token = await _apiService.secureStorage.read(key: 'access_token');
      if (token != null && !JwtDecoder.isExpired(token)) {
        isLoggedIn.value = true;
        // 尝试获取本地缓存的用户信息
        final userStr = await _apiService.secureStorage.read(key: 'user_info');
        // 这里只是简单处理，更好的做法是用 Hive 或 SharedPreferences
        // 但安全存储也可以临时用
        if (userStr != null) {
          // parse logic if needed, we'll fetch from /users/me anyway
        }
        await fetchUserInfo();
      } else {
        isLoggedIn.value = false;
        currentUser.value = null;
      }
    } catch (e) {
      isLoggedIn.value = false;
      currentUser.value = null;
    }
  }

  Future<bool> login(String phone, String password) async {
    try {
      final response = await _apiService.dio.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });

      if (response.statusCode == 200) {
        await _saveTokens(response.data);
        isLoggedIn.value = true;
        
        // 解析用户信息并保存
        currentUser.value = {
          'user_id': response.data['user_id'],
          'phone': response.data['phone'],
          'nickname': response.data['nickname'],
          'avatar_emoji': response.data['avatar_emoji'],
        };
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar('登录失败', e.response?.data['detail'] ?? '网络错误');
      return false;
    }
  }

  Future<bool> register(String phone, String password, String nickname) async {
    try {
      final response = await _apiService.dio.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'nickname': nickname,
      });

      if (response.statusCode == 201) {
        await _saveTokens(response.data);
        isLoggedIn.value = true;
        
        currentUser.value = {
          'user_id': response.data['user_id'],
          'phone': response.data['phone'],
          'nickname': response.data['nickname'],
          'avatar_emoji': response.data['avatar_emoji'],
        };
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar('注册失败', e.response?.data['detail'] ?? '网络错误');
      return false;
    }
  }

  Future<void> fetchUserInfo() async {
    try {
      final response = await _apiService.dio.get('/users/me');
      if (response.statusCode == 200) {
        currentUser.value = response.data;
      }
    } catch (e) {
      print('Fetch user info failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.dio.post('/auth/logout');
    } catch (e) {
      // 忽略登出时的网络错误
    } finally {
      await _apiService.secureStorage.deleteAll();
      isLoggedIn.value = false;
      currentUser.value = null;
      // TODO: 清除 Hive 里的数据？根据需求决定
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await _apiService.secureStorage.write(key: 'access_token', value: data['access_token']);
    await _apiService.secureStorage.write(key: 'refresh_token', value: data['refresh_token']);
  }
}
