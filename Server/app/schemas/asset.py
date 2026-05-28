"""
惜物 API — 资产相关请求/响应模型
"""
from datetime import date, datetime
from decimal import Decimal
from pydantic import BaseModel, ConfigDict


class AssetCreateRequest(BaseModel):
    """创建资产请求"""
    client_id: int
    name: str
    emoji_icon: str = "📦"
    category: str
    buy_price: float
    buy_date: date
    current_value: float
    depreciation_model: str
    status: str = "active"
    sell_price: float | None = None
    sell_date: date | None = None
    note: str | None = None
    expiry_date: date | None = None
    sort_order: int = 0


class AssetUpdateRequest(BaseModel):
    """更新资产请求（所有字段可选）"""
    name: str | None = None
    emoji_icon: str | None = None
    category: str | None = None
    buy_price: float | None = None
    buy_date: date | None = None
    current_value: float | None = None
    depreciation_model: str | None = None
    status: str | None = None
    sell_price: float | None = None
    sell_date: date | None = None
    note: str | None = None
    expiry_date: date | None = None
    sort_order: int | None = None


class AssetResponse(BaseModel):
    """资产响应"""
    id: str
    client_id: int
    name: str
    emoji_icon: str
    category: str
    buy_price: float
    buy_date: date
    current_value: float
    depreciation_model: str
    status: str
    sell_price: float | None = None
    sell_date: date | None = None
    note: str | None = None
    expiry_date: date | None = None
    sort_order: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @classmethod
    def from_orm_model(cls, item) -> "AssetResponse":
        """从 ORM 模型转换，处理 UUID 和 Decimal 类型"""
        return cls(
            id=str(item.id),
            client_id=item.client_id,
            name=item.name,
            emoji_icon=item.emoji_icon,
            category=item.category,
            buy_price=float(item.buy_price),
            buy_date=item.buy_date,
            current_value=float(item.current_value),
            depreciation_model=item.depreciation_model,
            status=item.status,
            sell_price=float(item.sell_price) if item.sell_price is not None else None,
            sell_date=item.sell_date,
            note=item.note,
            expiry_date=item.expiry_date,
            sort_order=item.sort_order,
            created_at=item.created_at,
            updated_at=item.updated_at,
        )


class AssetListResponse(BaseModel):
    """资产列表响应"""
    items: list[AssetResponse]
    total: int


class ReorderItem(BaseModel):
    """排序项"""
    id: str
    sort_order: int


class ReorderRequest(BaseModel):
    """批量排序请求"""
    orders: list[ReorderItem]
