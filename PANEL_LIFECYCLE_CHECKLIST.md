# Panel Anti-Residue Checklist (MQL5 CAppDialog)

适用范围：
- 基于 CAppDialog / CDialog / Controls 库的面板
- 需要 Create / Run / ChartEvent / Destroy 全生命周期管理的 EA

## 1. 生命周期对称
1. 创建顺序固定：Create -> Run -> 开事件/定时器。
2. 销毁顺序反向：关定时器/事件 -> Destroy。
3. 每个“开启动作”都必须有对应“关闭动作”。

## 2. 初始化原子化
1. OnInit 任一步失败，必须回滚已创建对象。
2. 禁止出现半初始化状态（部分 Create 成功后直接 return）。
3. Run 失败也必须回滚，不可忽略返回值。

## 3. 状态位治理
1. 维护 created / timer_started / mouse_event_enabled 等状态位。
2. OnTick / OnTimer / OnChartEvent 进入前先检查状态位。
3. Destroy 后立即重置状态位，确保幂等。

## 4. 事件路由单播
1. 同一事件只路由到一个目标面板。
2. 对 CHARTEVENT_MOUSE_MOVE 做命中路由（HitTest）。
3. 对 CHARTEVENT_CUSTOM / OBJECT_CLICK 按对象名来源路由。
4. 路由函数未命中时必须有回退，不可吞事件。

## 5. 启动前残留清理
1. OnInit 最前执行残留扫描和清理。
2. 清理策略优先级：
- 前缀清理（已知实例前缀）
- 标题识别清理（Caption 反推前缀）
3. 清理逻辑必须容忍“对象不存在”。

## 6. 销毁后兜底清理
1. 调用面板 Destroy 后，再做一次对象级前缀清扫。
2. 清扫应限定在本 EA 可识别前缀，避免误删他人对象。
3. 清理完成后清空前缀缓存。

## 7. 禁止可视化状态标记
1. 不使用可显示图表对象（如 Label）保存运行状态。
2. 若历史版本已使用，OnInit 做一次性迁移/删除。

## 8. 失败可观测性
1. Create 失败、Run 失败、Destroy 异常都要 Print 明确原因。
2. 日志前缀统一，例如：[Lifecycle] [Route] [CreateFail] [Destroy]。
3. 日志必须能回答：谁创建了、谁没销毁、谁误路由。

## 9. 代码评审验收项
1. 是否存在“Create 成功但失败路径无回滚”？
2. 是否存在“ChartEvent 双转发导致串扰”？
3. 是否存在“OnDeinit 未关闭 EventSetTimer/ChartSetInteger 开关”？
4. 是否存在“Destroy 后仍可进入 OnTick/OnTimer 调用对象方法”？

## 10. 实测场景清单
1. 正常挂载 -> 正常移除（无残留）。
2. Create 第二个面板故意失败（无半残留）。
3. 强制终端异常退出 -> 重启挂载（无重复面板）。
4. 快速切换周期与模板（无重复对象）。
5. 高频点击与拖拽（无跨面板误触发）。

## 推荐最小实现模板
1. 全局状态位：
- g_panel_a_created
- g_panel_b_created
- g_timer_started
- g_mouse_move_enabled

2. 必备函数：
- DestroyCreatedPanels(reason)
- RouteEventByName(...)
- RouteMouseEventByHitTest(...)
- CleanupStalePanels...

3. OnInit 结构：
- ResetState()
- CleanupStalePanels()
- Create A -> Create B -> Run A -> Run B
- Enable MouseMove
- EventSetTimer

4. OnDeinit 结构：
- EventKillTimer
- Disable MouseMove
- DestroyCreatedPanels(reason)
- ResetState()
