# 个人主页模板

基于 al-folio 的学术个人主页模板。

## 添加 HTML 博客流程

### 1. 复制 HTML 文件
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
```

注意：路径最后要加 `/`，因为 Jekyll 会把 HTML 转为子目录。

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