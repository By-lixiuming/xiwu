"""
惜物 API — 应用配置管理
使用 pydantic-settings 从 .env 文件读取配置
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """应用配置，自动从 .env 文件加载"""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # 应用基础配置
    app_name: str = "惜物API"
    app_version: str = "2.0.0"
    debug: bool = False
    secret_key: str = "change-me"

    # JWT 配置
    jwt_secret_key: str = "change-me"
    jwt_access_token_expire_minutes: int = 120
    jwt_refresh_token_expire_days: int = 30

    # 数据库配置
    db_user: str = "postgres"
    db_password: str = ""
    db_host: str = "localhost"
    db_port: int = 5432
    db_name: str = "xiwu"

    # Redis 配置
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0

    # CORS 配置
    cors_origins: str = "*"

    @property
    def database_url(self) -> str:
        """异步数据库连接 URL（asyncpg 驱动）"""
        return (
            f"postgresql+asyncpg://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def sync_database_url(self) -> str:
        """同步数据库连接 URL（Alembic 迁移使用，psycopg2 驱动）"""
        return (
            f"postgresql+psycopg2://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
        )

    @property
    def cors_origins_list(self) -> list[str]:
        """解析 CORS 允许的来源列表"""
        if self.cors_origins == "*":
            return ["*"]
        return [origin.strip() for origin in self.cors_origins.split(",")]


# 全局单例
settings = Settings()
