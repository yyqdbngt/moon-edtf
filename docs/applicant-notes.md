# 申报前技术事实清单

本文件供申报人核对，不替代本人撰写的一页式申报书。

- 项目：[Moon EDTF](https://github.com/yyqdbngt/moon-edtf)，模块
  `yyqdbngt/moon_edtf`，Apache-2.0，运行依赖仅 `moonbitlang/core`。
- 当前仓库版本 `0.2.0`；MoonCakes `0.2.0` 已发布、未 yank，独立下载安装运行通过。
- 根目录生产 MoonBit 1,229 行 / 6 文件；测试 537 行 / 39 块。计数不含示例、文档。
- 解析支持 EDTF 明确子集：日期、日期时间、区间、掩码月日、择一/全部成员集合；
  稳定错误码与原始 UTF-16 偏移；保守外包络、时间窗和目录批量审计。
- wasm、wasm-gc、js、native 四后端本地各 39/39 通过；核心提交
  `26a15a1` 的 [CI 全绿](https://github.com/yyqdbngt/moon-edtf/actions/runs/35551811301)。
- 新版包归档 SHA-256 `c138c91748be410302af6faacf085a21ba1162530e31e3386cd4ab4fd68f1675`
  与公开注册表一致；独立消费项目输出 `within=1 review=1 invalid=1`。
- 六条示范元数据记录的场景结果为：窗口内 1、可能相交 1、窗口外 2、错误 1、
  人工复核 1；数据是标准公开示例的写法组合，**不是实际馆藏数据集**。
- 项目不宣称完整 EDTF 等级合规，不联网，不做自然语言识别、时区转换或精确的
  集合成员检索。`PossibleOverlap` 可有假阳性。

提交前本人应检查：GitHub 最新提交及作者、CI、MoonCakes 对应版本与独立消费测试、
申报书的本人理解段落，以及赛事表格里上传的是最新 Markdown 文件。
