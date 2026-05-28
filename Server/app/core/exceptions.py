"""
惜物 API — 自定义异常
统一异常处理，简化错误响应
"""


class XiwuException(Exception):
    """基础异常"""
    def __init__(self, message: str = "服务器内部错误", status_code: int = 400):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class AuthenticationError(XiwuException):
    """认证失败（401）"""
    def __init__(self, message: str = "认证失败"):
        super().__init__(message=message, status_code=401)


class AuthorizationError(XiwuException):
    """权限不足（403）"""
    def __init__(self, message: str = "权限不足"):
        super().__init__(message=message, status_code=403)


class NotFoundError(XiwuException):
    """资源不存在（404）"""
    def __init__(self, message: str = "资源不存在"):
        super().__init__(message=message, status_code=404)


class ConflictError(XiwuException):
    """资源冲突（409）"""
    def __init__(self, message: str = "资源冲突"):
        super().__init__(message=message, status_code=409)
