// 功能块：FB_SineWave 实现部分
// 正弦波生成逻辑
// 假设任务周期为20ms（50Hz），计算时间步长
rTimeStep := 0.02; // 20ms = 0.02s

IF xEnable THEN
    // 计算相位增量：2π * 频率 * 时间步长
    rPhase := rPhase + LREAL_TO_REAL(rTwoPi * rFrequency * rTimeStep);
    
    // 相位超过2π时重置，避免溢出
    IF rPhase >= rTwoPi THEN
        rPhase := rPhase - rTwoPi;
    END_IF;
    
    // 计算正弦波输出：振幅 * sin(相位) + 偏移
    rOutput := rAmplitude * LREAL_TO_REAL(SIN(rPhase)) + rOffset;
    
    xRunning := TRUE;
ELSE
    // 禁用时输出0
    rOutput := 0.0;
    xRunning := FALSE;
END_IF;
