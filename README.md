# 薪流 XinFlow

<p align="center">
  <img src="design-assets/icons/xinFlow_icon_v2.png" alt="薪流 XinFlow App Icon" width="180">
</p>

> 以工资周期为单位，记录工资的每一个去向，让你随时知道这笔工资还剩多少。

## 项目简介

薪流是一款面向个人的工资流向记录 App。它不追求完整资产管理，而是专注回答：每期工资去了哪里，现在还剩多少？

工资周期由用户设置的固定发薪日确定。消费、存款和理财均视为工资去向，并共同影响本期剩余金额。

```text
当前剩余 = 本期工资 - 净消费 - 存款 - 理财
```

## 主要功能

- 按固定发薪日管理当前与历史工资周期
- 快速记录消费、存款和理财，支持一级与二级分类
- 查看本期工资剩余、发薪倒计时和最近流水
- 查询、筛选、修改和软删除当前周期流水
- 通过关联退款记录冲减原消费
- 查看分类占比、每日趋势和周期对比报告
- 跟随系统、浅色和深色外观模式
- 导出与导入带 SHA-256 校验的 `.xinflow` 本地备份

## 技术栈

| 领域 | 方案 |
|---|---|
| 客户端 | Flutter + Dart |
| UI | Material 3 |
| 状态管理 | Riverpod |
| 数据库 | SQLite + Drift |
| 架构 | Repository + Domain Service |
| 备份 | JSON + ZIP + SHA-256 |

金额在数据库和业务层统一使用整数“分”保存，避免浮点数精度问题。应用无需账号或服务器即可离线使用。

## 快速开始

环境要求：Flutter 稳定版、Dart 3.12 或更高版本，以及对应平台的开发工具。Android 构建当前使用 NDK `28.2.13676358`。

```powershell
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter run
```

构建 Android 调试包：

```powershell
flutter build apk --debug
```

## 仓库结构

```text
XinFlow/
├─ lib/             Flutter 页面、业务逻辑与数据访问代码
├─ test/            单元测试和 Widget 测试
├─ docs/            产品与工程设计文档
├─ design-assets/   UI 参考图与图标素材
├─ android/         Android 平台工程
└─ ios/             iOS 平台工程
```

## 文档与状态

- [薪流 V1 产品与工程设计手册](docs/XINFLOW_V1_DESIGN.md)
- 当前版本：`0.1.0`
- 当前状态：V1 M0–M4 核心功能完成，已通过 Android 16 真机验证
- 待完成：Android 完整交互验收与 iOS 真机验收

设计手册是业务规则、数据模型、备份兼容和验收标准的开发基线。涉及工资周期、金额计算、退款或数据库迁移的变更，应同步更新设计文档并补充测试。

> `.xinflow` 备份未加密，可能包含个人财务数据，请妥善保管。

## License

项目许可证尚未确定。在正式添加许可证之前，仓库内容默认保留全部权利。
