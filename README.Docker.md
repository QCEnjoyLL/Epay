# Docker 部署

本仓库已经包含 Docker 镜像构建、MySQL 自动初始化和 GitHub Actions 自动发布配置。

默认镜像：

- `orangeqiu/epay:latest`
- `orangeqiu/epay:sha-<commit短SHA>`

## 自动打包

推送到 `main` 后，GitHub Actions 会自动构建并推送 `orangeqiu/epay:latest`：

```bash
git add .
git commit -m "Update Docker deployment"
git push origin main
```

到 GitHub 仓库的 `Actions` 页面，打开 `Docker Image` 工作流，等待构建完成。成功后 Docker Hub 会出现 `orangeqiu/epay:latest` 镜像。

如需发版本号镜像：

```bash
git tag v1.0.0
git push origin v1.0.0
```

会额外发布 `orangeqiu/epay:v1.0.0`。

## 只下载 compose 启动

等 GitHub Actions 构建成功后，只需要下载 `docker-compose.yml` 和 `.env`：

```bash
curl -fsSLO https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/docker-compose.yml
curl -fsSLO https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/.env
docker compose up -d
```

Windows PowerShell：

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/docker-compose.yml -OutFile docker-compose.yml
Invoke-WebRequest -Uri https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/.env -OutFile .env
docker compose up -d
```

默认访问地址：

- 前台：`http://服务器IP:8080/`
- 后台：`http://服务器IP:8080/admin/`

默认后台账号来自上游安装脚本：

- 用户名：`admin`
- 密码：`123456`

第一次登录后立即修改后台密码。

## 修改配置

启动前可以编辑 `.env`：

```env
APP_PORT=8080
MYSQL_ROOT_PASSWORD=改成强密码
MYSQL_DATABASE=epay
MYSQL_USER=epay
MYSQL_PASSWORD=改成强密码
EPAY_DB_PREFIX=pay
EPAY_IMAGE=orangeqiu/epay:latest
```

生产环境建议至少修改 `MYSQL_ROOT_PASSWORD` 和 `MYSQL_PASSWORD`。

## 数据库初始化

应用容器首次启动时，会自动使用镜像内的 `install/install.sql` 初始化 MySQL，并根据 `EPAY_DB_PREFIX` 替换表前缀。

初始化只会在数据库卷为空时执行一次。需要清空本地测试数据并重新初始化时运行：

```bash
docker compose down -v
docker compose up -d
```

## 更新镜像

```bash
docker compose pull
docker compose up -d
```

## 常用命令

查看状态：

```bash
docker compose ps
```

查看应用日志：

```bash
docker compose logs -f app
```

查看数据库日志：

```bash
docker compose logs -f db
```

停止：

```bash
docker compose down
```

重启：

```bash
docker compose restart
```

进入应用容器：

```bash
docker compose exec app bash
```

## 定时任务

项目包含 `cron.php`，生产环境需要配置定时访问。可在服务器 crontab 中按需添加：

```cron
*/5 * * * * curl -fsS http://127.0.0.1:8080/cron.php >/dev/null 2>&1
```

如果后台配置了定时任务密钥，请按后台显示的地址填写。
