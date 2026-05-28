"""
惜物 API — 资产业务逻辑
"""
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select, func, asc, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.exceptions import NotFoundError
from app.models.asset_item import AssetItem


async def get_assets(
    db: AsyncSession,
    user_id: UUID,
    status: str | None = None,
    category: str | None = None,
    sort_by: str = "sort_order",
    order: str = "asc",
) -> tuple[list[AssetItem], int]:
    """
    获取用户的资产列表
    :return: (资产列表, 总数)
    """
    # 基础查询条件
    query = select(AssetItem).where(
        AssetItem.user_id == user_id,
        AssetItem.is_deleted == False,  # noqa: E712
    )

    # 可选筛选条件
    if status:
        query = query.where(AssetItem.status == status)
    if category:
        query = query.where(AssetItem.category == category)

    # 计算总数
    count_query = select(func.count()).select_from(query.subquery())
    total_result = await db.execute(count_query)
    total = total_result.scalar() or 0

    # 排序
    sort_column = getattr(AssetItem, sort_by, AssetItem.sort_order)
    order_func = desc if order == "desc" else asc
    query = query.order_by(order_func(sort_column))

    # 执行查询
    result = await db.execute(query)
    items = list(result.scalars().all())

    return items, total


async def get_asset(
    db: AsyncSession,
    asset_id: UUID,
    user_id: UUID,
) -> AssetItem | None:
    """获取单个资产（确保属于该用户）"""
    result = await db.execute(
        select(AssetItem).where(
            AssetItem.id == asset_id,
            AssetItem.user_id == user_id,
            AssetItem.is_deleted == False,  # noqa: E712
        )
    )
    return result.scalar_one_or_none()


async def create_asset(
    db: AsyncSession,
    user_id: UUID,
    data: dict,
) -> AssetItem:
    """创建新资产"""
    asset = AssetItem(user_id=user_id, **data)
    db.add(asset)
    await db.flush()
    return asset


async def update_asset(
    db: AsyncSession,
    asset_id: UUID,
    user_id: UUID,
    data: dict,
) -> AssetItem:
    """
    更新资产
    :raises NotFoundError: 资产不存在或不属于该用户
    """
    asset = await get_asset(db, asset_id, user_id)
    if asset is None:
        raise NotFoundError("资产不存在")

    # 更新非空字段
    for key, value in data.items():
        if value is not None and hasattr(asset, key):
            setattr(asset, key, value)

    asset.updated_at = datetime.now(timezone.utc)
    await db.flush()
    return asset


async def delete_asset(
    db: AsyncSession,
    asset_id: UUID,
    user_id: UUID,
) -> None:
    """
    软删除资产
    :raises NotFoundError: 资产不存在
    """
    asset = await get_asset(db, asset_id, user_id)
    if asset is None:
        raise NotFoundError("资产不存在")

    asset.is_deleted = True
    asset.deleted_at = datetime.now(timezone.utc)
    asset.updated_at = datetime.now(timezone.utc)
    await db.flush()


async def reorder_assets(
    db: AsyncSession,
    user_id: UUID,
    orders: list[dict],
) -> None:
    """批量更新资产排序"""
    for item in orders:
        asset_id = UUID(item["id"])
        result = await db.execute(
            select(AssetItem).where(
                AssetItem.id == asset_id,
                AssetItem.user_id == user_id,
            )
        )
        asset = result.scalar_one_or_none()
        if asset:
            asset.sort_order = item["sort_order"]
            asset.updated_at = datetime.now(timezone.utc)
    await db.flush()
