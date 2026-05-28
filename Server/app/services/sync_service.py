"""
惜物 API — 数据同步业务逻辑
基于时间戳的增量同步，冲突策略：Last Write Wins (LWW)
"""
from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.asset_item import AssetItem
from app.schemas.asset import AssetResponse


async def push_changes(
    db: AsyncSession,
    user_id: UUID,
    changes: list,
    last_sync_at: datetime | None = None,
) -> dict:
    """
    处理客户端推送的变更
    :return: {synced, id_mappings, conflicts, server_time}
    """
    synced = 0
    id_mappings = []
    conflicts = []
    now = datetime.now(timezone.utc)

    for change in changes:
        action = change.action
        client_id = change.client_id
        data = change.data or {}
        client_updated_at = change.client_updated_at

        try:
            if action == "create":
                # 创建新资产
                asset = AssetItem(
                    user_id=user_id,
                    client_id=client_id,
                    name=data.get("name", ""),
                    emoji_icon=data.get("emoji_icon", "📦"),
                    category=data.get("category", "other"),
                    buy_price=data.get("buy_price", 0),
                    buy_date=data.get("buy_date"),
                    current_value=data.get("current_value", 0),
                    depreciation_model=data.get("depreciation_model", "model_a_linear"),
                    status=data.get("status", "active"),
                    sell_price=data.get("sell_price"),
                    sell_date=data.get("sell_date"),
                    note=data.get("note"),
                    expiry_date=data.get("expiry_date"),
                    sort_order=data.get("sort_order", 0),
                    created_at=now,
                    updated_at=now,
                )
                db.add(asset)
                await db.flush()
                id_mappings.append({
                    "client_id": client_id,
                    "server_id": str(asset.id),
                })
                synced += 1

            elif action == "update":
                # 查找资产：优先用 server_id，否则用 (user_id, client_id)
                asset = None
                if change.server_id:
                    result = await db.execute(
                        select(AssetItem).where(
                            AssetItem.id == UUID(change.server_id),
                            AssetItem.user_id == user_id,
                        )
                    )
                    asset = result.scalar_one_or_none()

                if asset is None:
                    result = await db.execute(
                        select(AssetItem).where(
                            AssetItem.user_id == user_id,
                            AssetItem.client_id == client_id,
                        )
                    )
                    asset = result.scalar_one_or_none()

                if asset is None:
                    conflicts.append({
                        "client_id": client_id,
                        "reason": "资产不存在",
                    })
                    continue

                # LWW 冲突检测：客户端时间更新则覆盖
                if asset.updated_at and client_updated_at.replace(tzinfo=timezone.utc) <= asset.updated_at.replace(tzinfo=timezone.utc):
                    conflicts.append({
                        "client_id": client_id,
                        "reason": "服务端数据更新，已被覆盖",
                    })
                    continue

                # 更新字段
                for key, value in data.items():
                    if hasattr(asset, key) and key not in ("id", "user_id", "created_at"):
                        setattr(asset, key, value)
                asset.updated_at = now
                await db.flush()
                synced += 1

            elif action == "delete":
                # 软删除
                asset = None
                if change.server_id:
                    result = await db.execute(
                        select(AssetItem).where(
                            AssetItem.id == UUID(change.server_id),
                            AssetItem.user_id == user_id,
                        )
                    )
                    asset = result.scalar_one_or_none()

                if asset is None:
                    result = await db.execute(
                        select(AssetItem).where(
                            AssetItem.user_id == user_id,
                            AssetItem.client_id == client_id,
                        )
                    )
                    asset = result.scalar_one_or_none()

                if asset:
                    asset.is_deleted = True
                    asset.deleted_at = now
                    asset.updated_at = now
                    await db.flush()
                    synced += 1

        except Exception as e:
            conflicts.append({
                "client_id": client_id,
                "reason": str(e),
            })

    return {
        "synced": synced,
        "id_mappings": id_mappings,
        "conflicts": conflicts,
        "server_time": now,
    }


async def pull_changes(
    db: AsyncSession,
    user_id: UUID,
    since: datetime,
) -> dict:
    """
    拉取自上次同步以来的服务端变更
    包括已软删除的记录（客户端需要知道哪些被删除了）
    """
    now = datetime.now(timezone.utc)

    # 查询所有 updated_at > since 的记录（包括已删除的）
    result = await db.execute(
        select(AssetItem).where(
            AssetItem.user_id == user_id,
            AssetItem.updated_at > since,
        ).order_by(AssetItem.updated_at.asc())
    )
    items = result.scalars().all()

    changes = []
    for item in items:
        if item.is_deleted:
            changes.append({
                "action": "delete",
                "server_id": str(item.id),
                "client_id": item.client_id,
                "data": None,
                "updated_at": None,
                "deleted_at": item.deleted_at.isoformat() if item.deleted_at else None,
            })
        else:
            asset_data = AssetResponse.from_orm_model(item)
            changes.append({
                "action": "update",  # 对客户端来说，create 和 update 统一处理
                "server_id": str(item.id),
                "client_id": item.client_id,
                "data": asset_data.model_dump(mode="json"),
                "updated_at": item.updated_at.isoformat() if item.updated_at else None,
                "deleted_at": None,
            })

    return {
        "changes": changes,
        "server_time": now,
        "has_more": False,
    }


async def full_sync(
    db: AsyncSession,
    user_id: UUID,
) -> dict:
    """全量拉取用户所有未删除的资产"""
    now = datetime.now(timezone.utc)

    result = await db.execute(
        select(AssetItem).where(
            AssetItem.user_id == user_id,
            AssetItem.is_deleted == False,  # noqa: E712
        ).order_by(AssetItem.sort_order.asc())
    )
    items = result.scalars().all()

    return {
        "items": [AssetResponse.from_orm_model(item) for item in items],
        "total": len(items),
        "server_time": now,
    }
