"""
惜物 API — FastAPI 应用入口
"""
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.database import init_db
from app.core.exceptions import XiwuException
from app.api.v1.router import api_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期管理"""
    # 启动时：初始化数据库表（开发模式）
    if settings.debug:
        await init_db()
        print("✅ 数据库表已初始化（开发模式）")
    print(f"🚀 {settings.app_name} v{settings.app_version} 启动成功")
    yield
    # 关闭时：清理资源
    print("👋 应用已关闭")


# 创建 FastAPI 应用
app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="惜物 — 个人资产折旧管理工具 API",
    lifespan=lifespan,
)

# CORS 中间件
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# 全局异常处理
@app.exception_handler(XiwuException)
async def xiwu_exception_handler(request: Request, exc: XiwuException):
    """统一处理自定义业务异常"""
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.message},
    )


# 注册 API 路由
app.include_router(api_router, prefix="/api/v1")


# 根路径
@app.get("/")
async def root():
    """应用根路径"""
    return {
        "message": "惜物 API V2.0",
        "version": settings.app_version,
        "docs": "/docs",
    }


# 健康检查
@app.get("/health")
async def health_check():
    """健康检查接口"""
    return {"status": "healthy", "version": settings.app_version}
