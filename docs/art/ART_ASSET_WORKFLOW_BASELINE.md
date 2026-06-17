# ART Asset Workflow Baseline

本文档是 ART-02 的仓库内边界镜像说明，用于记录 Base Docs、Base Art、Connection 和 Godot runtime assets 的职责边界。它不是第二套 source of truth，也不重复 Godot import 细则。

## 阶段结论摘要

### ART-00

- 资产治理需要区分设计来源、制作区、交接层和运行时资产。
- Godot runtime assets 不能直接从外部素材目录随意引用。
- 后续进入运行时的资产必须具备可追踪来源和明确导入流程。

### ART-00-R1

- `D:\AGAME1\Godot` 与 `D:\AGAME1\Godot\GraytailGodot` 更像空壳 / 半同步目录 / 错误工作目录。
- 真实 Godot 项目路径是 `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`。
- 外部空壳路径永久默认禁止写入，不作为真实项目路径，不复制、不清理、不修复、不迁移。

### ART-01

- Godot runtime assets 必须保持 manifest-backed。
- 资产 ID、导入规则、迁移计划和 T0 checklist 由 Godot 项目内文档承载。
- UI、业务逻辑和资产路径应保持解耦，不应硬编码运行时图片路径。

### ART-02

- `D:\AGAME1\Base Art` 建立为原始美术制作区 / staging 区。
- `D:\AGAME1\Connection` 建立为程序 / 美术交接层。
- 本阶段只建立规范、空目录、registry CSV header 和交接模板。
- 本阶段不放入真实图片，不复制 Base Docs，不导入 Godot，不修改 runtime assets、manifest、AssetCatalog、ContentDB、PresentationMapping、scripts 或 scenes。

## 当前路径边界

### Base Docs

`D:\AGAME1\Base Docs` 是设计资料和参考来源区域。本阶段不复制其中图片，不把它作为 runtime assets 来源直接接入 Godot。

### Base Art

`D:\AGAME1\Base Art` 是原始美术制作区。它可以保存 prompt、生成原图、候选图、筛选结果、切割工作文件、动效源文件和 runtime candidates。

Base Art 不等于 Godot runtime assets，不应被 Godot 自动导入，不应被 AssetCatalog 直接引用。进入运行时前，资产需要经过来源登记、评审、导出、manifest 注册和 Godot 导入流程。

### Connection

`D:\AGAME1\Connection` 是程序 / 美术交接层，不是资源池。

- `Connection\Program`：程序侧给美术侧的需求出口。
- `Connection\Art`：美术侧给程序侧的交付与反馈入口。

Connection 可放需求、状态、尺寸约束、visual key 建议、交付清单、候选状态、导入建议和验收反馈。Connection 不应堆放大批原图，不放 Godot runtime assets，不被 AssetCatalog 直接引用。

现有 `D:\AGAME1\Connection\Program\G24_LongTerm_Content_Framework_Art_Request.md` 是 Program 侧真实请求样例，不属于 runtime assets，不应覆盖、不重写、不移动、不重编码。

### 仓库 assets

`D:\AGAME1\_repo_cache\Game1_work\assets` 不是本阶段写入目标。本阶段不向仓库 assets 放入图片或候选资产。

### Godot runtime assets

真实 Godot 项目位于 `D:\AGAME1\_repo_cache\Game1_work\Godot\GraytailGodot`。其中 runtime assets、manifest、data、scripts 和 scenes 均不属于 ART-02 写入范围。

Godot runtime assets 必须通过 manifest-backed 流程接入。后续导入应遵守 Godot 项目内的资产导入、命名、迁移和 checklist 文档。

### 外部 Godot 空壳路径

`D:\AGAME1\Godot` 与 `D:\AGAME1\Godot\GraytailGodot` 禁止写入。它们不作为真实项目路径，不参与本阶段任何复制、清理、修复或迁移。

## ART-02 产物

### Base Art

- `README.md`：原始美术制作区规范。
- `_registry\source_registry.csv`：来源登记 header。
- `_registry\generation_log.csv`：生成记录 header。
- `_registry\review_status.csv`：候选审查 header。
- `_registry\export_manifest.csv`：导出候选 header。
- `00_prompts` 到 `99_rejected_or_archive`：空目录结构，用于后续分类存放。

### Connection

- `README.md`：交接层总说明。
- `Program\README.md`：程序侧需求出口说明。
- `Program\ART_PROGRAM_HANDOFF_TEMPLATE.md`：程序到美术交接模板。
- `Program\ART_CURRENT_STATUS.md`：当前 ART 程序侧状态说明。
- `Art\README.md`：美术侧交付反馈入口说明。
- `Art\ART_DELIVERY_TEMPLATE.md`：美术交付模板。
- `Art\ART_REVIEW_FEEDBACK_TEMPLATE.md`：美术审查反馈模板。

## 后续依赖

### ART-03

ART-03 可在 Base Art registry 和 Connection 模板基础上，开始登记真实 prompt、生成结果或候选来源，但仍需保持授权、来源和用途可追踪。

### ART-04

ART-04 可在候选资产通过评审后，规划 runtime candidates 到 Godot manifest-backed 导入的试点流程。导入前仍需确认尺寸、命名、透明背景、fallback policy、asset_id 和 visual key 映射。

