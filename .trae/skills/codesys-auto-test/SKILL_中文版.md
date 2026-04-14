---
name: "codesys-auto-test"
description: "CODESYS MCP 自动化测试：部署 PLC 项目、采集变量、Web 监控验证。当用户需要进行 CODESYS 项目测试、PLC 部署、变量监控或完整集成测试时调用此技能。"
---

# CODESYS MCP 自动化测试技能

## 1. 测试环境配置

### 1.1 软件依赖

| 组件 | 版本 | 路径 |
|------|------|------|
| CODESYS IDE | 3.5.19.50 | `C:\Program Files\CODESYS 3.5.19.50\CODESYS\Common\CODESYS.exe` |
| CODESYS Profile | CODESYS V3.5 SP19 Patch 5 | 默认安装 |
| CODESYS Control Win V3 x64 | 3.5.19.50 | Windows 服务 |
| CODESYS Gateway V3 | 3.5.19.50 | Windows 服务 |
| Node.js | >= 16.x | Web 监控后端 |
| PowerShell | 5.1 | Windows 内置 |
| MCP Server | codesys-mcp v0.4.0 | `D:\Codesys-MCP-main\Codesys-MCP-main` |

### 1.2 目录结构

```
D:\Codesys-MCP-main\Codesys-MCP-Test\
├── templates\                          # 项目模板库
│   ├── template_registry.json          # 模板注册表 (UTF-8 无 BOM)
│   └── Accumulator_Rev1.0.0.260412.project  # 已验证的模板
├── projects\                           # 测试项目输出
├── scripts\                            # 自动化脚本
│   ├── Start-FullAutoDeploy.ps1        # 全自动部署入口
│   ├── deploy_and_collect.py           # CODESYS Python 脚本
│   ├── Collect-VariableData.ps1        # 独立数据采集
│   ├── New-ProjectFromTemplate.ps1     # 从模板创建项目
│   └── Run-IntegrationTest.ps1         # 集成测试套件
├── web-monitor\                        # Web 监控系统
│   ├── backend\
│   │   ├── server.js                   # Express + WebSocket 服务器
│   │   ├── package.json
│   │   └── data\                       # 采集的数据
│   │       ├── latest.json             # 最新采样
│   │       └── history.json            # 历史记录
│   └── frontend\
│       └── index.html                  # 响应式监控界面
└── .trae\skills\codesys-auto-test\     # 本技能
```

### 1.3 需要运行的 Windows 服务

| 服务名称 | 必须运行 |
|----------|----------|
| CODESYS Control Win V3 - x64 | 是 |
| CODESYS Gateway V3 | 是 |
| CODESYS ServiceControl | 是 |

### 1.4 MCP 脚本引擎已知问题

| 问题 | 根本原因 | 解决方案 |
|------|----------|----------|
| `online.create_online_application()` 返回"堆栈为空" | MCP watcher 使用 `exec()` 和自定义全局变量，CODESYS 内部状态不完整 | 使用 `--runscript` 直接执行而非 MCP `exec()` |
| `print(msg, flush=True)` TypeError | IronPython 不支持 `flush` 关键字 | 使用 `print(msg); sys.stdout.flush()` |
| JSON BOM 解析错误 | PowerShell `WriteAllText` 添加 UTF-8 BOM | 使用 `New-Object System.Text.UTF8Encoding $false` |
| `library_manager` 导入失败 | scriptengine 中不可用 | 使用 try/except 单独导入每个模块 |
| ScriptManager 缓存过期 | MCP 服务器缓存已加载的模板 | 在 `script-manager.ts` 中禁用缓存或重启 MCP |

---

## 2. 详细操作步骤

### 步骤 1: 确保 PLC 运行时服务正在运行

```powershell
# 检查并启动服务
$svc = Get-Service -Name "CODESYS Control Win V3 - x64"
if ($svc.Status -ne "Running") { Start-Service -Name "CODESYS Control Win V3 - x64" }

$gw = Get-Service -Name "CODESYS Gateway V3"
if ($gw.Status -ne "Running") { Start-Service -Name "CODESYS Gateway V3" }
```

**验证**: `Get-Service -Name "CODESYS*" | Select-Object Name, Status` — 所有服务应显示 "Running"

### 步骤 2: 启动 Web 监控后端

```powershell
cd D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend
node server.js
```

**验证**: 访问 http://localhost:3000 返回 HTTP 200

### 步骤 3: 全自动部署 + 运行 + 采集

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Start-FullAutoDeploy.ps1"
```

此单一命令执行：
1. 确保 PLC 运行时和 Gateway 服务正在运行
2. 关闭现有 CODESYS 实例
3. 通过 `--runscript` 在 CODESYS 中打开项目
4. 编译项目 (隐含在 `login` 中)
5. 登录到 PLC 设备 (`onlineapp.login(OnlineChangeOption.Try, True)`)
6. 下载应用程序到 PLC
7. 启动 PLC 应用程序 (`onlineapp.start()`)
8. 以 500ms 间隔采集 20 个变量样本
9. 保存数据到 `latest.json` 和 `history.json`
10. 登出并关闭项目

**预期时长**: 30-60 秒

### 步骤 4: 通过 API 验证数据

```powershell
$data = Invoke-RestMethod -Uri "http://localhost:3000/api/variables/latest"
$data.samples[-1].values
```

**预期输出**:
```
PLC_PRG.nAccumulator: INT#<0-999>
PLC_PRG.nCycleCount:  DINT#0
PLC_PRG.bEnable:      TRUE
PLC_PRG.nStep:        INT#1
PLC_PRG.nMaxValue:    INT#1000
```

### 步骤 5: 运行集成测试套件

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Run-IntegrationTest.ps1"
```

**预期输出**: `ALL 10 TESTS PASSED!`

---

## 3. 关键验证点

### 3.1 PLC 程序验证

| 检查点 | 预期 | 如何验证 |
|--------|------|----------|
| 项目编译 | 0 错误, 0 警告 | `mcp_codesys_compile_project` |
| 登录成功 | 无异常 | `onlineapp.login()` 返回 |
| 应用程序状态 | `ApplicationState.run` | `onlineapp.application_state` |
| nAccumulator 递增 | 每个样本值增加 | 比较连续样本 |
| nAccumulator 在 1000 时重置 | nAccumulator 回到 0 | 长时间观察 |
| nCycleCount 递增 | 每次完整周期后 +1 | nAccumulator 重置后 |
| bEnable 控制累加 | 设置 FALSE 停止递增 | 写入 FALSE，观察 |

### 3.2 Web 监控验证

| 检查点 | 预期 | 如何验证 |
|--------|------|----------|
| 登录 API | 返回 token + role | POST /api/login |
| 模板 API | 返回模板列表 | GET /api/templates |
| 报警配置 API | 返回报警阈值 | GET /api/alarm-config |
| 最新数据 API | 返回样本数组 | GET /api/variables/latest |
| 历史 API | 返回历史记录 | GET /api/variables/history |
| CSV 导出 | 返回 CSV 文本 | GET /api/variables/export?format=csv |
| WebSocket 推送 | 连接时实时数据 | ws://localhost:3000/ws |
| 用户角色 | admin/operator/viewer | 使用不同凭据登录 |

### 3.3 集成测试检查清单 (10 项)

1. 模板注册表检查 — JSON 有效, templates > 0
2. 模板项目文件 — 文件存在, 大小 > 10KB
3. 项目目录 — 输出项目文件存在
4. Web 监控登录 — admin 登录返回 role=admin
5. 模板 API — 返回 >= 1 个模板
6. 报警配置 API — nAccumulator 报警阈值存在
7. 变量数据 API — 返回带有有效 PLC_PRG.* 值的样本
8. 用户权限 — viewer 登录返回 role=viewer
9. 前端文件 — index.html 包含正确的变量名
10. 后端服务器 — / 返回 HTTP 200

---

## 4. 测试工具和版本信息

### 4.1 使用的 MCP 工具

| MCP 工具 | 用途 | 备注 |
|----------|------|------|
| `create_project` | 从模板创建项目 | 使用 Standard.project 模板 |
| `create_pou` | 创建 PLC 程序 POU | 必须指定 type=Program, language=ST |
| `set_pou_code` | 设置 POU 声明和实现 | 声明/实现分开 |
| `create_gvl` | 创建全局变量列表 | 用于外部变量访问 |
| `compile_project` | 构建项目 | 部署前必须通过 |
| `connect_to_device` | 登录到 PLC | **已知问题**: 通过 MCP exec() 失败 |
| `read_variable` | 读取 PLC 变量 | 需要活动连接 |
| `write_variable` | 写入 PLC 变量 | 需要活动连接 |

### 4.2 直接 CODESYS 脚本执行 (推荐)

对于需要 `online.create_online_application()` 的操作，使用直接 `--runscript`:

```powershell
Start-Process -FilePath $CodesysExe -ArgumentList "--profile=`"$Profile`"", "--runscript=`"$ScriptPath`"" -NoNewWindow
```

这绕过 MCP 的 `exec()` 机制，在 CODESYS 主线程上下文中运行。

### 4.3 CODESYS Python 脚本模板

```python
# encoding:utf-8
from __future__ import print_function
import sys

def log(msg):
    print(msg)
    sys.stdout.flush()

try:
    if projects.primary:
        projects.primary.close()
    proj = projects.open(r"<PROJECT_PATH>")
    app = proj.active_application
    onlineapp = online.create_online_application(app)
    onlineapp.login(OnlineChangeOption.Try, True)
    if not onlineapp.application_state == ApplicationState.run:
        onlineapp.start()
    system.delay(500)
    val = onlineapp.read_value("PLC_PRG.nAccumulator")
    log("Value: %s" % val)
    onlineapp.logout()
    proj.close()
    log("SUCCESS")
except Exception as e:
    log("ERROR: %s" % str(e))
    sys.exit(1)
```

**IronPython 关键注意事项**:
- 不要使用 `print(msg, flush=True)` — 使用 `print(msg); sys.stdout.flush()`
- 不要使用 f-string — 使用 `%` 格式化
- 不要使用 `from scriptengine import *` — 直接使用全局对象 (`projects`, `online`, `OnlineChangeOption`, `ApplicationState`)
- 等待使用 `system.delay()`，不要使用 `time.sleep()`

---

## 5. 异常处理

### 5.1 PLC 服务未运行

**症状**: `login()` 失败或超时
**解决方案**:
```powershell
Start-Service -Name "CODESYS Control Win V3 - x64"
Start-Service -Name "CODESYS Gateway V3"
```

### 5.2 MCP 导致的"堆栈为空"错误

**症状**: 调用 `online.create_online_application()` 时 `SystemError: 堆栈为空。`
**根本原因**: MCP watcher 的 `exec()` 无法正确初始化 CODESYS 在线模块
**解决方案**: 使用 `--runscript` 直接执行而非 MCP 工具

### 5.3 CODESYS 进程冲突

**症状**: 脚本挂起或无法打开项目
**解决方案**:
```powershell
Get-Process -Name "CODESYS" | Stop-Process -Force
Start-Sleep -Seconds 3
```

### 5.4 JSON BOM 解析错误

**症状**: Node.js `JSON.parse` 在 template_registry.json 上失败
**根本原因**: PowerShell 写入文件时添加 UTF-8 BOM
**解决方案**:
```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

### 5.5 找不到变量名

**症状**: `read_value()` 返回"无效表达式"
**根本原因**: 变量路径与 POU 声明名称不匹配
**解决方案**: 验证 POU 使用 `PLC_PRG` 作为任务名称，变量名称完全匹配 (区分大小写)

### 5.6 MCP ScriptManager 缓存过期

**症状**: 修改后的脚本未生效
**根本原因**: `ScriptManager` 在内存中缓存已加载的模板
**解决方案**: 重启 MCP 服务器进程 (需要用户操作)

---

## 6. 版本历史

| 版本 | 日期 | 作者 | 变更 |
|------|------|------|------|
| Rev1.0.0.260412 | 2026-04-12 | TRAE AI | 初始版本 - 完整测试流程已记录 |
| | | | 修复 IronPython flush 问题 |
| | | | 修复 JSON BOM 问题 |
| | | | 记录 MCP exec() 限制 |
| | | | 创建全自动部署管道 |
| | | | Web 监控与 10 点集成测试 |

---

## 7. 快速参考命令

```powershell
# 全自动部署 + 采集 (一条命令)
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Start-FullAutoDeploy.ps1"

# 启动 web 监控
cd D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend; node server.js

# 运行集成测试
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Run-IntegrationTest.ps1"

# 检查 PLC 服务
Get-Service -Name "CODESYS*" | Select-Object Name, Status

# 检查最新数据
Invoke-RestMethod -Uri "http://localhost:3000/api/variables/latest" | ConvertTo-Json

# 终止卡住的 CODESYS
Get-Process -Name "CODESYS" | Stop-Process -Force
```
