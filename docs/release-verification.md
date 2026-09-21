# MoonCakes 0.2.0 发布与独立消费验证

日期：2026-09-21。模块：`yyqdbngt/moon_edtf`。源码提交：`26a15a1`；
[该提交的四目标 CI 全绿](https://github.com/yyqdbngt/moon-edtf/actions/runs/35551811301)。

## 发布与注册表

使用 yyqdbngt 登录配置在源码目录运行 `moon publish --frozen`：包内解压重检
`moon check` 通过，服务端返回 `200 OK`。公开
[MoonCakes 注册表 API](https://mooncakes.io/api/v0/modules/yyqdbngt/moon_edtf)
返回 `version: 0.2.0`、`latest_version: 0.2.0`、`yanked: false`、
`build_status: success`，仓库地址为本项目 GitHub。

注册表 `metadata.checksum`：

```text
c138c91748be410302af6faacf085a21ba1162530e31e3386cd4ab4fd68f1675
```

## 独立下载安装与运行

在 D 盘新建 `probe/edtftest` 模块，与项目仓库隔离，运行：

```text
$ moon update
Registry index updated successfully
$ moon add yyqdbngt/moon_edtf@0.2.0
Downloading yyqdbngt/moon_edtf@0.2.0
```

下载缓存归档为 39,862 字节，其本地 SHA-256 是上文的
`c138c91748be410302af6faacf085a21ba1162530e31e3386cd4ab4fd68f1675`，
与公开注册表逐字节一致。消费者的 `moon.pkg` 导入
`"yyqdbngt/moon_edtf" @edtf`，实际调用新 API：

```moonbit
let rows = [
  @edtf.CatalogEntry::{ record_id: "A", edtf: "1985-04-XX", },
  @edtf.CatalogEntry::{ record_id: "B", edtf: "1984?", },
  @edtf.CatalogEntry::{ record_id: "C", edtf: "1984-02-30", },
]
let report = try! @edtf.audit_catalog(rows, "1985-04-01", "1985-04-30")
```

`moon run cmd/main --target js` 成功，关键输出：

```text
within=1 review=1 invalid=1
1985-04-12T23:20:30Z
```

第二行来自同一消费程序对新日期时间语法的解析。因此验证覆盖了**注册表下载、
依赖解析、编译和新版功能运行**，而不只是发布命令成功。此消费者为最小确定性
输入，不代替六条场景测试、1,000 条批量回归测试或真实馆藏数据集验证。
