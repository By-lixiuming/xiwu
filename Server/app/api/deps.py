"""
惜物 API — API 依赖注入
提供数据库 Session 和当前用户获取
"""
from uuid import UUID

from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import async_session_factory
from app.core.security import decode_token
from app.core.exceptions import AuthenticationError
from app.models.user import User

# OAuth2 Bearer 令牌提取
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_db():
    """获取数据库 Session"""
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    """
    从 JWT 令牌中获取当前登录用户
    :raises AuthenticationError: 令牌无效或用户不存在
    """
    # 解码令牌
    payload = decode_token(token)

    # 验证令牌类型
    if payload.get("type") != "access":
        raise AuthenticationError("无效的令牌类型")

    # 获取用户 ID
    user_id_str = payload.get("sub")
    if not user_id_str:
        raise AuthenticationError("令牌中缺少用户信息")

    try:
        user_id = UUID(user_id_str)
    except ValueError:
        raise AuthenticationError("无效的用户ID")

    # 查询用户
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise AuthenticationError("用户不存在")
    if not user.is_active:
        raise AuthenticationError("账号已被停用")

    return user
