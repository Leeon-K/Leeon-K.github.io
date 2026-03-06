# CLAUDE.md - 项目开发指南

## 项目概述

基于 al-folio 的学术个人主页 Jekyll 模板托管在 GitHub Pages。

## 项目结构

```
├── _config.yml          # Jekyll 配置文件
├── _data/
│   └── blogs.yml        # HTML 博客列表配置
├── _pages/
│   └── blog.md          # 博客列表页模板
├── assets/
│   └── blog/            # HTML 博客内容（每个博客一个目录）
│       └── 2026-03-05_rapid/
│           ├── index.html
│           └── images/
└── scripts/
    └── add_blog.sh      # 添加博客的自动化脚本
```

## 常用操作

### 添加 HTML 博客

**唯一正确方式：使用脚本**

```bash
./scripts/add_blog.sh /path/to/blog.html "博客标题" 2026-03-06
```

**重要细节：**
1. HTML 中的图片必须用相对路径或绝对路径（如 `/20260305_RAPID/source/figures/xxx.png`）
2. 脚本会根据 HTML 中的 `<img src="...">` 提取文件名，然后在源目录的父目录（papers 目录）下递归搜索
3. 搜索路径：`/Users/lichangkang/.openclaw/workspace/papers/` 及其子目录
4. 图片会复制到博客目录的 `images/` 子目录，并自动修改 HTML 中的路径

**源目录结构（重要）：**
- HTML 文件通常在 `/Users/lichangkang/.openclaw/workspace/papers/20260305_RAPID/report.html`
- 图片可能在 `/Users/lichangkang/.openclaw/workspace/papers/20260305_RAPID/source/figures/xxx.png`
- 脚本通过文件名搜索，所以只要图片在 papers 目录下就能找到

### 博客列表显示

HTML 博客显示在 `_pages/blog.md`，通过 `site.data.blogs` 读取配置。

每个博客条目支持：
- `title`: 标题
- `file`: 路径（注意末尾有 `/`，因为 Jekyll 把 HTML 转为子目录）
- `date`: 日期
- `description`: 描述
- `tags`: 分类数组

### 分类系统

- tags 在 `_config.yml` 的 `display_tags` 中定义
- categories 在 `_config.yml` 的 `display_categories` 中定义
- 点击 tag/category 会跳转到 `/blog/tag/xxx/` 或 `/blog/category/xxx/`

### 部署流程

```bash
git add -A
git commit -m "feat: 添加新博客"
git push
```

GitHub Actions 自动构建部署到 gh-pages。

## 开发注意事项

1. **不要手动复制 HTML 文件** - 必须使用脚本，否则图片路径处理很麻烦
2. **图片路径** - HTML 中使用带路径的引用（如 `source/figures/xxx.png`），脚本会自动搜索并转换
3. **baseurl** - 本地预览时为空，GitHub Pages 上也是空（因为是用户主页而非组织主页）
4. **_config.yml exclude** - 包含 `scripts/`，所以脚本不会被打包进构建

## 相关文件

- [_data/blogs.yml](_data/blogs.yml) - 博客列表配置
- [_pages/blog.md](_pages/blog.md) - 博客列表页
- [scripts/add_blog.sh](scripts/add_blog.sh) - 添加博客脚本
- [_config.yml](_config.yml) - Jekyll 配置（含 display_tags 和 display_categories）