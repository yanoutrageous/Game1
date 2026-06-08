# GraytailGodot

这是《灰尾回收 / 五四三二一》的 Godot 独立版项目骨架。

当前阶段是资产迁移与架构地基阶段，不包含完整玩法实现，也不迁移任何真实资产。

当前原则：

- TruthMap 记录真实地图。
- IntelMap 记录玩家已知情报。
- UI 只读取 ViewModel，例如 MiniMapViewModel。
- UI 不得直接读取 TruthMap。

后续资产必须登记到 `data/assets/asset_manifest.csv`，再进入 Godot 项目目录。
