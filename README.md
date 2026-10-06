### 📦 环境变量配置说明

| 变量名 | 类型 | 默认值 | 示例 | 功能说明 |
| :--- | :---: | :---: | :--- | :--- |
| **TZ** | String | `Asia/Shanghai` | `UTC` | 容器时区；镜像里只带 `Asia/Shanghai` 这一份 zoneinfo（`/etc/localtime` 就是它） |
| **VW_WORKDIR** | String | `/opt/vw` | `/data` | vaultwarden 的工作目录，数据默认落在 `${VW_WORKDIR}/data` |
| **VW_VERSION** | String | 构建时的源码 tag | `1.37.3` | 由构建流程传入，等于本次编译的上游 tag |
| **ROCKET_ADDRESS** | String | `127.0.0.1` | `127.0.0.1` | vaultwarden 监听地址；不要改成 `0.0.0.0`，对外只走 caddy 的 `8080` |
| **ROCKET_PORT** | Integer | `8000` | `8000` | vaultwarden 监听端口 |
| **ROCKET_PROFILE** | String | `production` | `production` | Rocket 运行环境 |
| **CR_CADDY_PASS_SERVER** | String | `127.0.0.1` | `127.0.0.1` | caddy 反代的上游地址 |
| **CR_CADDY_PASS_PORT** | Integer | `8000` | `8000` | caddy 反代的上游端口 |
| **CR_CADDY_REAL_IP** | String | `X-Forwarded-For` | `CF-Connecting-IP` | 反代时识别真实 IP 的请求头（Caddy 据此填 `X-Real-IP` / `X-Forwarded-For`） |
| **CR_CONTROLLER_CONFIG** | String | `/etc/controller/config.json` | | 控制器配置：要托管的进程、模板、目录与备份，可用挂载的配置替换 |
| **CR_BACKUP_AT** | String | `21:01` | `03:30` | 每日备份时刻，格式 `HH:MM` |
| **CR_BACKUP_TZ** | String | `Asia/Shanghai` | `UTC` | 备份时刻所用的时区 |
| **CR_AUTOBACKUP_BACKUP_PATH** | String | `/opt/vw/data` | | 备份要打包的目录 |
| **CR_AUTOBACKUP_BACKUP_NAME** | String | `vaultwarden` | | 备份名称前缀 |
| **CR_AUTOBACKUP_ENCRYPTION_PUB_KEY** | String | | `base64...` | Base64 编码的 GPG 公钥，备份用它加密 |
| **CR_AUTOBACKUP_OSS_ACCESS_KEY_ID** | String | | | 阿里云 OSS AccessKey ID |
| **CR_AUTOBACKUP_OSS_ACCESS_KEY_SECRET** | String | | | 阿里云 OSS AccessKey Secret |
| **CR_AUTOBACKUP_OSS_BUCKET** | String | | | 阿里云 OSS Bucket |
| **CR_AUTOBACKUP_OSS_REGION** | String | | | 阿里云 OSS Region（如 `cn-hongkong`，程序自动拼域名） |
| **CR_AUTOBACKUP_PUSH_URL** | String | | | 备份日志推送的 Webhook URL |
| **CR_AUTOBACKUP_PUSH_TOKEN** | String | | | 备份日志推送的 Token |
| **CR_AUTOBACKUP_DAYS_TO_KEEP** | Integer | `7` | | OSS 上保留旧备份的天数 |
| **DATA_FOLDER** | String | `data` | `data` | Vaultwarden 数据目录，相对 `${VW_WORKDIR}`；`DATABASE_URL`、`TMP_FOLDER` 等若也写相对路径，基准同样是 `${VW_WORKDIR}` |
| **WEB_VAULT_FOLDER** | String | `web-vault/` | `web-vault/` | 前端静态目录，相对 `${VW_WORKDIR}`；镜像已放在 `/opt/vw/web-vault/` |
| **其它 Vaultwarden 变量** | | | | `DOMAIN`、`ADMIN_TOKEN`、`SIGNUPS_*`、`SMTP_*`、`PUSH_*`、`ICON_*`、`*_SCHEDULE` 等原样透传给进程，默认值与含义见上游 [wiki](https://github.com/dani-garcia/vaultwarden/wiki) |
