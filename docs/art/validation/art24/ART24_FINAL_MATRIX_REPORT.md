# ART24 最终分辨率矩阵报告

- 捕获器：`Godot/GraytailGodot/tests/art24_in_run_matrix_capture_runner.gd`
- 状态源：`art24_acceptance_state_matrix.csv`
- 分辨率：1280×720、1366×768、1600×900、1920×1080、2560×1440
- 结果：每档 54 张，共 270 张，全部返回 `PASS states=54`
- 本地原生 PNG 总量：301.05 MiB（315,671,841 bytes）
- 静态门禁：`python tools/validate_art24_in_run_final_ui.py --require-matrix` 返回 `PASS`

270 张原生 PNG 是可再生验收副产物，保留在当前工作树 `docs/art/validation/art24/matrix/final/` 供本地复核，不纳入 Git 提交，避免把 301 MiB 重复渲染结果永久写入仓库。提交保留状态矩阵、捕获器、验证器、审计记录与代表性返工截图；任意环境可按同一状态表重新生成并由验证器检查尺寸、数量和唯一性。

Computer Use 对五档真实 Godot 窗口均已启动检查；1920×1080 与 2560×1440 超出当前桌面可视区域，因此另在 Windows Photos 中适配显示同源原生全帧，核对四边、协议牌、左栏和底栏。详细记录见 `ART24_CU_FINAL_AUDIT.md`。
