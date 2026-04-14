// 功能块：FB_SineWave
// 功能：生成正弦波信号
// 输入：xEnable（使能），rAmplitude（振幅），rFrequency（频率），rOffset（偏移）
// 输出：rOutput（正弦波输出），xRunning（运行状态）
// 版本：Rev0.0.1.260412
// 作者：Trae AI
// 修改记录：
// Rev0.0.1.260412 - 初始版本，实现正弦波生成功能
FUNCTION_BLOCK FB_SineWave
VAR_INPUT
    xEnable : BOOL;                 // 使能信号
    rAmplitude : REAL := 1.0;       // 振幅，默认1.0
    rFrequency : REAL := 1.0;       // 频率，默认1.0Hz
    rOffset : REAL := 0.0;          // 偏移量，默认0.0
END_VAR
VAR_OUTPUT
    rOutput : REAL;                 // 正弦波输出
    xRunning : BOOL;                // 运行状态
END_VAR
VAR
    rPhase : REAL := 0.0;           // 相位角
    rTimeStep : REAL;               // 时间步长
    rTwoPi : REAL := 6.283185307;   // 2π常量
END_VAR
