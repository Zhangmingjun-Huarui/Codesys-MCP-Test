// 全局变量表：GVL_WebInterface
// 功能：提供Web界面与CODESYS控制器之间的通信变量
// 版本：Rev0.0.1.260412
// 作者：Trae AI
// 修改记录：
// Rev0.0.1.260412 - 初始版本，实现Web界面通信变量
VAR_GLOBAL
    // 正弦波控制变量（Web界面可写）
    xSineEnable : BOOL := FALSE;    // 正弦波使能
    rSineAmplitude : REAL := 1.0;   // 正弦波振幅
    rSineFrequency : REAL := 1.0;   // 正弦波频率
    rSineOffset : REAL := 0.0;      // 正弦波偏移
    
    // 正弦波状态变量（Web界面可读）
    rSineOutput : REAL;             // 正弦波输出值
    xSineRunning : BOOL;            // 正弦波运行状态
    
    // 系统状态变量（Web界面可读）
    xSystemReady : BOOL := TRUE;    // 系统准备就绪状态
    diCycleCount : DINT := 0;       // 系统循环计数
END_VAR
