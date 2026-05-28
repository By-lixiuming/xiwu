"""
惜物 API — 同步相关请求/响应模型
"""
from datetime import datetime
from pydantic import BaseModel

from app.schemas.asset import AssetResponse


class SyncChange(BaseModel):
    """同步变更项"""
    action: str  # create / update / delete
    client_id: int
    server_id: str | None = None
    data: dict | None = None
    client_updated_at: datetime


class SyncPushRequest(BaseModel):
    """同步推送请求"""
    changes: list[SyncChange]
    last_sync_at: datetime | None = None


class IdMapping(BaseModel):
    """客户端ID ↔ 服务端ID 映射"""
    client_id: int
    server_id: str


class SyncPushResponse(BaseModel):
    """同步推送响应"""
    synced: int
    id_mappings: list[IdMapping]
    conflicts: list = []
    server_time: datetime


class SyncPullChange(BaseModel):
    """服务端变更项"""
    action: str  # create / update / delete
    server_id: str
    client_id: int
    data: dict | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class SyncPullResponse(BaseModel):
    """同步拉取响应"""
    changes: list[SyncPullChange]
    server_time: datetime
    has_more: bool = False


class SyncFullResponse(BaseModel):
    """全量同步响应"""
    items: list[AssetResponse]
    total: int
    server_time: datetime
