# Moon EDTF

[![CI](https://github.com/yyqdbngt/moon-edtf/actions/workflows/ci.yml/badge.svg)](https://github.com/yyqdbngt/moon-edtf/actions/workflows/ci.yml)

纯 MoonBit 实现的 EDTF（Extended Date/Time Format）**明确子集**解析库。核心目标是保留日期的不确定/近似/掩码语义，而不是把“约 1984 年”擅自变成某个精确时间戳。

## 目标

- 解析并校验一组严格限定的 EDTF 日期、区间和集合/选择。
- 内部表示区分精确值、uncertain、approximate、both、masked/unspecified、open/unknown 端点。
- 对批量输入给出 valid/invalid、稳定错误码、原始 UTF-16 偏移和规范化输出。
- 零第三方依赖，仅使用 `moonbitlang/core` 基础包。

## 安装与使用

开发验证版本：MoonBit `0.1.20260904`，Node.js 24（CI 使用）。

```sh
git clone https://github.com/yyqdbngt/moon-edtf.git
cd moon-edtf
moon run examples/basic --target js
```

本页不代表 MoonCakes 已发布。发布确认后，消费项目可运行
`moon add yyqdbngt/moon_edtf@0.1.0`。
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
| 区间 | `2004-01-01/2005` | 两个端点独立表示 |
| 开放端点 | `../1984`、`1984/..` | `..` 表示无界（Open） |
| 未知端点 | `1984/`、`/1984` | 空侧表示 Unknown，保留为空 |
| 选择集合 | `[1667,1668]`、`[1667,1668,1670..1672]` | 表示其中一个成员；`a..b` 保留为 Range，不改成 `a/b` |
| 批量诊断 | `diagnose_batch([...])` | 不抛异常，返回逐条结果 |
| 有限比较 | 两个完整、无修饰、精确日期 | 其他情况显式拒绝 |

精确年份按格里高利规则校验月/日。掩码年份限四位、末尾一或两位 X；
`19XX-02-29` 保留不确定性，仍拒绝 `19XX-02-30`、`19XX-04-31`。

## 明确不做

- 不做自然语言识别（如“circa 1984”“early 19th century”）。
- 不做完整历法/时间轴计算，不把 EDTF 展开成具体日期枚举或时间戳。
- 不宣称任何完整 EDTF 等级合规（包括 Level 0）：暂不支持时间、时区、扩展季节语法等。
- 不把 uncertain/approximate/masked 静默转成精确时间戳。
- 不支持掩码月/日、科学计数年份、集合嵌套、集合中 open/unknown 端点。
- 不支持花括号全成员集合、前置单组件修饰、集合内斜杠区间、单独 `..` 日期。
- 不提供 IO、CLI、网络、发布工具；示例仅演示 API。

## 与 brickfrog/tempo 等日期库的差异

`brickfrog/tempo` 等日期库通常面向精确日期/时间运算、格式化和时间线计算。本项目是相邻功能，不是替代品：Moon EDTF 专注于 EDTF 文本子集的解析、保留不确定语义和批量诊断，不尝试做完整日历计算或自然语言日期推理。

## 工程与来源

- [技术设计与支持矩阵](docs/design.md)
- [规范来源与查重说明](docs/provenance.md)
- [申报前技术事实清单](docs/applicant-notes.md)
- [人工申报准备清单](docs/proposal-draft.md)（不是正式申报书）
- [版本记录](CHANGELOG.md)

代码、测试和文档由维护者使用 AI 编程辅助工具开发；参赛者需亲自理解、验证并撰写/改写申报材料。许可证：[Apache-2.0](LICENSE)。

