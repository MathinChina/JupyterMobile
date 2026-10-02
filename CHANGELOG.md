# Changelog

## v1.1.0

### 新增

- 部署方式支持「一键脚本」：复制命令即可安装 `jm` / `jupytermobile`，
  `jm config` 配置端口令牌、`jm start/stop/status/log` 管理服务
- Termux 一键部署脚本 `jupytermobile.sh`（下载执行一次）
- 代码 / 文本单元折叠与展开
- 连接令牌可随机生成或手动指定，不再使用占位符
- 赞助页（微信 / 支付宝收款码 + 赞助链接）
- 外部扩展管理：pip 包 + nbextension / labextension
- 中 / 英文界面（i18n）
- Notebook 重命名、另存为 `.ipynb`

### 修复

- 命令 / 终端输出显示「方格子」：内置 DejaVu Sans Mono 字体 + ANSI 转义清洗
- 补充 Termux Jupyter 部署问题排查文档（maturin / psutil / cffi / pyzmq 等）

### 文档

- 完善 README（项目简介、一键部署、客户端使用、开发说明）

## v1.0.0

- 首个版本：连接外部 / 本机 Termux Jupyter 内核，Notebook 渲染 / 编辑 / 执行。
