# 个人主页模板

基于 al-folio 的学术个人主页模板。

## 快速添加 HTML 博客

### 推荐：使用脚本（自动复制 HTML 和图片）

```bash
./scripts/add_blog.sh /path/to/blog.html "博客标题" 2026-03-06
```

脚本会：
1. 在 `assets/blog/` 下创建以日期命名的文件夹
2. 复制 HTML 文件（重命名为 index.html）
3. 如果源目录有 `images` 文件夹，一并复制
4. 自动添加到 `_data/blogs.yml`

### 手动流程

#### 1. 复制 HTML 文件
将写好的 HTML 文件复制到 `assets/blog/` 目录。

```bash
cp /path/to/your/blog.html assets/blog/2026-03-06-your-title.html
```

### 2. 配置博客目录
在 `_data/blogs.yml` 中添加博客信息：

```yaml
- title: "你的博客标题"
  file: "/assets/blog/2026-03-06-your-title/"
  date: 2026-03-06
  description: "博客描述，会显示在博客列表页"
  tags: ["Papers", "code"]  # 可选，用于分类
```

注意：
- 路径最后要加 `/`，因为 Jekyll 会把 HTML 转为子目录。
- `description` 和 `tags` 是可选的，但建议添加，让博客列表页显示更美观

### 3. 推送部署
```bash
git add -A
git commit -m "feat: 添加新博客"
git push
```

GitHub Actions 会自动构建并部署到 gh-pages 分支。

## 本地预览

```bash
bundle exec jekyll serve
```

然后访问 http://localhost:4000

## 图片路径建议

HTML 博客中的图片建议使用相对路径：

```
assets/blog/2026-03-04_rapid/
├── index.html          # HTML 中用 <img src="images/figure1.png">
└── images/
    └── figure1.png
```