# 个人主页模板

基于 al-folio 的学术个人主页模板。

## 目录

- [快速开始](#快速开始)
- [添加 HTML 博客](#添加-html-博客)
- [删除博客](#删除博客)
- [本地预览](#本地预览)
- [部署](#部署)

## 快速开始

```bash
# 安装依赖
bundle install

# 本地预览
bundle exec jekyll serve
```

访问 http://localhost:4000

## 添加 HTML 博客

### 使用脚本（推荐）

```bash
./scripts/add_blog.sh /path/to/blog.html "博客标题" 2026-03-06
```

**参数说明：**
1. HTML 文件路径（完整路径）
2. 博客标题
3. 日期（格式：2026-03-06）

**脚本功能：**
- 自动在 `assets/blog/日期_标题/` 创建目录
- 复制 HTML 文件为 `index.html`
- 解析 HTML 中的图片路径，在源目录下递归搜索图片
- 复制图片到 `images/` 目录
- 自动修改 HTML 中的图片路径为相对路径（`images/xxx.png`）
- 添加博客信息到 `_data/blogs.yml`

**示例：**
```bash
./scripts/add_blog.sh /Users/lichangkang/.openclaw/workspace/papers/20260305_RAPID/report.html "RAPID: 长上下文推理的检索增强推测解码" 2026-03-05
```

### 博客配置

脚本会自动添加基础配置到 `_data/blogs.yml`，手动修改：

```yaml
- title: "博客标题"
  file: "/assets/blog/2026-03-05_rapid/"
  date: 2026-03-05
  description: "博客描述，会显示在博客列表页"  # 必填
  tags: ["Papers", "code"]  # 分类，可多个
```

### 博客结构

```
assets/blog/2026-03-05_rapid/
├── index.html          # 主 HTML 文件，图片用相对路径
└── images/
    ├── figure1.png
    └── figure2.png
```

## 删除博客

### 步骤 1：删除博客文件

```bash
# 删除博客目录（包含 HTML 和图片）
rm -rf assets/blog/2026-03-05_rapid/
```

### 步骤 2：删除博客配置

编辑 `_data/blogs.yml`，删除对应的博客条目：

```yaml
# 删除这一整块
- title: "RAPID: 长上下文推理的检索增强推测解码"
  file: "/assets/blog/2026-03-05_rapid/"
  date: 2026-03-05
  description: "介绍 RAPID 方法..."
  tags: ["Papers", "code"]
```

### 步骤 3：提交并推送

```bash
git add -A
git commit -m "chore: 删除博客"
git push
```

## 本地预览

```bash
bundle exec jekyll serve
```

然后访问 http://localhost:4000

## 部署

推送到 master 分支后，GitHub Actions 会自动构建并部署到 gh-pages 分支。

```bash
git add -A
git commit -m "feat: 添加新博客"
git push
```