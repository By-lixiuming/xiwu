"""
惜物 API — 用户业务逻辑
"""
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import AuthenticationError
from app.core.security import hash_password, verify_password
from app.models.user import User


async def get_user_by_id(db: AsyncSession, user_id: UUID) -> User | None:
    """根据ID查询用户"""
    result = await db.execute(select(User).where(User.id == user_id))
    return result.scalar_one_or_none()


async def update_user(
    db: AsyncSession,
    user: User,
    nickname: str | None = None,
    avatar_emoji: str | None = None,
) -> User:
    """更新用户信息"""
    if nickname is not None:
        user.nickname = nickname
    if avatar_emoji is not None:
        user.avatar_emoji = avatar_emoji
    await db.flush()
    return user


async def change_password(
    db: AsyncSession,
    user: User,
    old_password: str,
    new_password: str,
) -> bool:
    """
    修改密码
    :raises AuthenticationError: 旧密码错误
    """
    if not verify_password(old_password, user.password_hash):
        raise AuthenticationError("旧密码错误")

    user.password_hash = hash_password(new_password)
    await db.flush()
    return True


async def delete_user(db: AsyncSession, user: User) -> None:
    """注销账号（软删除：设置 is_active=False）"""
    user.is_active = False
    await db.flush()
