#!/bin/bash
#
# 惜物(Xiwu) 一键发布脚本
# 功能：自动递增版本号 → 构建 APK → 重命名 → Git 提交/标签 → 推送到 GitHub Release
#
# 用法：
#   ./scripts/release.sh           # 正常发布（需手动确认）
#   ./scripts/release.sh --yes     # 跳过确认直接发布
#   ./scripts/release.sh --dry-run # 干跑测试（不实际构建和发布）
#

set -e

# ============================================================
# 配置
# ============================================================
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE="$PROJECT_DIR/version.txt"
PUBSPEC_FILE="$PROJECT_DIR/pubspec.yaml"
OUTPUT_DIR="$PROJECT_DIR/output"
APK_SOURCE="$PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
APP_NAME="xiwu"
DRY_RUN=false
AUTO_YES=false

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================
# 参数解析
# ============================================================
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            echo -e "${YELLOW}🔍 干跑模式 - 不执行实际构建和发布${NC}"
            ;;
        --yes|-y)
            AUTO_YES=true
            ;;
        --help|-h)
            echo "用法: ./scripts/release.sh [选项]"
            echo ""
            echo "选项:"
            echo "  --dry-run    干跑模式，只显示将要执行的操作"
            echo "  --yes, -y    跳过所有确认提示，直接执行"
            echo "  --help, -h   显示帮助信息"
            exit 0
            ;;
    esac
done

# ============================================================
# 前置检查
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  🚀 惜物(Xiwu) 自动发布工具${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查 version.txt 是否存在
if [ ! -f "$VERSION_FILE" ]; then
    echo -e "${RED}❌ 错误：version.txt 不存在！${NC}"
    echo "请在项目根目录创建 version.txt，内容为初始版本号，例如：1.0.0"
    exit 1
fi

# 检查 gh CLI 是否安装（非 dry-run 时）
if [ "$DRY_RUN" = false ]; then
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}❌ 错误：GitHub CLI (gh) 未安装！${NC}"
        echo "请先安装 gh CLI："
        echo "  Ubuntu/Debian: sudo apt install gh"
        echo "  其他系统: https://cli.github.com/"
        echo ""
        echo "安装后运行 'gh auth login' 进行认证"
        exit 1
    fi

    # 检查 gh 是否已认证
    if ! gh auth status &> /dev/null; then
        echo -e "${RED}❌ 错误：GitHub CLI 未认证！${NC}"
        echo "请运行 'gh auth login' 进行认证"
        exit 1
    fi
fi

# 检查工作区是否干净
if [ "$DRY_RUN" = false ]; then
    if [ -n "$(git -C "$PROJECT_DIR" status --porcelain)" ]; then
        echo -e "${YELLOW}⚠️  警告：工作区有未提交的更改${NC}"
        echo ""
        git -C "$PROJECT_DIR" status --short
        echo ""
        if [ "$AUTO_YES" = false ]; then
            read -p "是否继续发布？(y/N) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "已取消发布"
                exit 0
            fi
        else
            echo -e "${YELLOW}  --yes 模式，自动继续${NC}"
        fi
    fi
fi

# ============================================================
# 版本号处理
# ============================================================
CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
echo -e "${GREEN}📋 当前版本号：V${CURRENT_VERSION}${NC}"

# 解析三级版本号
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# 验证版本号格式
if [[ -z "$MAJOR" || -z "$MINOR" || -z "$PATCH" ]]; then
    echo -e "${RED}❌ 错误：版本号格式无效！期望格式：X.Y.Z${NC}"
    exit 1
fi

# 递增最小版本号
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}"

echo -e "${GREEN}📋 新版本号：  V${NEW_VERSION}${NC}"
echo ""

# 计算 Flutter 版本号
# version: MAJOR.MINOR.PATCH+versionCode
# versionCode 需要是递增整数，使用公式确保唯一性
VERSION_CODE=$((MAJOR * 10000 + MINOR * 100 + NEW_PATCH))
FLUTTER_VERSION="${MAJOR}.${MINOR}.${NEW_PATCH}+${VERSION_CODE}"

echo -e "${BLUE}📦 Flutter 版本：${FLUTTER_VERSION}${NC}"
echo -e "${BLUE}📦 Android versionCode：${VERSION_CODE}${NC}"
echo ""

# APK 文件名
APK_FILENAME="${APP_NAME}_v${MAJOR}_${MINOR}_${NEW_PATCH}_release.apk"
echo -e "${BLUE}📄 APK 文件名：${APK_FILENAME}${NC}"
echo ""

# Git Tag
GIT_TAG="v${NEW_VERSION}"
echo -e "${BLUE}🏷️  Git 标签：${GIT_TAG}${NC}"
echo ""

# ============================================================
# 干跑模式到此结束
# ============================================================
if [ "$DRY_RUN" = true ]; then
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔍 干跑模式完成，以上为将要执行的操作预览${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 0
fi

# ============================================================
# 确认发布
# ============================================================
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ "$AUTO_YES" = false ]; then
    read -p "确认发布 V${NEW_VERSION}？(y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "已取消发布"
        exit 0
    fi
else
    echo -e "${GREEN}✅ 自动确认发布 V${NEW_VERSION}${NC}"
fi
echo ""

# ============================================================
# 步骤 1：更新 pubspec.yaml 中的版本号
# ============================================================
echo -e "${CYAN}[1/7] 📝 更新 pubspec.yaml 版本号...${NC}"
sed -i "s/^version: .*/version: ${FLUTTER_VERSION}/" "$PUBSPEC_FILE"
echo "  version: ${FLUTTER_VERSION}"
echo ""

# ============================================================
# 步骤 2：构建 APK
# ============================================================
echo -e "${CYAN}[2/7] 🔨 构建 Release APK...${NC}"
cd "$PROJECT_DIR"
flutter build apk --release
echo ""

# ============================================================
# 步骤 3：重命名并复制 APK
# ============================================================
echo -e "${CYAN}[3/7] 📦 重命名并复制 APK...${NC}"

if [ ! -f "$APK_SOURCE" ]; then
    echo -e "${RED}❌ 错误：APK 文件不存在：${APK_SOURCE}${NC}"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"
cp "$APK_SOURCE" "$OUTPUT_DIR/$APK_FILENAME"
echo "  → $OUTPUT_DIR/$APK_FILENAME"

# 显示文件大小
APK_SIZE=$(du -h "$OUTPUT_DIR/$APK_FILENAME" | cut -f1)
echo "  📏 文件大小：${APK_SIZE}"
echo ""

# ============================================================
# 步骤 4：更新 version.txt
# ============================================================
echo -e "${CYAN}[4/7] 📝 更新 version.txt...${NC}"
echo "$NEW_VERSION" > "$VERSION_FILE"
echo "  ${CURRENT_VERSION} → ${NEW_VERSION}"
echo ""

# ============================================================
# 步骤 5：Git 提交并打标签
# ============================================================
echo -e "${CYAN}[5/7] 📌 Git 提交并打标签...${NC}"
cd "$PROJECT_DIR"
git add pubspec.yaml version.txt
git commit -m "发布版本 V${NEW_VERSION}"
git tag -a "$GIT_TAG" -m "发布版本 V${NEW_VERSION}"
echo "  ✅ 已创建 Git 标签：${GIT_TAG}"
echo ""

# ============================================================
# 步骤 6：推送到远程仓库
# ============================================================
echo -e "${CYAN}[6/7] 🚀 推送到远程仓库...${NC}"
git push origin HEAD
git push origin "$GIT_TAG"
echo "  ✅ 已推送代码和标签"
echo ""

# ============================================================
# 步骤 7：创建 GitHub Release
# ============================================================
echo -e "${CYAN}[7/7] 🎉 创建 GitHub Release...${NC}"

# 获取上一个标签（用于生成发布说明）
PREV_TAG=$(git tag --sort=-version:refname | sed -n '2p')

# 生成发布说明
RELEASE_NOTES="## 惜物 V${NEW_VERSION} 发布说明\n\n"
RELEASE_NOTES+="📅 发布时间：$(date '+%Y-%m-%d %H:%M:%S')\n\n"

if [ -n "$PREV_TAG" ]; then
    RELEASE_NOTES+="### 更新内容\n\n"
    # 获取两个标签之间的 commit 信息
    COMMITS=$(git log "${PREV_TAG}..${GIT_TAG}" --pretty=format:"- %s" --no-merges)
    RELEASE_NOTES+="${COMMITS}\n\n"
else
    RELEASE_NOTES+="### 更新内容\n\n"
    # 没有上一个标签，获取最近 10 条 commit
    COMMITS=$(git log --pretty=format:"- %s" --no-merges -10)
    RELEASE_NOTES+="${COMMITS}\n\n"
fi

RELEASE_NOTES+="### 安装说明\n\n"
RELEASE_NOTES+="1. 下载 \`${APK_FILENAME}\` 文件\n"
RELEASE_NOTES+="2. 在 Android 设备上打开并安装\n"
RELEASE_NOTES+="3. 如需允许安装未知来源应用，请在设置中开启\n"

# 创建 Release 并上传 APK
echo -e "$RELEASE_NOTES" | gh release create "$GIT_TAG" \
    "$OUTPUT_DIR/$APK_FILENAME" \
    --title "惜物 V${NEW_VERSION}" \
    --notes-file - \
    --latest

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ 发布完成！${NC}"
echo -e "${GREEN}  📦 版本：V${NEW_VERSION}${NC}"
echo -e "${GREEN}  📄 APK：${OUTPUT_DIR}/${APK_FILENAME}${NC}"
echo -e "${GREEN}  🏷️  标签：${GIT_TAG}${NC}"
echo -e "${GREEN}  🔗 GitHub Release 已创建${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
