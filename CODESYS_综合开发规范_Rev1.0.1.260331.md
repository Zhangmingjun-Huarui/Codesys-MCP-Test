# CODESYS综合开发规范

## 文档信息

- **文档名称**: CODESYS综合开发规范
- **版本**: Rev1.0.0.260316
- **创建时间**: 2026年3月16日
- **适用对象**: CODESYS开发工程师、代码审查人员、质量保证人员
- **核心目的**: 统一代码风格，提高代码质量，便于维护，提供系统化检查流程
- **适用范围**: 所有CODESYS开发场景

## 一、架构设计原则

### 1.1 模块化设计

- 程序按功能拆分成FB（功能块）、FUN（函数）、PRG（程序）、GVL（全局变量表）
- 单一职责：每个功能块只负责一个明确功能
- 公共功能抽象成库，避免代码重复

### 1.2 分层架构（五层模型）

```
应用层：参数管理、故障处理、诊断记录
控制层：逻辑控制、算法处理、状态机
处理层：信号滤波、数据转换、信号处理
接口层：IO输入、IO输出、通讯接口
驱动层：硬件驱动、初始化、系统配置
```

## 二、命名规范（强制遵守）

### 2.1 匈牙利命名法前缀

| 数据类型   | 前缀     | 示例                          |
| ------ | ------ | --------------------------- |
| BOOL   | x      | xRunning, xEnable           |
| SINT   | si     | siTemperature               |
| USINT  | usi    | usiCounter                  |
| INT    | i      | iPosition                   |
| UINT   | ui     | uiSpeed                     |
| DINT   | di     | diTotalCount                |
| UDINT  | udi    | udiTimeout                  |
| REAL   | r      | rPressure                   |
| LREAL  | lr     | lrPrecisionValue            |
| STRING | s      | sProductName                |
| TIME   | tim    | timCycleTime                |
| DATE   | date   | dateProductionDate          |
| ENUM   | e      | eSystemStatus               |
| STRUCT | stru   | struMotorParameters         |
| ARRAY  | ar     | arTemperatureValues REAL型数组 |
| ARRAY  | aw     | awTemperatureValues WORD型数组 |
| ARRAY  | ax     | axTemperatureValues BOOL型数组 |
| 以此类推   | <br /> | <br />                      |

### 2.2 POU命名规范

- **PROGRAM**: `PRG_` + 功能描述（如 `PRG_MainControl`）
- **FUNCTION BLOCK**: `FB_` + 设备/功能描述（如 `FB_MotorController`）
- **FUNCTION**: `FUN_` + 功能描述（如 `FUN_CalculateAverage`）

### 2.3 命名基本原则

- 统一使用英文，禁止拼音与英文混用
- 命名要准确表达变量或函数的用途
- 尽量不使用缩写，确需使用时要统一

### 2.4 版本命名规范

- **项目命名**: `项目名_Rev主版本.次版本.修订号.日期.project`
- **POU命名**: 建议包含版本号，如 `PRG_MainControl_Rev0.0.1.260315`

## 三、代码格式规范

### 3.1 基本格式要求

- **缩进**: 使用Tab字符，不使用空格
- **换行**: 每个语句独占一行
- **行长度**: 每行代码不超过120个字符
- **空行**: 不同逻辑块之间用空行分隔

### 3.2 空格使用规范

- 运算符前后：二元运算符前后各一个空格
- 括号内部：括号内部不使用空格
- 逗号后面：逗号后面使用一个空格
- 分号后面：分号后面不使用空格（除非换行）

### 3.3 控制结构格式

```st
// IF语句格式
IF xCondition THEN
    // 执行语句
END_IF;

// IF-ELSE语句
IF xCondition1 THEN
    // 执行语句1
ELSIF xCondition2 THEN
    // 执行语句2
ELSE
    // 执行语句3
END_IF;

// CASE语句格式
CASE eVariable OF
    VALUE1:
        // 处理VALUE1
    VALUE2, VALUE3:
        // 处理VALUE2和VALUE3
    ELSE
        // 默认处理
END_CASE;
```

### 3.4 变量声明格式

```st
VAR
    // 系统状态变量
    xSystemReady        : BOOL := FALSE;    // 系统准备完成
    xSystemFault        : BOOL := FALSE;    // 系统故障
    eSystemMode         : T_SystemMode := T_SystemMode.Manual;  // 系统模式
    
    // 控制变量
    rTemperatureSetpoint : REAL := 25.0;    // 温度设定点
    rPressureSetpoint    : REAL := 5.0;     // 压力设定点
    xControlEnable       : BOOL := FALSE;   // 控制使能
END_VAR
```

## 四、注释规范

### 4.1 注释语言要求

- **常规开发**: 支持中文字符注释，便于中文开发者阅读

### 4.2 POU头部注释（必须包含）

```st
// 功能块：FB_MotorController
// 功能：实现电机的启停控制、转速调节及故障保护（过流、过热）
// 输入：xEnable（使能），rTargetSpeed（目标转速），xEmergencyStop（急停）
// 输出：xIsRunning（运行状态），xFault（故障），eFaultCode（故障代码），rActualSpeed（实际转速）
// 版本：Rev0.0.1.260315
// 作者：开发人员姓名
// 修改记录：
// Rev0.0.1.260315 - 初始版本，实现基本功能
FUNCTION_BLOCK FB_MotorController
```

### 4.3 代码注释要求

- **简洁明了**: 用简洁的语言表达清楚含义
- **必要充分**: 只注释必要的信息，避免冗余
- **及时更新**: 代码修改时要同步更新注释
- **统一格式**: 遵循统一的注释格式

### 4.4 注释类型

- 头部注释：POU开头的功能说明
- 行内注释：单行代码的说明
- 块注释：代码块的功能说明

## 五、版本管理规范

### 5.1 版本号格式

- **格式**: `Rev主版本.次版本.修订号.日期`
- **示例**: `Rev0.0.1.260315` 表示2026年3月15日的第1次修订
- **位置**: 程序注释中

### 5.2 版本升级流程

1. **小修改**: Rev0.0.1 → Rev0.0.2（功能微调，bug修复）
2. **功能完善**: Rev0.0.2 → Rev0.1.0（测试确认功能完好后）
3. **重大更新**: Rev0.1.0 → Rev1.0.0（架构调整，重大功能增加）
4. **日期更新**: 每次修改更新日期部分

### 5.3 版本记录要求

- 每个POU文档中必须包含版本信息
- 必须记录变更日志，说明版本升级内容
- 版本升级后需要更新程序命名

### 5.4 版本管理错误预防

- **禁止直接修改**: 严禁在原程序上直接修改，必须创建新版本
- **版本备份**: 重要修改前必须备份当前版本
- **变更记录**: 每次修改必须记录变更内容和原因
- **版本验证**: 新版本必须通过编译验证和功能测试

## 六、数据类型与变量规范

### 6.1 数据类型选择原则

- 最小够用原则：选择能够满足需求的最小数据类型
- 一致性原则：相同功能的数据使用相同的数据类型
- 可读性原则：选择能够清晰表达数据含义的数据类型

### 6.2 常用数据类型选择

| 应用场景  | 推荐类型   | 说明                       |
| ----- | ------ | ------------------------ |
| 开关量信号 | BOOL   | 逻辑状态，TRUE/FALSE          |
| 小范围整数 | INT    | -32768 到 32767           |
| 无符号整数 | UINT   | 0 到 65535                |
| 大范围整数 | DINT   | -2147483648 到 2147483647 |
| 小数    | REAL   | 单精度浮点数                   |
| 高精度小数 | LREAL  | 双精度浮点数                   |
| 文本    | STRING | 字符串数据                    |
| 时间    | TIME   | 时间间隔                     |

### 6.3 自定义数据类型

```st
// 枚举类型（ENUM）
TYPE eMotorStatus:
(
    Stopped := 0,      // 停止状态
    Starting := 1,     // 启动中
    Running := 2,      // 运行中
    Stopping := 3,     // 停止中
    Fault := 4         // 故障状态
) INT;
END_TYPE

// 结构体类型（STRUCT）
TYPE struMotorParameters:
STRUCT
    rRatedPower: REAL;          // 额定功率 (kW)
    rRatedSpeed: REAL;          // 额定速度 (rpm)
    rMaxTorque: REAL;           // 最大扭矩 (Nm)
    uiMaxCurrent: UINT;         // 最大电流 (A)
    timStartupTime: TIME;       // 启动时间 (s)
    eMotorType: T_MotorType;    // 电机类型
END_STRUCT
END_TYPE
```

### 6.4 类型转换要求

必须使用显式类型转换函数：

- DINT转REAL: DINT\_TO\_REAL(diValue)
- REAL转DINT: REAL\_TO\_DINT(rValue)
- INT转REAL: INT\_TO\_REAL(iValue)

## 七、初始化规范

### 7.1 初始化基本原则

- 一次性执行：初始化代码只在系统启动时执行一次
- 状态检测：每个初始化步骤都要检测执行结果
- 错误处理：初始化失败要有相应的错误处理机制
- 状态记录：记录初始化状态，避免重复执行

### 7.2 初始化流程

1. 硬件初始化：CAN、IO等硬件接口初始化
2. 参数初始化：加载默认参数或保存的参数
3. 变量初始化：程序变量的初始值设置
4. 状态初始化：系统状态的初始设置
5. 自检：系统自检和诊断

## 八、错误预防机制

### 8.1 通用错误预防

1. **版本管理错误**: 严禁直接修改原程序，必须创建新版本
2. **编译错误**: 每次修改后必须编译验证
3. **CONCAT函数限制**: CODESYS中CONCAT函数只能连接2个字符串，连接多个字符串时需要使用嵌套CONCAT或中间变量

### 8.2 POU声明完整性规范

- **严禁删除POU声明部分**: 必须包含完整的PROGRAM/FUNCTION\_BLOCK声明
- **必须包含VAR部分**: 即使没有变量，也应包含空的VAR...END\_VAR结构
- **正确示例**:
  ```st
  // Program declaration with VAR section
  PROGRAM PRG_TestProgram
  VAR
      // Variables go here
  END_VAR
  ```

### 8.3 结构体声明位置规范

- **严禁在POU内部声明结构体**: TYPE...STRUCT...END\_TYPE不能在POU的VAR部分内声明
- **结构体必须在DataTypes目录下声明**: 在Application下创建DUT
- **正确示例**:
  ```st
  // Correct: DUT declared in Application
  TYPE MyStruct:
  STRUCT
      x: INT;
      y: BOOL;
  END_STRUCT
  END_TYPE
  ```

### 8.4 检查清单

- [ ] 确认修改前创建新版本
- [ ] 确认编译通过无错误
- [ ] 确认POU声明完整（PROGRAM/FUNCTION\_BLOCK声明和VAR部分）
- [ ] 确认结构体在DataTypes目录下声明，不在POU内部声明


#### 语法兼容性检查

- [ ] **指数运算**: 使用`EXPT`函数，而非`^`或`**`
- [ ] **数学函数**: LREAL返回值必须显式转换
- [ ] **枚举比较**: 使用完整枚举值比较
- [ ] **数组初始化**: 逐个元素赋值，不使用字面量
- [ ] **赋值与比较**: 使用正确运算符
- [ ] **逻辑运算符**: 使用CODESYS逻辑运算符

#### 定时器设计检查

- [ ] **时间计算**: 计数 = 目标时间(ms) ÷ 任务周期(ms)
- [ ] **变量类型**: 使用UINT类型，避免溢出
- [ ] **注释说明**: 代码中明确标注计算依据
- [ ] **任务同步**: 与任务配置interval设置保持一致

#### 变量声明检查

- [ ] **声明完整性**: 所有使用变量都已声明
- [ ] **类型匹配**: 变量声明类型与实际使用类型一致
- [ ] **循环变量**: FOR循环索引在localVars中声明
- [ ] **作用域正确**: 变量在正确的VAR区域声明

### 9.3 验证阶段（完成检查表）

- [ ] **编译验证**: 每次修改后必须编译，检查错误信息
- [ ] **语法专项检查**: 使用搜索工具检查不支持的语法
- [ ] **定时器测试**: 实际测试定时器时间准确性
- [ ] **版本更新**: 创建新版本，更新版本号
- [ ] **变更记录**: 在POU头部添加变更日志
- [ ] **项目保存**: 重要修改后手动保存项目



## 十一、专项检查清单

### 11.1 语法兼容性专项检查表

| 错误类型  | 错误示例                     | 正确写法                                     | 检查状态 |
| ----- | ------------------------ | ---------------------------------------- | ---- |
| 指数运算  | `r := 2.0^3.0;`          | `r := LREAL_TO_REAL(EXPT(2.0, 3.0));`    | \[ ] |
| 数学函数  | `r := SIN(angle);`       | `r := LREAL_TO_REAL(SIN(angle));`        | \[ ] |
| 枚举比较  | `IF eState.Running THEN` | `IF eState = eStateType.Running THEN`    | \[ ] |
| 数组初始化 | `arr := [1,2,3];`        | `arr[0]:=1; arr[1]:=2; arr[2]:=3;`       | \[ ] |
| 自增运算  | `i++;`                   | `i := i + 1;`                            | \[ ] |
| 比较运算符 | `IF a == b THEN`         | `IF a = b THEN`                          | \[ ] |
| 不等于运算 | `IF a != b THEN`         | `IF a <> b THEN`                         | \[ ] |
| 逻辑与运算 | `IF a && b THEN`         | `IF a AND b THEN`                        | \[ ] |
| 逻辑或运算 | `IF a \|\| b THEN`       | `IF a OR b THEN`                         | \[ ] |
| 逻辑非运算 | `IF !a THEN`             | `IF NOT a THEN`                          | \[ ] |
| 连续赋值  | `a := b := c;`           | `b := c; a := b;`                        | \[ ] |
| 三目运算符 | `r = (a>b) ? a : b;`     | `IF a > b THEN r:=a; ELSE r:=b; END_IF;` | \[ ] |

### 11.2 定时器设计专项检查表

| 检查点  | 标准要求             | 示例                            | 检查状态 |
| ---- | ---------------- | ----------------------------- | ---- |
| 时间计算 | 计数 = 目标时间 ÷ 任务周期 | 1000ms ÷ 20ms = 50次           | \[ ] |
| 变量类型 | 使用UINT类型，避免溢出    | `uiTimerCounter: UINT;`       | \[ ] |
| 注释说明 | 明确标注计算依据         | `// 50次 × 20ms = 1000ms延时`    | \[ ] |
| 任务同步 | 与任务配置interval一致  | 任务周期PT0.02S=20ms              | \[ ] |
| 边界处理 | 考虑溢出和重置逻辑        | `IF uiCounter >= 50 THEN`     | \[ ] |
| 使能控制 | 有明确的使能和完成标志      | `xTimerEnabled`, `xTimerDone` | \[ ] |
| 重置逻辑 | 定时完成后正确重置        | `uiCounter := 0;`             | \[ ] |

### 11.3 变量声明专项检查表

| 检查点   | 标准要求              | 错误示例                | 正确示例                                      | 检查状态 |
| ----- | ----------------- | ------------------- | ----------------------------------------- | ---- |
| 声明完整性 | 变量使用前已声明          | 直接使用`x`             | `VAR x: BOOL; END_VAR`                    | \[ ] |
| 类型匹配  | 声明与使用类型一致         | `VAR i: INT; r:=i;` | `VAR i: INT; r:=INT_TO_REAL(i);`          | \[ ] |
| 循环变量  | FOR索引在localVars声明 | `FOR i:=0 TO 10 DO` | `VAR i: UINT; END_VAR FOR i:=0 TO 10 DO`  | \[ ] |
| 作用域正确 | 在正确VAR区域声明        | VAR\_GLOBAL中声明临时变量  | VAR\_TEMP中声明临时变量                          | \[ ] |
| 数组索引  | 数组访问索引变量已声明       | `arr[i] := value;`  | `VAR i: UINT; END_VAR arr[i] := value;`   | \[ ] |
| 功能块实例 | 功能块实例已声明初始化       | 直接调用`FB_Instance()` | `VAR fbInst: FB_Motor; END_VAR fbInst();` | \[ ] |

## 十二、代码模板库

### 12.1 标准POU模板

```st
// 程序：PRG_MainControl
// 功能：主要控制程序实现
// 版本：Rev0.0.1.260315
// 作者：开发人员姓名
// 变更记录：
// Rev0.0.1.260315 - 初始版本，实现基本控制逻辑
PROGRAM PRG_MainControl
VAR
    // 系统状态变量
    xSystemReady : BOOL := FALSE;
    xSystemFault : BOOL := FALSE;
    
    // 控制变量
    xEnable : BOOL := FALSE;
    rSetpoint : REAL := 0.0;
END_VAR

// 主控制逻辑
IF xEnable THEN
    // 执行操作
END_IF;
```

### 12.2 定时器设计模板

```st
// 定时器设计：延时1秒
// 计算依据：目标时间1000ms ÷ 任务周期20ms = 50次计数
// 任务配置：MainTask interval = PT0.02S (20ms)
VAR
    uiTimerCounter : UINT := 0;        // 定时器计数器，使用UINT避免溢出
    xTimerEnabled : BOOL := FALSE;     // 定时器使能
    xTimerDone : BOOL := FALSE;        // 定时完成标志
END_VAR

// 定时器逻辑
IF xTimerEnabled THEN
    uiTimerCounter := uiTimerCounter + 1;
    
    IF uiTimerCounter >= 50 THEN       // 50次 × 20ms = 1000ms
        xTimerDone := TRUE;
        xTimerEnabled := FALSE;
        uiTimerCounter := 0;
    END_IF;
ELSE
    uiTimerCounter := 0;
    xTimerDone := FALSE;
END_IF;
```

### 12.3 数学函数使用模板

```st
// 指数运算：计算2的3次方
rResult := LREAL_TO_REAL(EXPT(2.0, 3.0));  // 正确：使用EXPT函数

// 三角函数：计算正弦值
rSinValue := LREAL_TO_REAL(SIN(rAngle));   // 正确：添加LREAL_TO_REAL转换

// 平方根：计算16的平方根
rSqrtValue := LREAL_TO_REAL(SQRT(16.0));   // 正确：添加类型转换

// 反三角函数：计算反正弦
rAsinValue := LREAL_TO_REAL(ASIN(0.5));    // 正确：添加类型转换

// 对数函数：计算自然对数
rLnValue := LREAL_TO_REAL(LN(10.0));       // 正确：添加类型转换
```

### 12.4 枚举状态机模板

```st
// 枚举定义
TYPE eSystemState:
(
    Idle := 0,      // 空闲状态
    Running := 1,   // 运行状态
    Paused := 2,    // 暂停状态
    Error := 3      // 错误状态
) INT;
END_TYPE

// 状态机实现
VAR
    eCurrentState : eSystemState := eSystemState.Idle;
    xStartCommand : BOOL := FALSE;
    xStopCommand : BOOL := FALSE;
END_VAR

CASE eCurrentState OF
    eSystemState.Idle:
        IF xStartCommand THEN
            eCurrentState := eSystemState.Running;
        END_IF;
        
    eSystemState.Running:
        IF xStopCommand THEN
            eCurrentState := eSystemState.Paused;
        END_IF;
        
    eSystemState.Paused:
        IF xStartCommand THEN
            eCurrentState := eSystemState.Running;
        ELSIF xStopCommand THEN
            eCurrentState := eSystemState.Idle;
        END_IF;
        
    eSystemState.Error:
        // 错误处理逻辑
        eCurrentState := eSystemState.Idle;
END_CASE;
```

## 十三、质量评分系统

### 13.1 评分标准（满分100分）

#### 1. 版本管理（15分）

- [ ] 版本命名规范：5分
- [ ] 变更记录完整：5分
- [ ] 创建新版本：5分

#### 2. 语法兼容性（25分）

- [ ] 无^/\*\*运算符：5分
- [ ] 数学函数正确转换：5分
- [ ] 枚举正确使用：5分
- [ ] 数组正确初始化：5分
- [ ] 无C风格语法：5分

#### 3. 定时器设计（20分）

- [ ] 时间计算正确：5分
- [ ] 使用UINT类型：5分
- [ ] 注释说明完整：5分
- [ ] 任务周期匹配：5分

#### 4. 变量声明（15分）

- [ ] 所有变量已声明：5分
- [ ] 类型匹配正确：5分
- [ ] 作用域正确：5分

#### 5. 代码结构（15分）

- [ ] POU声明完整：5分
- [ ] 注释充分：5分
- [ ] 模块化设计：5分

#### 6. 编译验证（10分）

- [ ] 编译无错误：10分

### 13.2 评分等级

- **优秀**: 90-100分（完全符合规范）
- **良好**: 75-89分（少量问题，不影响功能）
- **合格**: 60-74分（需要改进，存在风险）
- **不合格**: <60分（重写，存在严重问题）

## 十四、实施指南

### 14.1 第一阶段：基础实施（立即开始）

1. **文件分发**: 将本规范分发给所有开发人员
2. **培训**: 组织规范培训，重点讲解常见错误
3. **代码审查**: 在代码审查中引入检查清单
4. **模板使用**: 推广使用标准代码模板

### 14.2 第二阶段：工具支持（1个月内）

1. **检查脚本**: 开发基础的正则表达式检查脚本
2. **集成测试**: 在测试环境中集成检查工具
3. **反馈收集**: 收集使用反馈，优化检查项

### 14.3 第三阶段：全面实施（3个月内）

1. **环境集成**: 将检查工具集成到开发环境
2. **自动化流程**: 建立自动化代码检查流程
3. **质量监控**: 建立代码质量监控体系
4. **持续改进**: 定期更新规范文件

### 14.4 成功指标

1. **错误率下降**: 常见错误发生率降低50%以上
2. **代码质量提升**: 代码质量评分平均提高20分
3. **开发效率**: 代码审查时间减少30%
4. **维护成本**: 代码维护成本降低25%

## 十五、总结

本综合开发规范为CODESYS开发提供了完整的指导体系，包括：

1. **基础开发规范**: 架构设计、命名规范、代码格式、注释规范
2. **版本管理**: 严格的版本控制流程和错误预防
3. **工作流程**: 三阶段系统化检查流程
4. 
5. **检查工具**: 专项检查清单和代码模板库
6. **质量保证**: 质量评分系统和实施指南

**关键成功因素**:

- 领导支持和管理层承诺
- 开发团队的积极参与
- 持续培训和知识分享
- 工具支持和自动化
- 定期回顾和改进

**最后更新**: 2026年3月31日
**版本**: Rev1.0.1.260331
