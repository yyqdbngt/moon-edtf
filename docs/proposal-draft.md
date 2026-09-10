# Moon EDTF — 人工申报准备清单

> AI 辅助技术资料，不是可提交的项目申报书。请参赛者独立撰写一页 Markdown；
> 不能删除提示后将本文件冒充本人撰写。无需 PDF。

- 名称 / 仓库：[Moon EDTF](https://github.com/yyqdbngt/moon-edtf)。
- 方向 / 需求：历史日期数据清洗基础库，保留不确定、近似、掩码和日期精度。
- 核心：明确 EDTF 子集解析、日历检查、规范化、批量诊断；区分 Unknown/Open；保留选择集合 Range。
- 路线：UTF-16 游标递归下降、类型化模型、语义往返测试和四目标 CI。
- 不做：自然语言识别、完整 EDTF 等级合规、时间/时区、完整日历运算、掩码月日、花括号全成员集合。

## 场景事实（请本人结合实际使用者写完整）

1. 档案目录导入 → 输入 1984? 或 19XX → parse/normalize 校验并保留不确定性 → 非法记录带错误偏移退回，不补成精确年月日。
2. 博物馆藏品年代 → 人工先将年代描述转换为受支持 EDTF → 批量诊断 → 输出规范化值与错误清单；本库不负责自然语言转换。
3. 科研日期质量检查 → 输入含未知/开放端点和选择年份的记录 → diagnose_batch → 保留空端点与双点的区别；不将选择范围改成持续区间。

## 来源、差异与交付核对

独立 MoonBit 实现，Apache-2.0；规范参考 [Library of Congress EDTF](https://www.loc.gov/standards/datetime/)。
未移植第三方解析器；工程结构参考 [Moon JSON Repair](https://github.com/btlqql/moon-json-repair)
（Apache-2.0），未复制其功能逻辑。详细来源见 [provenance](provenance.md)。
与精确日期库相邻，不替代它们；不声称首个或唯一 EDTF 库。

已具备源码、README、示例、测试、CI、许可证；发布状态需单独确认。
请本人补充动机、亲自完成的工作、方案理解与交付计划，解释为何不能任意排序部分日期。
按 [赛事核对表](submission-checklist.md) 检查后，由对应参赛者本人提交。
