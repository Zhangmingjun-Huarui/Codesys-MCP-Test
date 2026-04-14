# CODESYS MCP 自动化测试规范文档

**版本**: Rev1.0.0.260412
**日期**: 2026-04-12
**状态**: 已验证通过

---

## 1. 测试环境配置

### 1.1 软件依赖

| 组件 | 版本 | 路径 |
|------|------|------|
| CODESYS IDE | 3.5.19.50 | `C:\Program Files\CODESYS 3.5.19.50\CODESYS\Common\CODESYS.exe` |
| CODESYS Profile | CODESYS V3.5 SP19 Patch 5 | 默认安装 |
| CODESYS Control Win V3 x64 | 3.5.19.50 | Windows 服务 |
| CODESYS Gateway V3 | 3.5.19.50 | Windows 服务 |
| Node.js | >= 16.x | Web监控后端 |
| PowerShell | 5.1 | Windows 内置 |
| MCP Server | codesys-mcp v0.4.0 | `D:\Codesys-MCP-main\Codesys-MCP-main` |

### 1.2 必须运行的Windows服务

| 服务名称 | 状态要求 |
|---------|---------|
| CODESYS Control Win V3 - x64 | Running |
| CODESYS Gateway V3 | Running |
| CODESYS ServiceControl | Running |

启动命令：
```powershell
Start-Service -Name "CODESYS Control Win V3 - x64"
Start-Service -Name "CODESYS Gateway V3"
```

### 1.3 目录结构

```
D:\Codesys-MCP-main\Codesys-MCP-Test\
├── templates\                          # 项目模板库
│   ├── template_registry.json          # 模板注册表（UTF-8无BOM）
│   └── Accumulator_Rev1.0.0.260412.project
├── projects\                           # 测试项目输出
├── scripts\                            # 自动化脚本
│   ├── Start-FullAutoDeploy.ps1        # 全自动部署入口
│   ├── deploy_and_collect.py           # CODESYS Python脚本
│   ├── Collect-VariableData.ps1        # 独立数据采集
│   ├── New-ProjectFromTemplate.ps1     # 从模板创建项目
│   └── Run-IntegrationTest.ps1         # 集成测试套件
├── web-monitor\                        # Web监控系统
│   ├── backend\server.js               # Express + WebSocket
│   ├── backend\data\latest.json        # 最新采样数据
│   ├── backend\data\history.json       # 历史记录
│   └── frontend\index.html             # 响应式监控界面
└── .trae\skills\codesys-auto-test\     # SKILL文件
```

---

## 2. 详细操作步骤

### 步骤1：确保PLC运行时服务运行

```powershell
Get-Service -Name "CODESYS*" | Select-Object Name, Status
# 如有服务未运行：
Start-Service -Name "CODESYS Control Win V3 - x64"
Start-Service -Name "CODESYS Gateway V3"
```

**验证点**：所有CODESYS服务状态为 Running

### 步骤2：启动Web监控后端

```powershell
cd D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend
node server.js
```

**验证点**：访问 http://localhost:3000 返回 HTTP 200

### 步骤3：一键全自动部署+运行+采集

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Start-FullAutoDeploy.ps1"
```

此命令自动执行：
1. 检查并启动PLC运行时和网关服务
2. 关闭现有CODESYS实例
3. 通过 `--runscript` 打开项目
4. 编译项目（login时隐式执行）
5. 登录PLC设备 `onlineapp.login(OnlineChangeOption.Try, True)`
6. 下载应用到PLC
7. 启动PLC应用 `onlineapp.start()`
8. 以500ms间隔采集20个变量样本
9. 保存数据到 `latest.json` 和 `history.json`
10. 登出并关闭项目

**预期耗时**：30-60秒

### 步骤4：验证数据

```powershell
$data = Invoke-RestMethod -Uri "http://localhost:3000/api/variables/latest"
$data.samples[-1].values
```

**预期输出**：
```
PLC_PRG.nAccumulator: INT#<0-999的递增值>
PLC_PRG.nCycleCount:  DINT#0
PLC_PRG.bEnable:      TRUE
PLC_PRG.nStep:        INT#1
PLC_PRG.nMaxValue:    INT#1000
```

### 步骤5：运行集成测试套件

```powershell
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Run-IntegrationTest.ps1"
```

**预期输出**：`ALL 10 TESTS PASSED!`

---

## 3. 关键验证点

### 3.1 PLC程序验证

| 验证点 | 预期结果 | 验证方式 |
|--------|---------|---------|
| 项目编译 | 0错误0警告 | compile_project |
| 登录成功 | 无异常 | login()返回 |
| 应用状态 | ApplicationState.run | application_state |
| nAccumulator递增 | 每次采样值增加 | 对比连续采样 |
| nAccumulator到1000归零 | 归零后nCycleCount+1 | 长时间观察 |
| bEnable控制累加 | 设为FALSE停止递增 | 写入FALSE观察 |

### 3.2 Web监控验证

| 验证点 | 预期结果 | API |
|--------|---------|-----|
| 登录 | 返回token+角色 | POST /api/login |
| 模板列表 | >=1个模板 | GET /api/templates |
| 报警配置 | nAccumulator阈值 | GET /api/alarm-config |
| 最新数据 | 采样数组 | GET /api/variables/latest |
| 历史数据 | 历史记录 | GET /api/variables/history |
| CSV导出 | CSV文本 | GET /api/variables/export?format=csv |
| WebSocket推送 | 实时数据 | ws://localhost:3000/ws |
| 用户角色 | admin/operator/viewer | 不同凭据登录 |

### 3.3 集成测试清单（10项）

1. 模板注册表检查 — JSON有效，模板>0
2. 模板项目文件 — 文件存在，>10KB
3. 项目目录 — 输出项目文件存在
4. Web监控登录 — admin登录返回role=admin
5. 模板API — 返回>=1个模板
6. 报警配置API — nAccumulator报警阈值存在
7. 变量数据API — 返回含PLC_PRG.*值的样本
8. 用户权限 — viewer登录返回role=viewer
9. 前端文件 — index.html包含正确变量名
10. 后端服务器 — HTTP 200

---

## 4. 测试工具及版本

### 4.1 MCP工具

| 工具 | 用途 | 备注 |
|------|------|------|
| create_project | 从模板创建项目 | 使用Standard.project |
| create_pou | 创建PLC程序POU | 必须指定type=Program, language=ST |
| set_pou_code | 设置POU声明和实现 | 分开设置declaration/implementation |
| create_gvl | 创建全局变量列表 | 用于外部变量访问 |
| compile_project | 编译项目 | 部署前必须通过 |
| connect_to_device | 登录PLC | **已知问题**：通过MCP exec()失败 |
| read_variable | 读取PLC变量 | 需要活动连接 |
| write_variable | 写入PLC变量 | 需要活动连接 |

### 4.2 CODESYS Python脚本模板

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

**IronPython关键限制**：
- 禁止 `print(msg, flush=True)` — 使用 `print(msg); sys.stdout.flush()`
- 禁止 f-string — 使用 `%` 格式化
- 禁止 `from scriptengine import *` — 直接使用全局对象
- 使用 `system.delay()` 等待，不用 `time.sleep()`

---

## 5. 异常处理方案

### 5.1 PLC服务未运行

**现象**：`login()` 失败或超时
**方案**：
```powershell
Start-Service -Name "CODESYS Control Win V3 - x64"
Start-Service -Name "CODESYS Gateway V3"
```

### 5.2 MCP "堆栈为空" 错误

**现象**：`SystemError: 堆栈为空。`
**根因**：MCP watcher的 `exec()` 无法正确初始化CODESYS online模块
**方案**：使用 `--runscript` 直接执行，不通过MCP工具

### 5.3 CODESYS进程冲突

**现象**：脚本挂起或无法打开项目
**方案**：
```powershell
Get-Process -Name "CODESYS" | Stop-Process -Force
Start-Sleep -Seconds 3
```

### 5.4 JSON BOM解析错误

**现象**：Node.js `JSON.parse` 失败
**根因**：PowerShell写入文件时添加UTF-8 BOM
**方案**：
```powershell
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($path, $content, $utf8NoBom)
```

### 5.5 变量名未找到

**现象**：`read_value()` 返回"无效的表达式"
**根因**：变量路径与POU声明名称不匹配
**方案**：确认POU任务名为 `PLC_PRG`，变量名完全匹配（区分大小写）

### 5.6 MCP ScriptManager缓存过期

**现象**：修改的脚本不生效
**根因**：`ScriptManager` 在内存中缓存已加载的模板
**方案**：重启MCP服务器进程

---

## 6. 版本历史

| 版本 | 日期 | 变更内容 |
|------|------|---------|
| Rev1.0.0.260412 | 2026-04-12 | 初始版本 - 完整测试流程文档化 |

---

## 7. 快速参考命令

```powershell
# 一键全自动部署+采集
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Start-FullAutoDeploy.ps1"

# 启动Web监控
cd D:\Codesys-MCP-main\Codesys-MCP-Test\web-monitor\backend; node server.js

# 运行集成测试
powershell -ExecutionPolicy Bypass -File "D:\Codesys-MCP-main\Codesys-MCP-Test\scripts\Run-IntegrationTest.ps1"

# 检查PLC服务
Get-Service -Name "CODESYS*" | Select-Object Name, Status

# 查看最新数据
Invoke-RestMethod -Uri "http://localhost:3000/api/variables/latest" | ConvertTo-Json

# 终止卡住的CODESYS
Get-Process -Name "CODESYS" | Stop-Process -Force
```
