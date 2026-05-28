"""
惜物 API — 用户 ORM 模型
"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import String, Boolean, DateTime, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class User(Base):
    """用户表"""
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("uuid_generate_v4()"),
    )
    phone: Mapped[str] = mapped_column(
        String(20), unique=True, nullable=False, index=True, comment="手机号"
    )
    password_hash: Mapped[str] = mapped_column(
        String(128), nullable=False, comment="bcrypt密码哈希"
    )
    nickname: Mapped[str] = mapped_column(
        String(50), default="惜物用户", server_default="惜物用户", comment="昵称"
    )
    avatar_emoji: Mapped[str] = mapped_column(
        String(10), default="😊", server_default="😊", comment="头像emoji"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        server_default=text("NOW()"),
        comment="注册时间",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        server_default=text("NOW()"),
        comment="更新时间",
    )
    is_active: Mapped[bool] = mapped_column(
        Boolean, default=True, server_default=text("true"), comment="账号是否激活"
    )
    last_login_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="最后登录时间"
    )

    # 关联资产列表
    assets = relationship("AssetItem", back_populates="user", cascade="all, delete-orphan")
