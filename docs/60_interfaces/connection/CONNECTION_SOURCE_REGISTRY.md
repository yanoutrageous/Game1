# Connection Source Registry

文档状态：外部只读接口注册表
适用范围：`D:\AGAME1\Connection` 当前并行交接文件的路径与只读观测
最后更新：2026/06/23
只读观测时间：2026/06/23

本注册表不保存 Connection 内容副本。路径、时间和 SHA256 只证明一次只读观测，不表示内容批准、任务授权或验收通过。

| lane | file | current_external_path | last_write | observed_sha256 | status |
| --- | --- | --- | --- | --- | --- |
| root | `README.md` | `D:\AGAME1\Connection\README.md` | `2026-06-17 12:00:25` | `542C9DF851108B8EB24BD4D13B6D89F2996B2F1DAE22C0F6EA54091C0E792542` | connection_external_only |
| Art | `ART_DELIVERY_TEMPLATE.md` | `D:\AGAME1\Connection\Art\ART_DELIVERY_TEMPLATE.md` | `2026-06-17 12:00:25` | `964960F0DD9D3200183F2D96D1A440520AFBF224B4D79A7977710E143EBA70DE` | connection_external_only |
| Art | `ART_REVIEW_FEEDBACK_TEMPLATE.md` | `D:\AGAME1\Connection\Art\ART_REVIEW_FEEDBACK_TEMPLATE.md` | `2026-06-17 12:00:25` | `6F2492AB9C61B0D5F27212C1AF553EAFE20A4F62E57CEF8A663464512690212B` | connection_external_only |
| Art | `README.md` | `D:\AGAME1\Connection\Art\README.md` | `2026-06-17 12:00:25` | `BB8F03A0232AF9EFDDFCADF7732AB3492268EE05005A426035B139180C2EBD58` | connection_external_only |
| Program | `ART_CURRENT_STATUS.md` | `D:\AGAME1\Connection\Program\ART_CURRENT_STATUS.md` | `2026-06-17 12:00:25` | `E75D7F0D31E970BD0FF8E0D3C0A68F6F0FA7029B445C2C4D8E95770FDAEA23A0` | connection_external_only |
| Program | `ART_PROGRAM_HANDOFF_TEMPLATE.md` | `D:\AGAME1\Connection\Program\ART_PROGRAM_HANDOFF_TEMPLATE.md` | `2026-06-17 12:00:25` | `D0974C80F1EA85280D71E1015C0A3B2858637F797A3DD8E5F92441DA18251B29` | connection_external_only |
| Program | `ART03_Program_Visual_Interface_Handoff.md` | `D:\AGAME1\Connection\Program\ART03_Program_Visual_Interface_Handoff.md` | `2026-06-22 15:23:06` | `C3286AEEC9F3194D4350FEABD823F874BCF41EE559AC1CD180C39A0BBC6406A7` | connection_external_only |
| Program | `G24_LongTerm_Content_Framework_Art_Request.md` | `D:\AGAME1\Connection\Program\G24_LongTerm_Content_Framework_Art_Request.md` | `2026-06-17 11:43:35` | `5226A6200A568CAA1FC666467F56F5B25438EC4DB067C4E13C10DAE37551B3A3` | connection_external_only |
| Program | `G25_UI_Structure_Stabilization_Notice.md` | `D:\AGAME1\Connection\Program\G25_UI_Structure_Stabilization_Notice.md` | `2026-06-17 15:18:34` | `AF6AC73BD7B3FF6A56E6BB8B6C536A0B5F50B02C9265C2076104C6A58E8C4A5D` | connection_external_only |
| Program | `README.md` | `D:\AGAME1\Connection\Program\README.md` | `2026-06-17 12:00:25` | `D959F7488DD0D099A0E50175D8D2CE329BBF158EB6655CC10F3AF87AD6C18C87` | connection_external_only |

`D:\AGAME1\Connection\Planning` 在本次观测时为空目录；这不是 blocker，也不限制并行工作流后续写入。

## 使用边界

```text
1. Planning / Program / Art 原始交接资料不直接作为策划定案。
2. Connection 内容只能作为外部接口交接信息或待确认事项。
3. Connection 文件不得复制或提交到 Git，不得作为 Godot 资源导入。
4. 若需将交接资料转为正式策划或工程任务，必须另起确认流程。
5. 不写入、不清理、不回滚、不移动、不覆盖 Connection。
```
