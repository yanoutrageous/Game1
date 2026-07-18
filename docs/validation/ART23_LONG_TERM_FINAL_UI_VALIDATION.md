# ART23 长期系统最终美术 UI 验收记录

验收日期：2026-07-18

验收标准：`ART23-CU-FROZEN-2`（验收前已冻结）

Computer-Use: PASS

Matrix-Result: 27/27 PASS

分辨率矩阵：135/135 PASS
条件通过：禁止；本次结论为无条件通过。

## 最终结论

长期系统已达到“可交付的最终美术 UI”目标。最终轮从真实 `main.tscn` 主菜单进入，使用 Computer Use 逐页检查全部 6 个一级模块和 27 个二级页面；随后完成图鉴末端滚入、设置外观路由、收起/展开精确恢复、快速切换 latest-request-wins、键盘焦点与三级 Esc 返回链，以及连续 60 秒动效观察。最终轮开始后未再修改代码。

## 27 页逐项结果

| 一级模块 | 二级页面 | 结果 |
| --- | --- | --- |
| 目标 | `task` 任务 | PASS |
| 目标 | `achievement` 成就 | PASS |
| 目标 | `commission_record` 委托记录 | PASS |
| 图鉴 | `map` 地图 | PASS |
| 图鉴 | `monster` 怪物 | PASS |
| 图鉴 | `collectible` 藏品 | PASS |
| 图鉴 | `equipment` 装备 | PASS |
| 图鉴 | `consumable` 消耗品 | PASS |
| 图鉴 | `event` 事件 | PASS |
| 图鉴 | `rule` 规则 | PASS |
| 图鉴 | `lore` 世界观 | PASS |
| 研究 | `unlock_interface` 功能解锁接口 | PASS |
| 研究 | `research_entry` 研究入口 | PASS |
| 角色 | `qualification_level` 资历等级 | PASS |
| 角色 | `history` 历史战绩 | PASS |
| 角色 | `statistics` 数据统计 | PASS |
| 角色 | `milestone` 里程碑 | PASS |
| 角色 | `title` 称号 | PASS |
| 角色 | `badge` 徽章 | PASS |
| 抽奖 | `pool` 奖池 | PASS |
| 抽奖 | `cost` 消耗 | PASS |
| 抽奖 | `result_entry` 结果入口 | PASS |
| 收藏外观 | `unique_display` 唯一藏品展示 | PASS |
| 收藏外观 | `appearance_config` 外观配置 | PASS |
| 收藏外观 | `display_content` 展示内容 | PASS |
| 收藏外观 | `badge_title` 徽章称号 | PASS |
| 收藏外观 | `settlement_display` 结算展示 | PASS |

## Computer Use 交互与动效验收

- 真实入口：主菜单“长期系统”进入 `long_term_shell`，默认目标/任务内容正确。
- 图鉴：键盘移动至 `lore` 时页签自动滚入视野，没有 Godot 原生灰色滚动条。
- 档案：右侧角色档案在所有切页中固定；“设置外观”进入 `collection_appearance / appearance_config`。
- 收起/展开：收起后完整档案室背景可见，顶部模块和右侧档案保持固定；Esc 首次展开后精确恢复外观配置上下文。
- 快速切换：目标→图鉴→研究→目标连续请求后，最终家具、内容和选中模块均为目标，latest-request-wins 通过。
- 键盘层级：一级向下进入二级、再向下进入卡片；Esc 按卡片→二级→一级→主菜单顺序返回。
- 动效：连续观察 60 秒，角色常态、观察动作、眨眼/回归常态均可见；八张资源级帧参与循环，暖/蓝环境光和低密度粒子可见，正文与卡片未独立漂移。
- 字体：FusionPixel 仅用于短按钮、页签和短卡片标签；标题、说明、元信息、档案等级与统计使用 Noto Sans CJK SC Regular，未见缺字、锯齿发虚或过度描边。
- 风格连续：与 ART22 共用黑铁、深木、旧羊皮纸、暖金和青绿色选中语法；长期系统只增加“房间家具打开”的模块隐喻，没有切换成现代面板或另一套角色画风。

## 失败轮次与重验纪律

最终 PASS 之前的预验收曾依次发现并修复：透明容器拦截点击、外观配置收起后恢复到错误页面、图鉴占位出现英文 `Unknown`、Esc 卡片层级跳级，以及收起态 Esc 直接回主菜单。每次失败均按 `SAME_CRITERIA_FULL_RESTART` 终止当轮并全量重验；最后一项通过将取消输入从 `_unhandled_input` 提升到 `_input`、保留 600 ms 防抖而解决。

## 静态矩阵与资产契约

- 5 个分辨率（1280×720、1366×768、1600×900、1920×1080、2560×1440）各 27 页，共 135/135 个唯一截图状态。
- `long_term_screenshot_matrix.csv` 的 135 个 SHA-256 均唯一；保留 5 张联系表和 5 张原尺寸代表图。
- 58 个运行时纹理全部由 manifest 解析；默认解码 6.86 MiB、总解码 16.27 MiB，低于 8/18 MiB 门槛。
- 角色资源帧数 8；状态契约为 `OPEN,CLOSED,OPENING,CLOSING,SWITCHING`。
- 正文字体文件 SHA-256：`2C76254F6FC379FDDFCE0A7E84FB5385BB135D3E399294F6EEB6680D0365B74B`；manifest 许可状态为 `verified_ofl_1_1`。

## 判定

`ART23-CU-FROZEN-2` 所有阻断项均为 PASS，`ALL_6_PRIMARY_AND_27_SECONDARY_PAGES_OR_FAIL` 已满足。ART23 可以完成、提交并 push。
