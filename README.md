# JupyterMobile

在 Android 上连接、编写并执行 Jupyter Notebook 的 Flutter 客户端，配套
Termux 里的一键部署脚本，让手机也能跑 Notebook。

## 功能特性

- Notebook 的渲染、编辑与执行（Markdown / Code / Raw 单元）
- 代码单元折叠 / 展开
- 内置等宽字体与 ANSI 转义清洗，终端 / 命令输出不再显示方格子或乱码
- 中文 / 英文界面（i18n）
- Notebook 重命名、另存为 `.ipynb`
- 外部扩展管理（pip 包 + nbextension / labextension）
- 连接令牌可在界面随机生成或手动指定
- 赞助页

## 服务端：Termux 一键部署（推荐）

仓库根目录的 `jupytermobile.sh` 是一键部署脚本。**下载并执行一次**，即可
安装 `jupytermobile` / `jm` 两个命令（互为别名），后续只需用命令管理服务：

```bash
# 1. 下载脚本（当前分支 feat/i18n-rename-extensions）
curl -fsSL https://gitee.com/mathinchina/JupyterMobile/raw/feat/i18n-rename-extensions/jupytermobile.sh -o jupytermobile.sh

# 2. 执行（默认即安装命令）
bash jupytermobile.sh

# 3. 重新打开终端，或让当前终端生效
source ~/.bashrc
```

安装后可用以下命令：

```bash
# 简写（推荐）
jm config                                # 交互式配置端口与令牌
jm config --port 8888 --gen-token        # 指定端口 + 随机令牌
jm start                                 # 写配置并后台启动
jm stop                                  # 停止
jm status                                # 查看运行状态
jm log                                   # 查看日志

# 全称等价
jupytermobile config
jupytermobile start
jupytermobile stop
jupytermobile status
jupytermobile log
```

`jm config` 会把端口与令牌写入 `~/.config/jupytermobile/config.env`，
并在启动时生成 `~/.jupyter/jupyter_server_config.py`（使用
`c.IdentityProvider.token`）。令牌与 App 连接界面里填写/随机生成的
token 保持一致即可。启动成功后，访问地址为：

```text
http://127.0.0.1:<端口>/?token=<令牌>
```

## 客户端：连接与使用

1. 在 App 里填写 Termux 的 Jupyter 服务地址、端口和令牌（端口/令牌与
   `jm config` 里的一致）。
2. 连接后即可新建 / 打开 Notebook，运行代码单元，查看输出。
3. 令牌可点「随机生成」按钮生成，也可手动填写；空令牌会自动补随机值。

## 常见问题

Termux 部署时遇到的编译 / 运行报错（maturin、`ANDROID_API_LEVEL`、psutil、
cffi / ffi.h、pyzmq、链接器、启动连接等），见
[docs/termux-jupyter-troubleshooting.md](docs/termux-jupyter-troubleshooting.md)。

「输出方格子 / 乱码」的原因与处理方式，也在该文档第 9 章说明。

## 开发

这是一个 Flutter 应用。要本地开发：

```bash
flutter pub get
flutter run
```

运行静态检查与测试：

```bash
flutter analyze
flutter test
```

## 目录结构

```text
lib/
  core/          # 内核协议、连接、ANSI 清洗、Termux 部署、Notebook 模型
  l10n/          # 中英文文案
  providers/     # 内核提供者（external / http / remote）
  state/         # 连接持久化、locale、连接状态
  ui/            # 界面与组件（连接、主界面、扩展管理、赞助页）
jupytermobile.sh # Termux 一键部署脚本
docs/            # Termux Jupyter 问题排查手册
test/            # 单元与 widget 测试
```

更多 Flutter 资源：

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## 许可

项目依赖的 `DejaVu Sans Mono` 字体版权归 Bitstream / DejaVu 团队所有，其
改动为公共领域（public domain），详见字体文件内嵌的许可说明。
