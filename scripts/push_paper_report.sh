#!/bin/bash

# 论文报告推送到 GitHub Pages 的脚本
# 用法: ./push_paper_report.sh <论文目录日期> <论文标题>
# 示例: ./push_paper_report.sh 20260307_SoT "Reasoning Models Generate Societies of Thought"

PAPER_DIR_NAME=$1
PAPER_TITLE=$2

if [ -z "$PAPER_DIR_NAME" ] || [ -z "$PAPER_TITLE" ]; then
    echo "用法: ./push_paper_report.sh <论文目录日期> <论文标题>"
    echo "示例: ./push_paper_report.sh 20260307_SoT 'Reasoning Models Generate Societies of Thought'"
    exit 1
fi

PAPERS_SOURCE_DIR="$HOME/.openclaw/workspace/papers/${PAPER_DIR_NAME}"
GITHUB_SITE_DIR="/Users/lichangkang/Desktop/coding/Leeon-K.github.io"

if [ ! -d "$PAPERS_SOURCE_DIR" ]; then
    echo "错误: 论文目录不存在: $PAPERS_SOURCE_DIR"
    exit 1
fi

# 检查 HTML 文件
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

# 复制图片
if [ -d "$PAPERS_SOURCE_DIR/source/figures" ]; then
    echo "📷 复制图片..."
    cp "$PAPERS_SOURCE_DIR/source/figures"/*.png "$BLOG_DIR/images/" 2>/dev/null || true
fi

# 修复 HTML 中的图片路径（处理各种可能的路径格式）
echo "🔧 修复图片路径..."

# 获取所有可能的路径模式
PAPER_PATHS=(
    "/${PAPER_DIR_NAME}/images/"
    "/${PAPER_DIR_NAME}/source/figures/"
    "source/figures/"
    "figures/"
    "/${PAPER_DIR_NAME}/"
)

for img in "$BLOG_DIR/images"/*.png; do
    if [ -f "$img" ]; then
        filename=$(basename "$img")
        # 替换各种可能的路径格式 → images/
        for pattern in "${PAPER_PATHS[@]}"; do
            sed -i '' "s|${pattern}${filename}|images/${filename}|g" "$BLOG_DIR/index.html"
        done
    fi
done

# 额外保险：把所有包含论文目录名的路径都替换掉
sed -i '' "s|/${PAPER_DIR_NAME}/||g" "$BLOG_DIR/index.html"

# 更新 blogs.yml
echo "📝 更新 blogs.yml..."

# 检查是否已存在
if grep -q "${DATE_FORMATTED}_${SLUG}" "_data/blogs.yml"; then
    echo "博客已存在，跳过添加"
else
    # 生成简短描述（从 HTML 中提取）
    DESCRIPTION="论文报告: ${PAPER_TITLE}"
    
    cat >> "_data/blogs.yml" << EOF

- title: "$PAPER_TITLE"
  file: "/assets/blog/${DATE_FORMATTED}_${SLUG}/"
  date: $DATE_FORMATTED
  description: "$DESCRIPTION"
  tags: ["Papers", "AI"]
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