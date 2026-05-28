"""
惜物 API — JWT 令牌与密码安全工具
"""
import uuid
from datetime import datetime, timedelta, timezone

import jwt
from passlib.context import CryptContext

from app.config import settings
from app.core.exceptions import AuthenticationError

# 密码加密上下文
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """使用 bcrypt 加密密码"""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """验证明文密码与哈希是否匹配"""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(
    data: dict,
    expires_delta: timedelta | None = None,
) -> str:
    """
    创建 Access Token
    :param data: payload 数据，必须包含 "sub" (user_id)
    :param expires_delta: 自定义过期时间
    :return: JWT 字符串
    """
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(minutes=settings.jwt_access_token_expire_minutes))

    to_encode = {
        **data,
        "type": "access",
        "exp": expire,
        "iat": now,
    }
    return jwt.encode(to_encode, settings.jwt_secret_key, algorithm="HS256")


def create_refresh_token(
    data: dict,
    expires_delta: timedelta | None = None,
) -> str:
    """
    创建 Refresh Token
    :param data: payload 数据，必须包含 "sub" (user_id)
    :param expires_delta: 自定义过期时间
    :return: JWT 字符串
    """
    now = datetime.now(timezone.utc)
    expire = now + (expires_delta or timedelta(days=settings.jwt_refresh_token_expire_days))

    to_encode = {
        **data,
        "type": "refresh",
        "jti": str(uuid.uuid4()),  # 唯一标识，用于黑名单
        "exp": expire,
        "iat": now,
    }
    return jwt.encode(to_encode, settings.jwt_secret_key, algorithm="HS256")


def decode_token(token: str) -> dict:
    """
    解码并验证 JWT 令牌
    :param token: JWT 字符串
    :return: payload 字典
    :raises AuthenticationError: 令牌无效或已过期
    """
    try:
        payload = jwt.decode(token, settings.jwt_secret_key, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise AuthenticationError("令牌已过期")
    except jwt.InvalidTokenError:
        raise AuthenticationError("无效的令牌")
