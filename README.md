# 惜物 Xiwu 📦

> **万物皆有成本，认清真实消费。珍惜物品，物尽其用。**

「惜物」是一款个人资产折旧管理工具，帮助你追踪消费品的折旧情况，计算物品的 **日均使用成本**，让每一笔消费都清晰可见。

## ✨ 功能特色

- 📱 **资产录入与管理** — 快速添加你的物品，记录买入价格、日期和分类
- 📊 **总资产看板** — 一眼查看总资产残值、总投入本金和总折损
- 📉 **三种折旧模型** — 根据物品类型自动计算残值变化
- 💰 **日均使用成本** — 实时计算每件物品每天花了你多少钱
- 🎯 **物品生命周期** — 支持「服役中」和「已出掉/转卖」两种状态
- 🎨 **手账风设计** — 马卡龙配色 + Emoji 图标 + 趣味文案，让记账不再枯燥

## 🧮 折旧模型说明

| 模型 | 名称 | 计算逻辑 | 适用场景 |
|:---|:---|:---|:---|
| 模型 A | 直线归零法 | 设定预期使用寿命，价值每天平均递减至 0 | 权益、消耗品（年卡、跑鞋等） |
| 模型 B | 落地打折 + 持续贬值 | 购买即扣 20% 价值，之后每年再按 15% 贬值 | 数码产品、汽车等 |
| 模型 C | 保值/缓慢折旧法 | 设定保底残值（50%），前期缓慢折旧至保底后不再下跌 | 奢侈品、贵金属、高端家具 |

**核心公式：**
```
日均使用成本 = (买入价格 - 当前残值) ÷ 已持有天数
```

## 🏗️ 项目架构

项目基于 **Flutter** 构建，采用 **GetX** 状态管理 + **Hive** 本地数据库的技术方案。

### 技术栈

| 类别 | 技术选型 | 版本 |
|:---|:---|:---|
| 跨平台框架 | Flutter | 3.41.8 |
| 编程语言 | Dart | 3.11.5 |
| 状态管理 | GetX | ^4.7.3 |
| 本地数据库 | Hive + Hive Flutter | ^2.2.3 |
| 代码生成 | build_runner + hive_generator | - |
| 国际化 | intl | ^0.20.2 |

### 目录结构

```
lib/
├── main.dart                      # 应用入口，初始化 Hive 和 GetX 依赖注入
├── controllers/
│   └── asset_controller.dart      # 资产控制器：CRUD 操作 + 折旧计算 + 看板汇总
├── models/
│   ├── asset_item.dart            # 数据模型：AssetItem + 枚举（分类/折旧模型/状态）
│   └── asset_item.g.dart          # Hive TypeAdapter（自动生成）
├── services/
│   └── database_service.dart      # 数据库服务：Hive Box 管理 + CRUD 封装
├── theme/
│   └── app_theme.dart             # 主题配置：马卡龙/莫兰迪色系 + Material 3
└── views/
    ├── home_page.dart             # 首页：看板卡片 + 资产列表
    ├── add_asset_page.dart        # 新增资产页：表单录入
    └── asset_detail_page.dart     # 资产详情页：数据展示 + 出掉/删除操作
```

### 架构设计

```
┌──────────────────────────────────────────────┐
│                   Views 层                    │
│  HomePage / AddAssetPage / AssetDetailPage    │
├──────────────────────────────────────────────┤
│               Controllers 层                  │
│     AssetController (GetX 响应式状态管理)       │
├──────────────────────────────────────────────┤
│                Services 层                    │
│      DatabaseService (Hive CRUD 操作)         │
├──────────────────────────────────────────────┤
│                 Models 层                     │
│   AssetItem / AssetCategory / ItemStatus      │
│   DepreciationModel (Hive TypeAdapter)        │
├──────────────────────────────────────────────┤
│               Hive 本地存储                    │
└──────────────────────────────────────────────┘
```

### 数据模型

核心数据模型 `AssetItem` 包含以下字段：

| 字段 | 类型 | 说明 |
|:---|:---|:---|
| `id` | int | 主键，自动递增 |
| `name` | String | 物品名称 |
| `emojiIcon` | String | Emoji 图标 |
| `category` | AssetCategory | 物品分类（数码/交通/家居/服饰/权益） |
| `buyPrice` | double | 买入价格 |
| `buyDate` | DateTime | 买入日期 |
| `currentValue` | double | 当前残值（由折旧模型动态计算） |
| `depreciationModel` | DepreciationModel | 折旧模型（A/B/C 三选一） |
| `status` | ItemStatus | 状态（服役中 / 已出掉） |
| `sellPrice` | double? | 卖出价格（选填） |
| `sellDate` | DateTime? | 卖出日期（选填） |
| `note` | String? | 备注（选填） |

## 🚀 如何运行

### 环境要求

- **Flutter SDK** ≥ 3.41.x（channel stable）
- **Dart SDK** ≥ 3.11.x
- Android Studio / VS Code（推荐安装 Flutter 插件）
- Android 模拟器 或 实体设备 或 Chrome（Web 端）

### 快速开始

1. **克隆仓库**

```bash
git clone git@github.com:By-lixiuming/xiwu.git
cd xiwu
```

2. **安装依赖**

```bash
flutter pub get
```

3. **生成 Hive TypeAdapter 代码**（如果 `asset_item.g.dart` 不存在或需要更新）

```bash
dart run build_runner build --delete-conflicting-outputs
```

4. **运行应用**

```bash
# Android 模拟器或真机
flutter run

# Web 端
flutter run -d chrome

# Linux 桌面端
flutter run -d linux
```

### 热重载（Hot Reload）

Flutter 在所有平台（包括 Linux 桌面端）运行时都支持热重载。执行 `flutter run` 后，应用启动完成会在终端显示可用的快捷键：

| 快捷键 | 功能 | 说明 |
|:---|:---|:---|
| `r` | **热重载 (Hot Reload)** | 保留应用状态，仅重新加载修改的代码，适合 UI 调整 |
| `R` | **热重启 (Hot Restart)** | 重启整个应用（丢失当前状态），适合修改了初始化逻辑时使用 |
| `q` | 退出应用 | 停止运行并退出 |
| `d` | 分离 (Detach) | 终端脱离应用，应用继续在后台运行 |
| `h` | 帮助 | 显示所有可用快捷键 |

**使用方式：** 修改代码并保存后，在运行 `flutter run` 的终端窗口中按 `r` 键即可立即看到效果，无需重新编译。

> 💡 **提示：** 热重载对大多数 UI 和业务逻辑修改即时生效，但以下情况需要使用热重启（`R`）：
> - 修改了 `main()` 函数
> - 修改了全局变量的初始值
> - 新增/修改了枚举类型
> - 修改了泛型类型参数

### 常用命令

```bash
# 检查环境配置
flutter doctor

# 清理构建缓存
flutter clean && flutter pub get

# 运行测试
flutter test

# 构建 APK（发布版）
flutter build apk --release
```

## 📋 物品分类

| 分类 | Emoji | 示例 |
|:---|:---|:---|
| 数码外设 | 📱 | 手机、电脑、相机 |
| 交通出行 | 🚗 | 汽车、自行车、摩托车 |
| 大件家居 | 🛋️ | 冰箱、洗衣机、人体工学椅 |
| 服饰箱包 | 👜 | 名表、奢侈品包 |
| 权益/服务 | 🎫 | 健身卡、视频会员 |

## 🗺️ 路线图

- [x] MVP V1.0 — 资产录入、折旧计算、看板概览
- [ ] AI 估价助手 — 对接大模型 API 一键估价
- [ ] 奶茶换算器 — 日均成本具象化对比
- [ ] 回本里程碑 — 日均成本低于阈值时触发庆祝动画
- [ ] 云端同步 — 多设备数据同步
- [ ] 图表分析 — 饼图/折线图展示资产配置和走势

## 📄 许可证

本项目仅供个人学习使用。
