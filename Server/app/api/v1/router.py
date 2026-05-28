"""
惜物 API — V1 路由汇总
"""
from fastapi import APIRouter

from app.api.v1.auth import router as auth_router
from app.api.v1.users import router as user_router
from app.api.v1.assets import router as asset_router
from app.api.v1.sync import router as sync_router

api_router = APIRouter()

api_router.include_router(auth_router, prefix="/auth", tags=["认证"])
api_router.include_router(user_router, prefix="/users", tags=["用户"])
api_router.include_router(asset_router, prefix="/assets", tags=["资产"])
api_router.include_router(sync_router, prefix="/sync", tags=["同步"])
