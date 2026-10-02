# F-Droid 上架草稿

本目录是提交到 F-Droid 所需的元数据**草稿**。正式提交时，把这些文件复制到
`fdroiddata` 仓库（`gitlab.com/fdroid/fdroiddata`）的对应路径并发起 MR。

## 文件说明

- `chn.mathinchina.jupyter_mobile.yml` —— 主元数据（含构建指令）
- `en-US/short_description.txt` —— 一句话简介（≤80 字符）
- `en-US/full_description.txt` —— 完整英文描述

## 上架步骤

1. 确保上游仓库满足自由软件要求（GPL-3.0-only 已就位、收款码已移除、
   Gradle wrapper 已纳入版本控制）。
2. fork `fdroiddata`，在 `metadata/` 下添加主元数据、描述文件，以及
   图标 / 截图。
3. 发起 MR，等待 reviewer 在 F-Droid 构建服务器上验证构建。

## 待确认 / TODO

- `commit` 字段需换成实际发布的 tag（例如 `v1.1.0`）。
- Flutter 在 F-Droid 的构建通过 `srclibs: flutter` 注入 SDK，`3.47.0`
  需替换为 F-Droid 已收录的 Flutter 版本号。
- 项目当前工具链较新（Gradle 9.3.1 / AGP 9.1.0 / Kotlin 2.4.0 / NDK 29）。
  按当前约定不在项目内降级；若 F-Droid 构建服务器不支持这些版本，需与
  reviewer 沟通调整构建环境或工具链版本。
- 源仓库为 gitee.com；若 F-Droid 服务器克隆 gitee 不稳定，建议镜像到
  GitHub / GitLab / Codeberg。
