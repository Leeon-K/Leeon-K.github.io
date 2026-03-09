#!/bin/bash

set -euo pipefail

# 论文报告推送到 GitHub Pages 的脚本
# 用法: ./push_paper_report.sh <论文目录日期> <论文标题> [额外标签...]
# 示例: ./push_paper_report.sh 20260307_SoT "Reasoning Models Generate Societies of Thought"
#
# 注意: 只有 _config.yml 中 display_tags 定义的标签才能正确显示在标签页面上
# 当前支持的标签: Papers, Multi-Agent, Infra, Algorithm

PAPER_DIR_NAME=$1
PAPER_TITLE=$2
shift 2
EXTRA_TAGS="$@"  # 额外的标签

if [ -z "$PAPER_DIR_NAME" ] || [ -z "$PAPER_TITLE" ]; then
    echo "用法: ./push_paper_report.sh <论文目录> <论文标题> [额外标签...]"
    echo ""
    echo "示例:"
    echo "  ./push_paper_report.sh 20260307_SoT 'Reasoning Models Generate Societies of Thought'"
    echo "  ./push_paper_report.sh 20260307_SoT 'Reasoning Models Generate Societies of Thought' Multi-Agent"
    echo ""
    echo "⚠️  注意: 只有以下标签可以正确显示在标签页面:"
    echo "   Papers, Multi-Agent, Infra, Algorithm"
    echo "   使用其他标签将无法点击进入标签页面"
    exit 1
fi

PAPERS_SOURCE_DIR="$HOME/.openclaw/workspace/papers/${PAPER_DIR_NAME}"
GITHUB_SITE_DIR="/Users/lichangkang/Desktop/coding/Leeon-K.github.io"

# 支持的标签列表（必须与 _config.yml 中的 display_tags 一致）
SUPPORTED_TAGS=("Papers" "Multi-Agent" "Infra" "Algorithm")

extract_local_image_refs() {
    python3 - "$1" <<'PY'
import re
import sys
from pathlib import PurePosixPath

html_path = sys.argv[1]
html = open(html_path, encoding="utf-8").read()
seen = set()

for src in re.findall(r'<img[^>]+src="([^"]+)"', html, flags=re.IGNORECASE):
    clean = src.split('?', 1)[0].split('#', 1)[0].strip()
    if not clean:
        continue
    if clean.startswith(('http://', 'https://', '//', 'data:')):
        continue
    suffix = PurePosixPath(clean).suffix.lower()
    if suffix not in {'.png', '.jpg', '.jpeg', '.gif', '.svg', '.webp'}:
        continue
    if src not in seen:
        seen.add(src)
        print(src)
PY
}

resolve_image_source() {
    local img_ref="$1"
    local clean_ref rel_path candidate found_file
    clean_ref="${img_ref%%\?*}"
    clean_ref="${clean_ref%%\#*}"
    rel_path="${clean_ref#/}"

    if [[ "$rel_path" == "${PAPER_DIR_NAME}/"* ]]; then
        rel_path="${rel_path#${PAPER_DIR_NAME}/}"
    fi

    candidate="$PAPERS_SOURCE_DIR/$rel_path"
    if [ -f "$candidate" ]; then
        printf '%s\n' "$candidate"
        return 0
    fi

    if [[ "$rel_path" != source/* ]]; then
        candidate="$PAPERS_SOURCE_DIR/source/$rel_path"
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    fi

    found_file=$(find "$PAPERS_SOURCE_DIR" -type f -name "$(basename "$clean_ref")" 2>/dev/null | head -1 || true)
    if [ -n "$found_file" ]; then
        printf '%s\n' "$found_file"
        return 0
    fi

    return 1
}

destination_rel_path() {
    local source_file="$1"
    local rel_path

    rel_path="${source_file#"$PAPERS_SOURCE_DIR"/}"
    rel_path="${rel_path#/}"
    if [[ "$rel_path" == source/* ]]; then
        rel_path="${rel_path#source/}"
    fi

    printf 'images/%s\n' "$rel_path"
}

if [ ! -d "$PAPERS_SOURCE_DIR" ]; then
    echo "错误: 论文目录不存在: $PAPERS_SOURCE_DIR"
    exit 1
fi

if [ ! -f "$PAPERS_SOURCE_DIR/report.html" ]; then
    echo "错误: report.html 不存在，请先运行渲染"
    exit 1
fi

cd "$GITHUB_SITE_DIR"

# 同步最新
git pull origin master

# 从日期生成目录名
DATE=$(echo "$PAPER_DIR_NAME" | cut -d'_' -f1)
DATE_FORMATTED="${DATE:0:4}-${DATE:4:2}-${DATE:6:2}"

# 生成 slug
SLUG=$(echo "$PAPER_TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g' | sed 's/-$//')
BLOG_DIR="assets/blog/${DATE_FORMATTED}_${SLUG}"

# 创建目录
mkdir -p "$BLOG_DIR/images"

echo "📄 复制 HTML 文件..."
cp "$PAPERS_SOURCE_DIR/report.html" "$BLOG_DIR/index.html"

echo "📷 复制并修复 HTML 中实际引用的图片..."
IMAGE_REFS=$(extract_local_image_refs "$PAPERS_SOURCE_DIR/report.html")
COPIED_COUNT=0
MISSING_IMAGES=0

if [ -z "$IMAGE_REFS" ]; then
    echo "  ⚠️  HTML 中没有本地图片引用"
else
    while IFS= read -r img_ref; do
        [ -n "$img_ref" ] || continue

        if ! source_file=$(resolve_image_source "$img_ref"); then
            echo "  ✗ 未找到源图片: $img_ref"
            MISSING_IMAGES=$((MISSING_IMAGES + 1))
            continue
        fi

        dest_rel=$(destination_rel_path "$source_file")
        dest_path="$BLOG_DIR/$dest_rel"
        mkdir -p "$(dirname "$dest_path")"
        cp "$source_file" "$dest_path"
        COPIED_COUNT=$((COPIED_COUNT + 1))

        python3 - "$BLOG_DIR/index.html" "$img_ref" "$dest_rel" <<'PY'
import sys

html_path, original, replacement = sys.argv[1:4]
with open(html_path, encoding="utf-8") as f:
    html = f.read()
html = html.replace(f'src="{original}"', f'src="{replacement}"')
with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)
PY
        echo "  ✓ $img_ref -> $dest_rel"
    done <<< "$IMAGE_REFS"
fi

if [ "$MISSING_IMAGES" -gt 0 ]; then
    echo "错误: 有 $MISSING_IMAGES 张图片未找到，已停止提交"
    exit 1
fi

echo "  ✓ 已处理 $COPIED_COUNT 张图片"

echo "🔎 校验最终 HTML 图片路径..."
VALIDATION_ERRORS=0
FINAL_REFS=$(extract_local_image_refs "$BLOG_DIR/index.html")

if [ -n "$FINAL_REFS" ]; then
    while IFS= read -r img_ref; do
        [ -n "$img_ref" ] || continue

        if [[ "$img_ref" == /${PAPER_DIR_NAME}/* ]] || [[ "$img_ref" == "${PAPER_DIR_NAME}/"* ]] || [[ "$img_ref" == source/* ]]; then
            echo "  ✗ 仍存在未改写路径: $img_ref"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
            continue
        fi

        if [ ! -f "$BLOG_DIR/${img_ref%%\?*}" ]; then
            echo "  ✗ HTML 引用的图片不存在: $img_ref"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    done <<< "$FINAL_REFS"
fi

if [ "$VALIDATION_ERRORS" -gt 0 ]; then
    echo "错误: 图片校验失败，共 $VALIDATION_ERRORS 项"
    exit 1
fi

echo "  ✓ 图片路径和文件校验通过"

# 验证并过滤标签
echo "🏷️ 处理标签..."

# 默认标签
TAGS=("Papers")

# 检查额外标签是否在支持列表中
for tag in $EXTRA_TAGS; do
    SUPPORTED=false
    for supported in "${SUPPORTED_TAGS[@]}"; do
        if [ "$tag" = "$supported" ]; then
            SUPPORTED=true
            break
        fi
    done
    if [ "$SUPPORTED" = true ]; then
        TAGS+=("$tag")
        echo "  ✓ $tag (支持)"
    else
        echo "  ✗ $tag (不支持，已忽略 - 不在 display_tags 中)"
    fi
done

# 构建标签字符串
TAGS_STR="["
first=true
for tag in "${TAGS[@]}"; do
    if [ "$first" = true ]; then
        first=false
    else
        TAGS_STR+=", "
    fi
    TAGS_STR+="\"$tag\""
done
TAGS_STR+="]"

echo "  最终标签: ${TAGS_STR}"

# 更新 blogs.yml
echo "📝 更新 blogs.yml..."

if grep -q "${DATE_FORMATTED}_${SLUG}" "_data/blogs.yml"; then
    echo "博客已存在，跳过添加"
else
    DESCRIPTION="论文报告: ${PAPER_TITLE}"
    
    cat >> "_data/blogs.yml" << EOF

- title: "$PAPER_TITLE"
  file: "/assets/blog/${DATE_FORMATTED}_${SLUG}/"
  date: $DATE_FORMATTED
  description: "$DESCRIPTION"
  tags: ${TAGS_STR}
EOF
    echo "✓ 已添加到博客列表"
fi

# 提交并推送
echo "🚀 提交并推送..."
git add -A
git commit -m "feat: 添加论文报告 - ${PAPER_TITLE}" || echo "没有需要提交的内容"
git push

echo ""
echo "✅ 完成！"
echo "访问地址: https://leeon-k.github.io/assets/blog/${DATE_FORMATTED}_${SLUG}/"
