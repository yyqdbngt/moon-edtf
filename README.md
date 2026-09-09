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
moon add yyqdbngt/moon_edtf@0.1.0
```

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
| 长年份 | `10000`、`-0999` | 精确年最多 9 位十进制数字 |
| 季节 | `1984-21` 至 `1984-24` | 作为文档化扩展；季节不接日 |
| 不确定 | `1984?` | 保留为 uncertain |
| 近似 | `1984~` | 保留为 approximate |
| 不确定且近似 | `1984%` | 保留为 both |
| 组件级修饰 | `1984?-06-11`、`1984-06?`、`1984-06-11?` | 修饰只作用于所在组件 |
| 掩码位 | `199X`、`19XX` | 不变成 `1990` 或 `1900` |
| 区间 | `2004-01-01/2005` | 两个端点独立表示 |
| 开放端点 | `../1984`、`1984/..`、`2004/..`、`1984/`、`/1984` | 空侧规范化为 `..` |
| unknown | `..` | 表示未知日期/值 |
| 集合/选择 | `[1667,1668]`、`[1667,1668,1670..1672]` | 集合内 `a..b` 规范化为区间 `a/b` |
| 批量诊断 | `diagnose_batch([...])` | 不抛异常，返回逐条结果 |
| 有限比较 | 两个完整、无修饰、精确日期 | 其他情况显式拒绝 |

月/日边界会校验；精确年份按格里高利闰年规则校验 `02-29`。掩码年份下无法判定闰年，因此 `XX-02-29` 只做 `01..31` 级基础校验，语义上保持不确定。

## 明确不做

- 不做自然语言识别（如“circa 1984”“early 19th century”）。
- 不做完整历法/时间轴计算，不把 EDTF 展开成具体日期枚举或时间戳。
- 不实现 EDTF 全部 Level 1/2：暂不支持时间、时区、扩展季节语法、`..` 之外的开放/未知组合等。
- 不把 uncertain/approximate/masked 静默转成精确时间戳。
- 不支持掩码月/日、科学计数年份、集合嵌套、集合中 open/unknown 端点。
- 不提供 IO、CLI、网络、发布工具；示例仅演示 API。

## 与 brickfrog/tempo 等日期库的差异

`brickfrog/tempo` 等日期库通常面向精确日期/时间运算、格式化和时间线计算。本项目是相邻功能，不是替代品：Moon EDTF 专注于 EDTF 文本子集的解析、保留不确定语义和批量诊断，不尝试做完整日历计算或自然语言日期推理。

## 工程与来源

- [技术设计与支持矩阵](docs/design.md)
- [规范来源与查重说明](docs/provenance.md)
- [申报前技术事实清单](docs/applicant-notes.md)
- [申报书草稿](docs/proposal-draft.md)
- [版本记录](CHANGELOG.md)

代码、测试和文档由维护者使用 AI 编程辅助工具开发；参赛者需亲自理解、验证并撰写/改写申报材料。许可证：[Apache-2.0](LICENSE)。

