# F-Droid 上架材料

向 F-Droid 提交所需的材料分两处存放，对应 F-Droid 的两种机制。

## 1. 源码仓库 metadata —— F-Droid 自动抓取

描述、图标和截图放在**仓库根目录** `metadata/en-US/`（fastlane 兼容结构），
F-Droid 构建时自动扫描，无需发 MR：

- `metadata/en-US/short_description.txt` —— 一句话简介（≤80 字符）
- `metadata/en-US/full_description.txt` —— 完整英文描述（≤4000 字符）
- `metadata/en-US/images/icon.png` —— 应用图标（512×512）
- `metadata/en-US/images/phoneScreenshots/1.png` 等 —— 应用截图

> `en-US` 是 F-Droid 的 fallback 语言目录。详见官方文档：
> https://f-droid.org/docs/All_About_Descriptions_Graphics_and_Screenshots/

## 2. fdroiddata 提交 —— 手动发 MR

向 fdroiddata 仓库只需提交**一个文件**：

- `chn.mathinchina.jupyter_mobile.yml` —— 主元数据（含构建指令）

提交方式：fork `gitlab.com/fdroid/fdroiddata` 后，在
`metadata/chn.mathinchina.jupyter_mobile.yml` 添加该文件并发起 MR。

## 上架步骤

1. 确保上游仓库满足自由软件要求（GPL-3.0-only 已就位、收款码已移除、
   Gradle wrapper 已纳入版本控制、已打 tag `v1.1.1`）。
2. fork `fdroiddata`，只添加 `metadata/chn.mathinchina.jupyter_mobile.yml`。
3. 发起 MR，等待 reviewer 在 F-Droid 构建服务器上验证构建。

## 待确认 / TODO

- Flutter 在 F-Droid 的构建通过 `srclibs: flutter` 注入 SDK，`3.47.0`
  需替换为 F-Droid 已收录的 Flutter 版本号。
- 项目当前工具链较新（Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0 / NDK 29）。
  按当前约定不在项目内降级；若 F-Droid 构建服务器不支持这些版本，需与
  reviewer 沟通调整构建环境或工具链版本。
- 源码已镜像到 GitHub（`github.com/MathinChina/JupyterMobile`），作为 F-Droid
  构建服务器拉取源码的主仓库；gitee 仅作为镜像源。
