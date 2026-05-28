"""
惜物 API — 用户相关请求/响应模型
"""
import re
from datetime import datetime
from pydantic import BaseModel, ConfigDict, field_validator


class UserResponse(BaseModel):
    """用户信息响应"""
    id: str
    phone: str
    nickname: str
    avatar_emoji: str
    created_at: datetime
    last_login_at: datetime | None = None

    model_config = ConfigDict(from_attributes=True)


class UserUpdateRequest(BaseModel):
    """更新用户信息请求"""
    nickname: str | None = None
    avatar_emoji: str | None = None


class PasswordChangeRequest(BaseModel):
    """修改密码请求"""
    old_password: str
    new_password: str

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, v: str) -> str:
        if len(v) < 8 or len(v) > 32:
            raise ValueError("新密码长度需要 8-32 位")
        if not re.search(r"[a-zA-Z]", v) or not re.search(r"\d", v):
            raise ValueError("新密码需要同时包含字母和数字")
        return v
