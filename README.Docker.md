# Docker 部署

本仓库包含 Docker 镜像构建、MySQL 自动初始化和 GitHub Actions 自动发布配置。

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

## 方案一：自带 MySQL 容器

适合没有现成 MySQL 的服务器。只需要下载 `docker-compose.yml` 和 `.env`：

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

## 方案二：使用服务器已有 MySQL

适合服务器上已经安装 MySQL，不想再启动 MySQL 容器的场景。

下载外部 MySQL 专用 compose 和 env：

```bash
curl -fsSL https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/docker-compose.external-mysql.yml -o docker-compose.yml
curl -fsSL https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/.env.external-mysql -o .env
```

Windows PowerShell：

```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/docker-compose.external-mysql.yml -OutFile docker-compose.yml
Invoke-WebRequest -Uri https://raw.githubusercontent.com/QCEnjoyLL/Epay/main/.env.external-mysql -OutFile .env
```

编辑 `.env`，修改数据库连接：

```env
DB_HOST=host.docker.internal
DB_PORT=3306
MYSQL_DATABASE=epay
MYSQL_USER=epay
MYSQL_PASSWORD=改成你的数据库密码
EPAY_DB_PREFIX=pay
```

如果 MySQL 就装在同一台 Linux 服务器，通常保留：

```env
DB_HOST=host.docker.internal
```

如果 MySQL 在另一台服务器，把 `DB_HOST` 改成那台服务器的 IP 或域名。

### 准备 MySQL

在 MySQL 里创建空数据库和账号：

```sql
CREATE DATABASE epay DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'epay'@'%' IDENTIFIED BY '改成强密码';
GRANT ALL PRIVILEGES ON epay.* TO 'epay'@'%';
FLUSH PRIVILEGES;
```

如果 MySQL 和 Docker 在同一台服务器，还要确保 MySQL 允许 Docker 容器连接。检查 MySQL 配置里的 `bind-address`，不要只监听 `127.0.0.1`。常见配置：

```ini
bind-address = 0.0.0.0
```

修改后重启 MySQL。

启动应用容器：

```bash
docker compose up -d
```

## 访问地址

- 前台：`http://服务器IP:8080/`
- 后台：`http://服务器IP:8080/admin/`

默认后台账号来自上游安装脚本：

- 用户名：`admin`
- 密码：`123456`

第一次登录后立即修改后台密码。

## 数据库初始化

应用容器首次启动时，会自动使用镜像内的 `install/install.sql` 初始化 MySQL，并根据 `EPAY_DB_PREFIX` 替换表前缀。

初始化只会在目标数据库还没有 `${EPAY_DB_PREFIX}_config` 表时执行。使用已有 MySQL 时，建议使用空数据库，避免同名前缀表被安装 SQL 覆盖。

需要清空自带 MySQL 容器的数据并重新初始化：

```bash
docker compose down -v
docker compose up -d
```

使用服务器已有 MySQL 时，请在 MySQL 中手动清空对应数据库后再重新启动容器。

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
