"""
惜物 API — 认证路由
"""
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user, oauth2_scheme
from app.core.security import decode_token, create_access_token, create_refresh_token
from app.core.exceptions import AuthenticationError
from app.models.user import User
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    RefreshResponse,
)
from app.services import auth_service
from app.config import settings

router = APIRouter()


@router.post("/register", response_model=TokenResponse, status_code=201)
async def register(
    request: RegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    """手机号注册"""
    user = await auth_service.register_user(
        db=db,
        phone=request.phone,
        password=request.password,
        nickname=request.nickname,
    )
    tokens = auth_service.create_tokens(user)

    return TokenResponse(
        user_id=str(user.id),
        phone=user.phone,
        nickname=user.nickname,
        avatar_emoji=user.avatar_emoji,
        **tokens,
    )


@router.post("/login", response_model=TokenResponse)
async def login(
    request: LoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """手机号密码登录"""
    user = await auth_service.authenticate_user(
        db=db,
        phone=request.phone,
        password=request.password,
    )
    tokens = auth_service.create_tokens(user)

    return TokenResponse(
        user_id=str(user.id),
        phone=user.phone,
        nickname=user.nickname,
        avatar_emoji=user.avatar_emoji,
        **tokens,
    )


@router.post("/refresh", response_model=RefreshResponse)
async def refresh_token(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
):
    """刷新令牌"""
    # 解码 refresh token
    payload = decode_token(token)
    if payload.get("type") != "refresh":
        raise AuthenticationError("需要使用 refresh token")

    user_id = payload.get("sub")
    if not user_id:
        raise AuthenticationError("无效的令牌")

    # 生成新的令牌对
    token_data = {"sub": user_id}
    new_access_token = create_access_token(token_data)
    new_refresh_token = create_refresh_token(token_data)

    return RefreshResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
        expires_in=settings.jwt_access_token_expire_minutes * 60,
    )


@router.post("/logout")
async def logout(
    current_user: User = Depends(get_current_user),
):
    """退出登录（后续可加入 token 黑名单）"""
    return {"message": "已成功退出登录"}
