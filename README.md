# JupyterMobile

在 Android 上连接 Termux 里的 Jupyter Notebook 的 Flutter 客户端。

## Termux 一键部署（推荐）

仓库根目录的 `jupytermobile.sh` 是一个一键部署脚本。**下载并执行一次**，
即可安装两个命令（互为别名），后续只需用命令管理服务：

```bash
# 1. 下载脚本
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/main/jupytermobile.sh -o jupytermobile.sh

# 2. 执行（默认即安装命令）
bash jupytermobile.sh

# 3. 重新打开终端，或让当前终端生效
source ~/.bashrc
```

安装后可用以下命令：

```bash
# 全称
jupytermobile config       # 配置端口与令牌（交互式）
jupytermobile start        # 写配置并后台启动
jupytermobile stop         # 停止
jupytermobile status       # 查看运行状态
jupytermobile log          # 查看日志

# 简写
jm config                  # 配置端口与令牌
jm config --port 8888 --gen-token   # 非交互：指定端口 + 随机令牌
jm start
jm stop
jm status
jm log
```

`jm config` 会把端口与令牌写入 `~/.config/jupytermobile/config.env`，
并在启动时生成 `~/.jupyter/jupyter_server_config.py`（使用
`c.IdentityProvider.token`）。令牌与 App 连接界面里填写/随机生成的
token 保持一致即可。

## Getting Started（开发）

这是一个 Flutter 应用。要本地开发：

```bash
flutter pub get
flutter run
```

更多 Termux 部署时的常见报错（maturin、psutil、cffi、pyzmq 等），见
[docs/termux-jupyter-troubleshooting.md](docs/termux-jupyter-troubleshooting.md)。

更多 Flutter 资源：

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
