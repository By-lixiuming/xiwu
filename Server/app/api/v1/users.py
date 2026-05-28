"""
惜物 API — 用户路由
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.user import UserResponse, UserUpdateRequest, PasswordChangeRequest
from app.services import user_service

router = APIRouter()


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
):
    """获取当前用户信息"""
    return UserResponse(
        id=str(current_user.id),
        phone=current_user.phone,
        nickname=current_user.nickname,
        avatar_emoji=current_user.avatar_emoji,
        created_at=current_user.created_at,
        last_login_at=current_user.last_login_at,
    )


@router.put("/me", response_model=UserResponse)
async def update_me(
    request: UserUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """更新用户信息"""
    user = await user_service.update_user(
        db=db,
        user=current_user,
        nickname=request.nickname,
        avatar_emoji=request.avatar_emoji,
    )
    return UserResponse(
        id=str(user.id),
        phone=user.phone,
        nickname=user.nickname,
        avatar_emoji=user.avatar_emoji,
        created_at=user.created_at,
        last_login_at=user.last_login_at,
    )


@router.put("/me/password")
async def change_password(
    request: PasswordChangeRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """修改密码"""
    await user_service.change_password(
        db=db,
        user=current_user,
        old_password=request.old_password,
        new_password=request.new_password,
    )
    return {"message": "密码修改成功"}


@router.delete("/me")
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """注销账号"""
    await user_service.delete_user(db=db, user=current_user)
    return {"message": "账号已注销"}
