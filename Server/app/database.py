"""
惜物 API — 数据库连接与 Session 管理
使用 SQLAlchemy 2.0 异步引擎
"""
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.config import settings

# 创建异步引擎
engine = create_async_engine(
    settings.database_url,
    echo=settings.debug,  # 调试模式下打印 SQL
    pool_size=20,
    max_overflow=10,
    pool_pre_ping=True,
)

# 创建异步 Session 工厂
async_session_factory = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


class Base(DeclarativeBase):
    """ORM 模型基类"""
    pass


async def get_db():
    """
    数据库 Session 依赖注入生成器
    使用方式: db: AsyncSession = Depends(get_db)
    """
    async with async_session_factory() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


async def init_db():
    """开发环境下直接创建所有表（生产环境使用 Alembic 迁移）"""
    async with engine.begin() as conn:
        # 导入所有模型以确保它们被注册
        from app.models import User, AssetItem  # noqa: F401
        await conn.run_sync(Base.metadata.create_all)
