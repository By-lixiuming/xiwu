"""
惜物 API — 认证相关请求/响应模型
"""
import re
from pydantic import BaseModel, ConfigDict, field_validator


class RegisterRequest(BaseModel):
    """注册请求"""
    phone: str
    password: str
    nickname: str | None = None

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, v: str) -> str:
        if not re.match(r"^1[3-9]\d{9}$", v):
            raise ValueError("请输入有效的手机号")
        return v

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str) -> str:
        if len(v) < 8 or len(v) > 32:
            raise ValueError("密码长度需要 8-32 位")
        if not re.search(r"[a-zA-Z]", v) or not re.search(r"\d", v):
            raise ValueError("密码需要同时包含字母和数字")
        return v


class LoginRequest(BaseModel):
    """登录请求"""
    phone: str
    password: str


class TokenResponse(BaseModel):
    """登录/注册成功响应"""
    user_id: str
    phone: str
    nickname: str
    avatar_emoji: str
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

    model_config = ConfigDict(from_attributes=True)


class RefreshResponse(BaseModel):
    """令牌刷新响应"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
