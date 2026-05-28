"""
惜物 API — 数据同步路由
"""
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.models.user import User
from app.schemas.sync import (
    SyncPushRequest,
    SyncPushResponse,
    SyncPullResponse,
    SyncFullResponse,
    IdMapping,
)
from app.schemas.asset import AssetResponse
from app.services import sync_service

router = APIRouter()


@router.post("/push", response_model=SyncPushResponse)
async def push_changes(
    request: SyncPushRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """客户端推送变更到服务端"""
    result = await sync_service.push_changes(
        db=db,
        user_id=current_user.id,
        changes=request.changes,
        last_sync_at=request.last_sync_at,
    )
    return SyncPushResponse(
        synced=result["synced"],
        id_mappings=[IdMapping(**m) for m in result["id_mappings"]],
        conflicts=result["conflicts"],
        server_time=result["server_time"],
    )


@router.get("/pull", response_model=SyncPullResponse)
async def pull_changes(
    since: datetime = Query(..., description="上次同步时间戳 (ISO 8601)"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """拉取服务端变更"""
    result = await sync_service.pull_changes(
        db=db,
        user_id=current_user.id,
        since=since,
    )
    return SyncPullResponse(**result)


@router.get("/full", response_model=SyncFullResponse)
async def full_sync(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """全量拉取所有资产数据（首次同步）"""
    result = await sync_service.full_sync(
        db=db,
        user_id=current_user.id,
    )
    return SyncFullResponse(**result)
