# Termux 部署 Jupyter Notebook 问题排查手册

本文档把在 Termux（Android）里安装、编译、运行 Jupyter Notebook 时最常见的
报错与解决方式汇总成一份可照做的清单，并结合本 App 的部署脚本口径统一说明。

阅读约定：所有命令均在 Termux 里执行，**不要使用 `sudo`**（Termux 是单用户
环境，普通用户身份即可）。

---

## 0. 快速自检：先判断你卡在哪一类

| 报错关键词 / 现象 | 对应章节 | 一句话结论 |
| --- | --- | --- |
| `maturin`、`ANDROID_API_LEVEL`、`rpds-py` | [第 2 章](#2-maturinrust-扩展报错) | 设置 `ANDROID_API_LEVEL` 再重装 |
| `psutil`、`android platform`、`getifaddrs` | [第 3 章](#3-psutil-编译报错) | 优先 `pkg install python-psutil` |
| `ffi.h`、`No such file`、`cffi` | [第 4 章](#4-cfficffih-报错) | 装 `libffi`，带 `CFLAGS` 重装 cffi |
| `pyzmq`、`zmq.h`、`libzmq` | [第 5 章](#5-pyzmq-编译报错) | 先 `pkg install libzmq` 再 pip |
| `ld` 找不到、链接失败 | [第 6 章](#6-链接器与编译工具链) | 装 `binutils` / `binutils-is-llvm` |
| 打开链接却连不上 / 只有方格子 | [第 8 章](#8-启动与连接) | 用 `--ip=0.0.0.0`，复制完整带 token 的 URL |

---

## 1. 推荐的整体安装流程

如果还没有搭好环境，按下面顺序走一遍，可以提前避开大部分编译坑。

### 1.1 准备 Termux

建议从 F-Droid 或 GitHub Releases 安装 Termux，**避免 Google Play 版本**
（Play 版本因 Target SDK 限制，部分编译与包管理行为有差异）。

```bash
pkg update -y && pkg upgrade -y
```

### 1.2 安装核心编译依赖

Jupyter 的很多依赖在 Android 上需要从源码编译，先把工具链装齐：

```bash
pkg install -y python rust libffi clang make cmake git \
  libbz2 zlib libjpeg-turbo binutils libzmq
```

> `libzmq` 提前装好，可以避免 [pyzmq](#5-pyzmq-编译报错) 从源码编译卡住。

### 1.3 创建并进入虚拟环境（推荐）

```bash
python -m venv ~/jupyter-env
source ~/jupyter-env/bin/activate
```

之后所有 `pip` 操作都在这个虚拟环境里进行。

### 1.4 升级打包工具

```bash
pip install --upgrade pip setuptools wheel
```

### 1.5 设置 Android API 级别（关键）

很多 Rust / C 扩展需要知道设备的 Android API 级别才能正确交叉编译。先在当前
终端导出：

```bash
export ANDROID_API_LEVEL=28
```

想永久生效（每次打开 Termux 都自动设置），把下面这行追加到 `~/.bashrc` 末尾：

```bash
echo 'export ANDROID_API_LEVEL=28' >> ~/.bashrc
```

如何确定你设备精确的 API 级别：

```bash
python -c "import sysconfig; print(sysconfig.get_config_var('ANDROID_API_LEVEL'))"
```

用输出的数字替换上面的 `28` 即可。推荐 `28` 是社区验证过比较稳定的取值。

### 1.6 安装并启动 Jupyter

```bash
pip install --no-cache-dir jupyter
```

启动 Notebook（注意用 `--no-browser` 和 `--ip=0.0.0.0`）：

```bash
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser
```

Termux 不会自动弹浏览器，你会看到类似
`http://127.0.0.1:8888/?token=...` 的链接。**复制完整的 URL（含 token）**，
在手机浏览器打开即可。

---

## 2. maturin / Rust 扩展报错

### 症状

安装 `rpds-py` 等依赖时，maturin 在编译 Rust 扩展时提示缺少 Android API
级别信息，无法正确构建。

### 解决

1. 显式设置 API 级别（推荐 28）：

   ```bash
   export ANDROID_API_LEVEL=28
   ```

2. 重新安装：

   ```bash
   pip install rpds-py -i https://pypi.tuna.tsinghua.edu.cn/simple
   ```

3. 想永久生效，把 `export ANDROID_API_LEVEL=28` 追加到 `~/.bashrc`。

### 设置后仍然失败

个别情况是 maturin 与 Python 3.14 的兼容性问题。可以尝试从 Git 源码安装
最新版 maturin：

```bash
pkg install binutils-is-llvm
cargo install --locked --git https://github.com/PyO3/maturin.git maturin
```

然后重新 `export ANDROID_API_LEVEL=28` 并重试 `pip install rpds-py`。

---

## 3. psutil 编译报错

### 症状

`psutil` 在 Android 平台上不被原生支持，`pip` 从源码编译时会因为检测到系统
平台是 android 而直接退出（常见报错与 `getifaddrs` / `freeifaddrs` 相关）。

### 方法一：使用 Termux 预编译包（推荐）

Termux 官方仓库已经为 Android 预编译好了 psutil，直接装，无需源码编译：

```bash
pkg install python-psutil
```

装完再重试安装 jupyter。

> 注意：如果使用了虚拟环境，`pkg install` 装的是 Termux 系统 Python，
> 需要确认虚拟环境能否导入；必要时在虚拟环境内用下面的方法二/三。

### 方法二：设置环境变量后从源码编译

需要特定版本 psutil 时可用：

```bash
pkg install build-essential clang
export ANDROID_API_LEVEL=24
pip install psutil
```

Android 的 `getifaddrs` / `freeifaddrs` 系统调用需要 API level 24 或更高，
设置该变量有助于编译通过。

### 方法三：使用兼容版本

有用户反馈 `5.9.3` 等版本包含针对 Android 的兼容性修复：

```bash
pip install psutil==5.9.3
```

### 其他备选

- 使用 Chaquo 的第三方 Android wheels：
  <https://chaquo.com/pypi-13.1/psutil/>
- 从含修复的 Git 提交安装：

  ```bash
  pip install psutil@git+https://github.com/giampaolo/psutil.git@b88f4d8
  ```

---

## 4. cffi / ffi.h 报错

### 症状

安装时出现 `ffi.h: No such file or directory` 等头文件缺失错误。

### 解决

1. 确保安装了 `libffi`：

   ```bash
   pkg install libffi
   ```

2. 带编译/链接路径强制重装 cffi：

   ```bash
   CFLAGS="-I$PREFIX/include" LDFLAGS="-L$PREFIX/lib" \
     pip install --no-cache-dir --force-reinstall cffi
   ```

`$PREFIX` 是 Termux 的安装前缀（通常是 `/data/data/com.termux/files/usr`），
头文件在 `$PREFIX/include`，库在 `$PREFIX/lib`。

---

## 5. pyzmq 编译报错

### 症状

`pyzmq` 编译卡住，或出现 `zmq.h` 缺失、找不到 `libzmq`。

### 解决

先安装系统包，再装 Python 包：

```bash
pkg install libzmq
pip install pyzmq
```

如果仍尝试从源码编译，确认 `zmq.h` 可用：

```bash
ls "$PREFIX/include/zmq.h"
```

不存在则说明 `libzmq` 没装好，重新执行 `pkg install libzmq`。

---

## 6. 链接器与编译工具链

### 症状

编译大包时报 `ld: ... not found`、链接失败，或内存不足被杀进程。

### 解决

- 链接相关：`pkg install binutils`；个别 Rust 工具链场景用
  `pkg install binutils-is-llvm`。
- 内存不足：关闭后台应用后重试；或减少并行编译（如 `CARGO_BUILD_JOBS=1`、
  `MAKEFLAGS="-j1"`）。

---

## 7. 通用兜底：社区一键脚本

想快速搭建，可尝试社区脚本（自动处理不少兼容性问题）：

```bash
pkg install -y git
git clone https://github.com/FGBASTANTE/termux_science_setup.git
cd termux_science_setup && chmod +x termux_science_setup.sh && ./termux_science_setup.sh
```

---

## 8. 启动与连接

### 一键脚本（推荐）

本项目根目录提供了 `jupytermobile.sh`，下载执行一次即可安装 `jm` /
`jupytermobile` 命令，之后用 `jm config` 配置端口令牌、`jm start` 启动、
`jm stop` 停止、`jm status` 查看状态、`jm log` 看日志：

```bash
bash jupytermobile.sh      # 安装命令
source ~/.bashrc
jm config --port 8888 --gen-token
jm start
```

### 手动启动

### 启动命令

```bash
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser
```

- `--ip=0.0.0.0`：监听所有网卡，便于本机 / 局域网访问。
- `--no-browser`：Termux 无 GUI 浏览器，避免它尝试调用系统浏览器失败。

### 令牌（token）在哪

启动日志里会打印类似
`http://127.0.0.1:8888/?token=...` 或 `http://127.0.0.1:8888/tree?token=...`。
复制**完整 URL（含 token 部分）**。

本 App 的「连接界面」使用固定 token：在界面上随机生成或手动填写，然后由
部署脚本写入 `jupyter_server_config.py` 的 `c.IdentityProvider.token`，
两边保持一致即可。

### 连接不上时检查

1. 服务是否真的起来了：`pgrep -f jupyter-notebook`。
2. 端口是否在监听：`ss -ltn | grep 8888`（或用 `netstat`）。
3. 是否用了 `--no-browser` 且没有 `--ip=0.0.0.0` 导致只能本机访问。
4. 是否复制错了 URL（少了 token、少了端口）。

---

## 9. 输出里的“方格子”（乱码）

### 症状

命令输出 / 终端输出里出现方格子（豆腐块），看起来像 Flutter 不支持某些字符。

### 原因

方格子通常不是「Flutter 不支持」，而是当前使用的字体**缺少对应字符的字形**
（glyph）。`pip` / `jupyter` 的输出常包含：

- Box-drawing 表格框线（`┌ ─ ┐ │ └ ┘`）
- 箭头（`→ ←`）、对勾/叉（`✓ ✗`）、圆点（`•`）
- ANSI 转义序列（颜色、光标控制、进度条回行覆盖）

默认的 `monospace` 在部分设备上不覆盖这些字符，于是显示为方格子；ANSI
转义序列还会在纯文本里表现为 `[32m` 之类的乱码。

### 本 App 的处理

1. **剥离 ANSI 转义序列**：`lib/core/ansi.dart` 提供 `stripAnsi()`，把 CSI /
   OSC 序列剥离、把回车（进度条回行）归一化为换行。cell 输出、扩展管理输出、
   终端输出都已接入。
2. **换成覆盖更全的等宽字体**：内置 `DejaVu Sans Mono`（
   `assets/fonts/DejaVuSansMono.ttf`），覆盖 box-drawing、箭头、数学符号等
   终端常用字符，避免方格子。

### 如果你仍看到方格子

- 确认对应字符确实属于终端常用的 box-drawing / 箭头 / 数学符号；若是更生僻
  的符号，可考虑替换为覆盖更广的字体（如 Noto Sans Mono CJK）。
- 若是网络返回的富文本（HTML/Markdown）里的 emoji，那是另一条渲染路径，
  与等宽字体的 box-drawing 无关。

---

## 附：本 App 的 Termux 部署口径

- 配置与命令分离：`jupyter_server_config.py` 只写一次，日常跑启动 / 停止。
- token 使用 Jupyter Server 2.x 的规范项 `c.IdentityProvider.token`，不再用
  已废弃的 `c.ServerApp.token` / `c.NotebookApp.token`。
- 共享目录模式把配置与 notebook 放到 `/sdcard/JupyterMobile`，便于文件管理器 /
  Shizuku 直接读写；私有模式放到 `~/.jupyter`。
