#!/bin/bash

# 用法: ./add_blog.sh /path/to/your/blog.html "博客标题" 2026-03-06
# 示例: ./add_blog.sh /Users/lichangkang/.openclaw/workspace/papers/20260305_RAPID/report.html "RAPID" 2026-03-04

HTML_FILE=$1
TITLE=$2
DATE=$3

if [ -z "$HTML_FILE" ] || [ -z "$TITLE" ] || [ -z "$DATE" ]; then
  echo "用法: ./add_blog.sh <html文件路径> <标题> <日期>"
  echo "示例: ./add_blog.sh /path/to/blog.html '我的博客' 2026-03-06"
  exit 1
fi

if [ ! -f "$HTML_FILE" ]; then
  echo "错误: 文件不存在: $HTML_FILE"
  exit 1
fi

# 用标题生成目录名
SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g' | sed 's/[^a-z0-9-]//g' | sed 's/-$//')
DIR_NAME="${DATE}_${SLUG}"
DEST_DIR="assets/blog/${DIR_NAME}"

# 创建目录
mkdir -p "$DEST_DIR/images"

# 获取源目录
SOURCE_DIR=$(dirname "$HTML_FILE")
PAPERS_DIR=$(dirname "$SOURCE_DIR")

echo "📄 处理 HTML 文件: $HTML_FILE"

# 提取 HTML 中的图片路径
IMAGES=$(grep -oE 'src="[^"]*\.(png|jpg|jpeg|gif|svg|webp)"' "$HTML_FILE" | sed 's/src="//;s/"$//' | sort -u)

if [ -z "$IMAGES" ]; then
  echo "⚠ 未找到图片"
else
  echo "📷 找到的图片:"
  COPIED=0

  # 用文件名搜索图片（在整个 papers 目录下递归搜索）
  for img in $IMAGES; do
    # 跳过绝对URL和外部链接
    if [[ "$img" =~ ^http:// ]] || [[ "$img" =~ ^https:// ]] || [[ "$img" =~ ^// ]]; then
      echo "  - $img (跳过: 外部链接)"
      continue
    fi

    # 获取文件名
    filename=$(basename "$img")
    # 去除查询参数（如 ?v=1）
    filename=$(echo "$filename" | sed 's/?.*$//')

    # 在 papers 目录下递归搜索
    FOUND_FILE=$(find "$PAPERS_DIR" -type f -name "$filename" 2>/dev/null | head -1)

    if [ -n "$FOUND_FILE" ]; then
      cp "$FOUND_FILE" "$DEST_DIR/images/$filename"
      echo "  ✓ $filename"
      COPIED=$((COPIED + 1))
    else
      echo "  ✗ 未找到: $filename"
    fi
  done
  echo "✓ 复制了 $COPIED 张图片"
fi

# 复制 HTML 文件
cp "$HTML_FILE" "$DEST_DIR/index.html"

# 修改 HTML 中的图片路径为相对路径
for img in $IMAGES; do
  # 跳过外部链接
  if [[ "$img" =~ ^http:// ]] || [[ "$img" =~ ^https:// ]] || [[ "$img" =~ ^// ]]; then
    continue
  fi

  # 获取文件名
  filename=$(basename "$img")
  filename=$(echo "$filename" | sed 's/?.*$//')

  # 替换各种路径格式为相对路径
  sed -i '' "s|src=\"$img\"|src=\"images/$filename\"|g" "$DEST_DIR/index.html"
  sed -i '' "s|src=\"$img\"|src=\"images/$filename\"|g" "$DEST_DIR/index.html"
done

echo "✓ 已修改 HTML 中的图片路径"

# 更新 blogs.yml
BLOGS_FILE="_data/blogs.yml"

if grep -q "title: \"$TITLE\"" "$BLOGS_FILE"; then
  echo "⚠ 博客 '$TITLE' 已存在，跳过添加"
else
  cat >> "$BLOGS_FILE" << EOF

- title: "$TITLE"
  file: "/assets/blog/${DIR_NAME}/"
  date: $DATE
  description: "添加描述"
  tags: []
EOF
  echo "✓ 添加到博客列表"
fi

echo ""
echo "✓ 完成！博客已添加到 $DEST_DIR"
echo ""
echo "⚠ 注意：请更新 _data/blogs.yml 中的 description 和 tags"