"""
惜物 API — 认证业务逻辑
"""
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.core.exceptions import AuthenticationError, ConflictError
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
)
from app.models.user import User


async def register_user(
    db: AsyncSession,
    phone: str,
    password: str,
    nickname: str | None = None,
) -> User:
    """
    注册新用户
    :raises ConflictError: 手机号已被注册
    """
    # 检查手机号是否已注册
    result = await db.execute(select(User).where(User.phone == phone))
    existing = result.scalar_one_or_none()
    if existing:
        raise ConflictError("该手机号已被注册")

    # 创建用户
    user = User(
        phone=phone,
        password_hash=hash_password(password),
        nickname=nickname or "惜物用户",
    )
    db.add(user)
    await db.flush()  # 获取生成的 ID
    return user


async def authenticate_user(
    db: AsyncSession,
    phone: str,
    password: str,
) -> User:
    """
    验证用户登录
    :raises AuthenticationError: 手机号或密码错误
    """
    result = await db.execute(select(User).where(User.phone == phone))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(password, user.password_hash):
        raise AuthenticationError("手机号或密码错误")

    if not user.is_active:
        raise AuthenticationError("账号已被停用")

    # 更新最后登录时间
    user.last_login_at = datetime.now(timezone.utc)
    await db.flush()

    return user


def create_tokens(user: User) -> dict:
    """
    为用户生成 access_token 和 refresh_token
    :return: 包含令牌信息的字典
    """
    token_data = {"sub": str(user.id)}

    access_token = create_access_token(token_data)
    refresh_token = create_refresh_token(token_data)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": settings.jwt_access_token_expire_minutes * 60,  # 秒
    }
