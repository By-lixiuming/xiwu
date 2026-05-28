"""
惜物 API — 资产 CRUD 路由
"""
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_user
from app.core.exceptions import NotFoundError
from app.models.user import User
from app.schemas.asset import (
    AssetCreateRequest,
    AssetUpdateRequest,
    AssetResponse,
    AssetListResponse,
    ReorderRequest,
)
from app.services import asset_service

router = APIRouter()


@router.get("/", response_model=AssetListResponse)
async def list_assets(
    status: str | None = Query(None, description="按状态筛选"),
    category: str | None = Query(None, description="按分类筛选"),
    sort_by: str = Query("sort_order", description="排序字段"),
    order: str = Query("asc", description="排序方向 asc/desc"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取资产列表"""
    items, total = await asset_service.get_assets(
        db=db,
        user_id=current_user.id,
        status=status,
        category=category,
        sort_by=sort_by,
        order=order,
    )
    return AssetListResponse(
        items=[AssetResponse.from_orm_model(item) for item in items],
        total=total,
    )


@router.post("/", response_model=AssetResponse, status_code=201)
async def create_asset(
    request: AssetCreateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """创建资产"""
    data = request.model_dump(exclude_none=True)
    asset = await asset_service.create_asset(
        db=db,
        user_id=current_user.id,
        data=data,
    )
    return AssetResponse.from_orm_model(asset)


@router.get("/{asset_id}", response_model=AssetResponse)
async def get_asset(
    asset_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """获取单个资产"""
    asset = await asset_service.get_asset(
        db=db,
        asset_id=asset_id,
        user_id=current_user.id,
    )
    if asset is None:
        raise NotFoundError("资产不存在")
    return AssetResponse.from_orm_model(asset)


@router.put("/{asset_id}", response_model=AssetResponse)
async def update_asset(
    asset_id: UUID,
    request: AssetUpdateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """更新资产"""
    data = request.model_dump(exclude_unset=True)
    asset = await asset_service.update_asset(
        db=db,
        asset_id=asset_id,
        user_id=current_user.id,
        data=data,
    )
    return AssetResponse.from_orm_model(asset)


@router.delete("/{asset_id}")
async def delete_asset(
    asset_id: UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """删除资产（软删除）"""
    await asset_service.delete_asset(
        db=db,
        asset_id=asset_id,
        user_id=current_user.id,
    )
    return {"message": "资产已删除", "id": str(asset_id)}


@router.put("/reorder", status_code=200)
async def reorder_assets(
    request: ReorderRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """批量更新资产排序"""
    orders = [{"id": item.id, "sort_order": item.sort_order} for item in request.orders]
    await asset_service.reorder_assets(
        db=db,
        user_id=current_user.id,
        orders=orders,
    )
    return {"message": "排序已更新"}
