# 通用时间数据查询场景与复现

## 目的

本场景证明库并非只服务馆藏字段。相同 API 同时处理科研观测、产品年份、项目区间、
事件索引和 API 脏数据。示范值用于可复现验收，不冒充真实生产数据。

## 运行

```sh
moon run examples/temporal-query --target wasm
moon run examples/temporal-query --target wasm-gc
moon run examples/temporal-query --target js
moon run examples/temporal-query --target native
```

查询窗为 `2024-05-01` 至 `2024-05-31`，策略为
`IncludePossibleOverlap`。预期摘要固定为：selected 2、invalid 1、needs-review 1、
outside 1、within 1、possible-overlap 1。

`sensor-17` 的精确日期确定落入窗口；`release-9` 只知道 2024 年，因此其安全包络可能
与窗口相交；`grant-2` 确定在窗口之前；`event-4` 带不确定标记，因缺少可证明的数值
边界转人工复核；`api-bad` 是不存在的日期并返回语法错误。

## 批量验收

`temporal_test.mbt` 构造 10,000 条循环混合记录，执行同一路径并断言：

- 每条输入均有 finding，不因解析错误丢行；
- invalid、needs-review、outside、within、possible-overlap 各 2,000；
- 召回优先策略选中 within 与 possible-overlap，共 4,000；
- 严格策略只选择 within；
- 安全 coverage 不吸收无法可靠计算边界的记录。

该测试验证确定性与批量完整性，不将 CI 用时冒充严格性能基准。
