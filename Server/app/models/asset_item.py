"""
惜物 API — 资产物品 ORM 模型
"""
import uuid
from datetime import datetime, date, timezone
from decimal import Decimal

from sqlalchemy import (
    String, Integer, Boolean, DateTime, Date,
    Numeric, Text, ForeignKey, UniqueConstraint, Index, text,
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class AssetItem(Base):
    """资产物品表"""
    __tablename__ = "asset_items"
    __table_args__ = (
        UniqueConstraint("user_id", "client_id", name="uq_asset_items_user_client"),
        Index("ix_asset_items_user_updated", "user_id", "updated_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("uuid_generate_v4()"),
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
        comment="所属用户ID",
    )
    client_id: Mapped[int] = mapped_column(
        Integer, nullable=False, comment="客户端本地ID"
    )
    name: Mapped[str] = mapped_column(
        String(100), nullable=False, comment="物品名称"
    )
    emoji_icon: Mapped[str] = mapped_column(
        String(10), nullable=False, default="📦", server_default="📦", comment="Emoji图标"
    )
    category: Mapped[str] = mapped_column(
        String(20), nullable=False, comment="分类"
    )
    buy_price: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, comment="买入价格"
    )
    buy_date: Mapped[date] = mapped_column(
        Date, nullable=False, comment="买入日期"
    )
    current_value: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), nullable=False, comment="当前残值"
    )
    depreciation_model: Mapped[str] = mapped_column(
        String(30), nullable=False, comment="折旧模型"
    )
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="active", server_default="active", comment="状态"
    )
    sell_price: Mapped[Decimal | None] = mapped_column(
        Numeric(12, 2), nullable=True, comment="卖出价格"
    )
    sell_date: Mapped[date | None] = mapped_column(
        Date, nullable=True, comment="卖出日期"
    )
    note: Mapped[str | None] = mapped_column(
        Text, nullable=True, comment="备注"
    )
    expiry_date: Mapped[date | None] = mapped_column(
        Date, nullable=True, comment="到期日期"
    )
    sort_order: Mapped[int] = mapped_column(
        Integer, nullable=False, default=0, server_default=text("0"), comment="排列顺序"
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        server_default=text("NOW()"),
        comment="创建时间",
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
        server_default=text("NOW()"),
        comment="更新时间",
    )
    is_deleted: Mapped[bool] = mapped_column(
        Boolean, default=False, server_default=text("false"), comment="软删除标记"
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True, comment="删除时间"
    )

    # 关联用户
    user = relationship("User", back_populates="assets")
