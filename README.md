# Moon EDTF

[![CI](https://github.com/yyqdbngt/moon-edtf/actions/workflows/ci.yml/badge.svg)](https://github.com/yyqdbngt/moon-edtf/actions/workflows/ci.yml)

纯 MoonBit 实现的 EDTF（Extended Date/Time Format）**明确子集**解析库。核心目标是保留日期的不确定/近似/掩码语义，而不是把“约 1984 年”擅自变成某个精确时间戳。

## 目标

- 解析并校验一组严格限定的 EDTF 日期、日期时间、区间和集合/选择。
- 内部表示区分精确值、uncertain、approximate、both、masked/unspecified、open/unknown 端点。
- 对批量输入给出 valid/invalid、稳定错误码、原始 UTF-16 偏移和规范化输出。
- 为馆藏元数据导入提供保守日期包络与批量时间窗审计，无法安全判断的记录交人工复核。
- 零第三方依赖，仅使用 `moonbitlang/core` 基础包。

## 安装与使用

开发验证版本：MoonBit `0.1.20260904`，Node.js 24（CI 使用）。

```sh
git clone https://github.com/yyqdbngt/moon-edtf.git
cd moon-edtf
moon run examples/basic --target js
```

MoonCakes `0.1.0` 已发布；本仓库 `0.2.0` 在完成本轮 CI 后发布。当前新版能力请先从
GitHub 源码运行，不能把旧包当作新代码。发布状态见[申报前技术事实清单](docs/applicant-notes.md)。
库 API 契约见 [README.mbt.md](README.mbt.md)。在 `moon.pkg` 中导入：

```text
import {
  "yyqdbngt/moon_edtf" @edtf,
}
```

```moonbit nocheck
///|
fn main {
  let value = try! @edtf.parse("1984?")
  println(value.to_string()) // 1984?
}
```

本仓库包含可运行示例：

```sh
moon run examples/basic --target wasm
moon run examples/basic --target wasm-gc
moon run examples/basic --target js
moon run examples/basic --target native
moon run examples/catalog-audit --target js
```

## 验证

```sh
moon fmt --check
moon check --target wasm --deny-warn
moon check --target wasm-gc --deny-warn
moon check --target js --deny-warn
moon build --target wasm --deny-warn
moon build --target wasm-gc --deny-warn
moon build --target js --deny-warn
moon test --target wasm --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target js --deny-warn
moon run examples/basic --target wasm
moon run examples/basic --target wasm-gc
moon run examples/basic --target js
moon run examples/catalog-audit --target js
```

`native` 由 CI 覆盖；如果本地旧 C 编译器不可用，可跳过本地 native 验证。

## 支持的 EDTF 子集

| 能力 | 示例 | 说明 |
| --- | --- | --- |
| 精确日期 | `1984`、`1984-06`、`1984-06-15` | 支持负年份和大于四位年份 |
| 长年份 | `Y10000`、`Y-10000`；普通负年 `-0999` | 超过四位必须加 `Y`；最多 9 位数字 |
| 季节 | `1984-21` 至 `1984-24` | 作为文档化扩展；季节不接日 |
| 不确定 | `1984?` | 保留为 uncertain |
| 近似 | `1984~` | 保留为 approximate |
| 不确定且近似 | `1984%` | 保留为 both |
| 后缀修饰 | `1984?-06-11`、`1984-06?`、`1984-06-11?` | 作用于所在组件及其左侧所有组件 |
| 掩码位 | `199X`、`19XX` | 不变成 `1990` 或 `1900` |
| 未指定月/日 | `2004-XX`、`1985-04-XX`、`1985-XX-XX` | 保留缺失精度，不接受掩码年再接月 |
| 日期时间 | `1985-04-12T23:20:30Z`、`...-04`、`...+04:30` | 只接受完整精确日期与 HH:MM:SS；保留本地/UTC/偏移写法 |
| 区间 | `2004-01-01/2005` | 两个端点独立表示 |
| 开放端点 | `../1984`、`1984/..` | `..` 表示无界（Open） |
| 未知端点 | `1984/`、`/1984` | 空侧表示 Unknown，保留为空 |
| 选择集合 | `[1667,1668]`、`[1667,1668,1670..1672]` | 表示其中一个成员；`a..b` 保留为 Range，不改成 `a/b` |
| 全部成员集合 | `{1667,1668,1670..1672}` | 与方括号选择集合在模型中区分 |
| 批量诊断 | `diagnose_batch([...])` | 不抛异常，返回逐条结果 |
| 保守包络 | `date_envelope` / `window_relation` | 只表示可能覆盖的外边界；可能重叠不等于实际命中 |
| 馆藏批量审计 | `audit_catalog` | 有效、格式错误、人工复核、窗口外/内/可能相交分类 |
| 有限比较 | 两个完整、无修饰、精确日期 | 其他情况显式拒绝 |

精确年份按格里高利规则校验月/日。掩码年份限四位、末尾一或两位 X；
掩码年份只支持单独的年份表达式；`19XX-02-29` 不在支持子集内。月/日 `XX` 只在上表
列出的右侧未指定形式出现。

## 实际工作流：馆藏日期字段筛查

`examples/catalog-audit` 用 Library of Congress EDTF / RDA 公开示例的写法组成 6 条
**示范记录**（记录 ID 与批次是示范数据，不冒称真实馆藏记录），查询 1985 年 4 月。
四目标输出一致：1 条窗口内、1 条可能重叠、2 条窗口外、1 条格式错误、1 条需人工复核。
例如 `1985-04-XX` 是整个月，不变成 4 月 1 日；`1984?` 无法给出可靠边界，交人工；
`1984-02-30` 返回 `INVALID_DAY`。步骤与验收断言见
[场景测试](docs/catalog-scenario.md)。

## 明确不做

- 不做自然语言识别（如“circa 1984”“early 19th century”）。
- 不做完整历法/时间轴计算，不把 EDTF 展开成具体日期枚举或时间戳。
- 不宣称任何完整 EDTF 等级合规（包括 Level 0）：暂不支持时间、时区、扩展季节语法等。
- 不把 uncertain/approximate/masked 静默转成精确时间戳。
- 不支持科学计数年份、集合嵌套、集合中 open/unknown 端点。
- 不支持前置单组件修饰、集合内斜杠区间、单独 `..` 日期、时刻小数、闰秒或 24:00。
- 日期时间不做跨时区换算；保守包络不处理近似/不确定、季节、开放/未知端点或日期时间。
- 不提供 IO、CLI、网络、发布工具；示例仅演示 API。

## 与 brickfrog/tempo 等日期库的差异

`brickfrog/tempo` 等日期库通常面向精确日期/时间运算、格式化和时间线计算。本项目是相邻功能，不是替代品：Moon EDTF 专注于 EDTF 文本子集的解析、保留不确定语义和批量诊断，不尝试做完整日历计算或自然语言日期推理。

## 工程与来源

- [技术设计与支持矩阵](docs/design.md)
- [馆藏批量筛查场景测试](docs/catalog-scenario.md)
- [规范来源与查重说明](docs/provenance.md)
- [申报前技术事实清单](docs/applicant-notes.md)
- [项目申报书底稿](docs/proposal.md)（AI 辅助底稿，提交前由本人改写确认）
- [人工申报准备清单](docs/proposal-draft.md)（不是正式申报书）
- [版本记录](CHANGELOG.md)

代码、测试和文档由维护者使用 AI 编程辅助工具开发；参赛者需亲自理解、验证并撰写/改写申报材料。许可证：[Apache-2.0](LICENSE)。


