# Docker 部署

本仓库已经包含 Docker 镜像构建、MySQL 初始化和 GitHub Actions 自动发布配置。

镜像默认发布到：

- `你的DockerHub用户名/epay:latest`
- `你的DockerHub用户名/epay:sha-<commit短SHA>`

## 一、提交后自动打包

你已经在 GitHub 仓库配置了 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_TOKEN` 后，只需要推送到 `main`：

```bash
git add .
git commit -m "Add Docker deployment"
git push origin main
```

然后到 GitHub 仓库的 `Actions` 页面，打开 `Docker Image` 工作流，等待构建完成。成功后 Docker Hub 会出现 `epay:latest` 镜像。

如需发版本号镜像：

```bash
git tag v1.0.0
git push origin v1.0.0
```

会额外发布 `你的DockerHub用户名/epay:v1.0.0`。

## 二、本地源码构建启动

适合在服务器上拉源码后直接构建运行。

```bash
git clone https://github.com/QCEnjoyLL/Epay.git
cd Epay
cp .env.example .env
```

Windows PowerShell 使用：

```powershell
Copy-Item .env.example .env
```

编辑 `.env`，至少修改这些密码：

```env
MYSQL_ROOT_PASSWORD=改成强密码
MYSQL_PASSWORD=改成强密码
APP_PORT=8080
```

启动：

```bash
docker compose up -d --build
```

查看状态：

```bash
docker compose ps
docker compose logs -f app
```

访问：

- 前台：`http://服务器IP:8080/`
- 后台：`http://服务器IP:8080/admin/`

默认后台账号来自上游安装脚本：

- 用户名：`admin`
- 密码：`123456`

第一次登录后立即修改后台密码。

## 三、使用 Docker Hub 镜像启动

适合 GitHub Actions 已经把镜像推送到 Docker Hub 后使用。

先准备部署文件：

```bash
git clone https://github.com/QCEnjoyLL/Epay.git
cd Epay
cp .env.example .env
```

Windows PowerShell 使用：

```powershell
Copy-Item .env.example .env
```

编辑 `.env`：

```env
DOCKERHUB_IMAGE=你的DockerHub用户名/epay:latest
MYSQL_ROOT_PASSWORD=改成强密码
MYSQL_PASSWORD=改成强密码
APP_PORT=8080
```

拉取镜像并启动：

```bash
docker compose -f docker-compose.hub.yml pull
docker compose -f docker-compose.hub.yml up -d
```

更新到最新镜像：

```bash
docker compose -f docker-compose.hub.yml pull
docker compose -f docker-compose.hub.yml up -d
```

## 四、数据库初始化说明

`docker-compose.yml` 和 `docker-compose.hub.yml` 都会在首次启动 MySQL 时自动导入 `install/install.sql`，并根据 `.env` 中的 `EPAY_DB_PREFIX` 替换表前缀。

初始化只会在数据库卷为空时执行一次。需要清空本地测试数据并重新初始化时运行：

```bash
docker compose down -v
docker compose up -d --build
```

使用 Docker Hub 镜像方式时对应命令为：

```bash
docker compose -f docker-compose.hub.yml down -v
docker compose -f docker-compose.hub.yml up -d
```

## 五、常用运维命令

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

查看应用日志：

```bash
docker compose logs -f app
```

查看数据库日志：

```bash
docker compose logs -f db
```

## 六、定时任务

项目包含 `cron.php`，生产环境需要配置定时访问。可在服务器 crontab 中按需添加：

```cron
*/5 * * * * curl -fsS http://127.0.0.1:8080/cron.php >/dev/null 2>&1
```

如果后台配置了定时任务密钥，请按后台显示的地址填写。
