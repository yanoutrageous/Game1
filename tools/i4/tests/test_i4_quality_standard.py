from __future__ import annotations

import re
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
STANDARD_PATH = (
    REPO_ROOT
    / "docs"
    / "20_product"
    / "I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md"
)
MATRIX_PATH = REPO_ROOT / "docs" / "00_governance" / "I4_REQUIREMENT_MATRIX.md"


def read_utf8(path: Path) -> str:
    raw = path.read_bytes()
    if raw.startswith(b"\xef\xbb\xbf"):
        raise AssertionError(f"{path} must be UTF-8 without BOM")
    return raw.decode("utf-8")


class I4QualityStandardGovernanceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.standard = read_utf8(STANDARD_PATH)
        cls.matrix = read_utf8(MATRIX_PATH)

    def test_standard_has_frozen_identity_and_normative_status(self) -> None:
        self.assertIn("文档状态：`ACTIVE / PRE-PASS NORMATIVE`", self.standard)
        self.assertIn("标准 ID：`I4-QA-FROZEN-1`", self.standard)
        self.assertIn("不存在“看起来大致可以”的条件通过", self.standard)

    def test_standard_contains_rule_schema_and_all_major_gates(self) -> None:
        required = [
            "## 1. 每条验收规则的完整结构",
            "## 2. 判定状态与证据隔离",
            "## 3. 几何模型：遮挡、裁切和间距如何判定",
            "### 3.5 边框带宽与层级",
            "## 4. 字体和文字栅格标准",
            "## 5. 信息完整性、密度和分栏标准",
            "## 6. 交互自然度和操作链标准",
            "## 8. 测试场与局内诊断面板标准",
            "## 9. 现有生产内容的验收范围",
            "#### 10.4.1 折叠小地图与展开地图的图层",
            "#### 10.4.2 房间阻挡与可见内容一一对应",
            "#### 10.4.3 右上协议安全区",
            "#### 10.4.4 左下物品簇的内容驱动密度",
            "#### 10.4.5 物品品质色与非颜色冗余",
            "#### 10.4.6 物品纹理与地面掉落",
            "## 11. 真实渲染捕获与人工视觉复核",
            "## 12. 存档、失败和复现标准",
            "### 12.1 验证存储收口",
            "## 14. 缺陷严重度与一票否决",
            "## 17. I4.7 边框收敛修复计划",
        ]
        for heading in required:
            with self.subTest(heading=heading):
                self.assertIn(heading, self.standard)

    def test_geometry_and_border_thresholds_are_explicit(self) -> None:
        required = [
            "`R`：控件分配矩形",
            "`S`：内容安全矩形",
            "`G`：字体实际墨迹矩形",
            "`V`：可见图形矩形",
            "`H`：输入命中矩形",
            "`F`：焦点轮廓矩形",
            "`P`：当前 ScrollContainer",
            "| 页面/羊皮纸最外层主框 | 16 逻辑像素 |",
            "| 主要工作区/详情/模态 | 8 逻辑像素 |",
            "| 常规卡片、摘要行、页签、按钮 | 4 逻辑像素 |",
            "| 紧凑步进器、标签、徽标 | 2 逻辑像素 |",
            "同一内容簇出现三层完整四边框",
        ]
        for rule in required:
            with self.subTest(rule=rule):
                self.assertIn(rule, self.standard)

    def test_information_density_and_debug_panel_thresholds_are_explicit(self) -> None:
        required = [
            "一行摘要的行高必须在 34–46 逻辑像素内",
            "摘要行间距为 4–8 逻辑像素",
            "至少 6 个单行决策项",
            "展开面板占 viewport 宽度不超过 28%，高度不超过 75%",
            "1280×720@100% 对内容普查的每一行全量捕获",
        ]
        for rule in required:
            with self.subTest(rule=rule):
                self.assertIn(rule, self.standard)

    def test_automated_capture_cannot_claim_visual_pass(self) -> None:
        self.assertIn("通过本节后状态只能是 `VISUAL_CANDIDATE`", self.standard)
        self.assertIn("逐张原图人工复核", self.standard)
        self.assertIn("截图不能替代本节", self.standard)

    def test_current_counterexample_is_registered(self) -> None:
        self.assertIn(
            "1F85061F1C90B1E6B3F673F8519399B8094FD2499B0F4004DB9BCEBD4C3E0C51",
            self.standard,
        )
        self.assertIn("disposition=VISUAL_FAIL", self.standard)

    def test_requirement_ids_are_unique_and_contiguous(self) -> None:
        ids = [int(value) for value in re.findall(r"^\| I4-R(\d{3}) \|", self.matrix, re.M)]
        self.assertEqual(ids, list(range(1, 51)))
        self.assertEqual(len(ids), len(set(ids)))

    def test_quality_requirements_preserve_fail_history_and_candidate_boundary(self) -> None:
        for requirement_id in range(31, 51):
            with self.subTest(requirement_id=requirement_id):
                self.assertIn(f"I4-R{requirement_id:03d}", self.matrix)
        self.assertRegex(
            self.matrix,
            r"\| I4-R036 \|[^\n]+\| `VISUAL_CANDIDATE` \|",
        )
        self.assertIn(
            "1F85061F1C90B1E6B3F673F8519399B8094FD2499B0F4004DB9BCEBD4C3E0C51",
            self.matrix,
        )
        for requirement_id in [42, 50]:
            with self.subTest(open_requirement=requirement_id):
                self.assertRegex(
                    self.matrix,
                    rf"\| I4-R{requirement_id:03d} \|[^\n]+\| `IMPLEMENTING` \|",
                )
        for requirement_id in [25, 38]:
            with self.subTest(visual_candidate_requirement=requirement_id):
                self.assertRegex(
                    self.matrix,
                    rf"\| I4-R{requirement_id:03d} \|[^\n]+\| `VISUAL_CANDIDATE` \|",
                )
        self.assertRegex(
            self.matrix,
            r"\| I4-R040 \|[^\n]+\| `TARGETED_PASS` \|",
        )
        self.assertRegex(
            self.matrix,
            r"\| I4-R029 \|[^\n]+\| `IMPLEMENTING` \|",
        )
        self.assertRegex(
            self.matrix,
            r"\| I4-R030 \|[^\n]+\| `TARGETED_PASS` \|",
        )

    def test_in_run_layer_collision_and_density_thresholds_are_explicit(self) -> None:
        required = [
            "| `cell_base` | 0 |",
            "| `semantic` | 20 |",
            "| `adjacent_badge` | 30 |",
            "| `focus_selection` | 40 |",
            "跨入相邻格的可见像素为",
            "交集面积除以",
            "`body_rect` 面积必须 ≥0.90",
            "safe_inset_each_side = max(measured_B_on_that_side + 6, 14)",
            "语义相邻对象之间出现连续空白带 >8 px",
            "承载框在负重行后",
            ">16 px 无语义内部空白",
        ]
        for rule in required:
            with self.subTest(rule=rule):
                self.assertIn(rule, self.standard)

    def test_rarity_palette_and_texture_failure_rules_are_explicit(self) -> None:
        for color in [
            "#D0D8E0",
            "#78DCAA",
            "#5FA5FF",
            "#BE78FF",
            "#FFC346",
            "#FA5F55",
            "#F6E079",
            "#A9B0AD",
        ]:
            with self.subTest(color=color):
                self.assertIn(color, self.standard)
        required = [
            "每通道",
            "`1/255`",
            "`ArtVisual`/`TextureRect` 节点存在不等于纹理存在",
            "正式内容的空纹理数为 0",
            "只剩光束而物品本体",
            "为空也为失败",
        ]
        for rule in required:
            with self.subTest(rule=rule):
                self.assertIn(rule, self.standard)

    def test_authority_documents_reference_the_standard(self) -> None:
        relative_standard = (
            "docs/20_product/I4_ENGINEERING_QUALITY_AND_ACCEPTANCE_STANDARD.md"
        )
        authority_files = [
            "AGENTS.md",
            "docs/50_stages/active/STAGE_INDEX.md",
            "docs/10_current/CURRENT_STATE.md",
            "docs/10_current/NEXT_ACTION.md",
            "docs/20_product/I4_PRODUCTION_INTERACTION_CONVERGENCE_CONTRACT.md",
            "docs/00_governance/I4_EXECUTION_LEDGER.md",
            "docs/00_governance/I4_REQUIREMENT_MATRIX.md",
            "docs/30_engineering/godot/I4_REPRODUCIBLE_PRODUCTION_VALIDATION_RUNBOOK.md",
            "docs/40_validation/VALIDATION_INDEX.md",
            "tools/i4/README.md",
        ]
        for relative_path in authority_files:
            with self.subTest(relative_path=relative_path):
                text = read_utf8(REPO_ROOT / relative_path)
                self.assertIn(relative_standard, text)

    def test_vague_pass_phrases_are_not_used_as_acceptance_rules(self) -> None:
        forbidden = [
            "清晰即可",
            "合理即可",
            "无明显问题即可",
            "大致通过",
            "看起来没问题就",
            "适当调整后通过",
        ]
        for phrase in forbidden:
            with self.subTest(phrase=phrase):
                self.assertNotIn(phrase, self.standard)


if __name__ == "__main__":
    unittest.main()
