# Gymlog P0-2 核心数据模型定义方案

## 摘要
本轮只定义数据模型规格，不实现解析器、编辑器或持久化接线。模型保持“双层模型”，但训练中的完成进度改为直接写入 `rawText`：

- 持久化层只保存真正需要跨重启保留的真值：训练原文、更新时间、动作库
- 解析层定义可从 `rawText` 重建的派生结构：`ExerciseBlock`、`PlanLine`
- 训练中的计划行采用“目标 + 当前进度后缀”语法，例如 `20 x 8 x 5 3/5`
- 结束训练后，同一行会收敛成实际完成记录，例如 `20 x 8 x 4`
- `rawText` 是唯一事实源，不再额外持久化 `PlanLineProgress` 或 `lineStates`

建议把这一轮的代码落在 3 个区域：

- `Gymlog/Domain/Workout`
- `Gymlog/Domain/ExerciseLibrary`
- `Gymlog/Persistence` 或同级模型目录

## 关键定义

### 1. 持久化实体

#### `WorkoutNote`
- 字段：`id`、`rawText`、`updatedAt`
- 角色：当前训练笔记的唯一真值宿主

约束：
- `rawText` 保存完整原始文本
- `rawText` 同时承载训练中的实时进度和结束训练后的最终结果
- 不直接持久化 `ExerciseBlock` / `PlanLine`
- 不包含 `lineStates`

#### `ExerciseLibraryEntry`
- 字段：`id`、`name`、`isBuiltin`
- 用途：`@动作` 自动补全的数据源

### 2. 解析输出类型

#### `ExerciseBlock`
- 字段：`id`、`exerciseName`、`startLineIndex`、`endLineIndex`
- 角色：从 `rawText` 推导出的动作段落
- 不作为长期真值保存

#### `PlanLine`
- 字段：`id`、`lineIndex`、`exerciseBlockId`、`weight`、`reps`、`targetSets`、`completedSets`、`rawText`
- 角色：从 `rawText` 推导出的结构化计划行
- `completedSets` 为可选值：
  - 纯计划行 `20 x 8 x 5` 时为空
  - 进行中计划行 `20 x 8 x 5 3/5` 时为 `3`
  - 结束训练后保存的 `20 x 8 x 4` 会被重新解析为纯计划行，`targetSets` 取最终实际组数 `4`
- 不作为长期真值保存

#### `PlanLineState`
- 角色：表达解析后当前行所处的语义阶段
- 取值：
  - `planned`
  - `inProgress`
  - `finalized`
- 说明：该状态由 `rawText` 推导，不单独持久化

### 3. 文本语义

计划行在不同阶段的文本规则如下：

- 计划态：`20 x 8 x 5`
- 进行中：`20 x 8 x 5 3/5`
- 结束训练后：`20 x 8 x 4`

收敛规则：

- `20 x 8 x 5 4/5` -> `20 x 8 x 4`
- `20 x 8 x 5 5/5` -> `20 x 8 x 5`
- `20 x 8 x 5` 或 `20 x 8 x 5 0/5` -> 删除该行

训练中的点击规则：

- 点击右侧勾选时，系统直接改写该行正文
- `20 x 8 x 5` -> `20 x 8 x 5 1/5`
- `20 x 8 x 5 3/5` -> `20 x 8 x 5 4/5`

编辑规则：

- 用户手动编辑计划核心内容时，已有进度立即清空
- 改动重量、次数或目标组数后，该行回到新的纯计划态
- 仍保留“离开当前行后再统一校验”的编辑稳定性原则

## 实现变更

- 为持久化层定义最小模型骨架，优先兼容后续 SwiftData：
  - `WorkoutNote`
  - `ExerciseLibraryEntry`
- 为解析层定义纯领域类型：
  - `ExerciseBlock`
  - `PlanLine`
  - `PlanLineState`
- 明确关系与职责：
  - `WorkoutNote.rawText` 是唯一事实源
  - 训练中的实时进度直接写入 `rawText`
  - `ExerciseBlock` / `PlanLine` 全部由解析器重建

不在本轮加入：

- `PlanLineProgress`
- `lineStates`
- 模板模型
- 历史页聚合模型
- 统计模型
- 网络/同步相关字段

## 测试与验收

### 类型层验收
- 能清楚区分“持久化实体”和“解析输出类型”
- `WorkoutNote` 不直接包含 `ExerciseBlock` / `PlanLine` 集合
- 不再定义 `PlanLineProgress` 或 `lineStates` 作为进度真值

### 解析层验收
- `PlanLine` 能同时识别：
  - `20 x 8 x 5`
  - `20 x 8 x 5 3/5`
  - `20 x 8 x 4`
- `completedSets` 仅在进行中语法下出现
- `PlanLineState` 能由文本稳定推导

### 动作库验收
- `ExerciseLibraryEntry` 只承担名称和内置/自定义来源区分

### 文档/命名验收
- 类型命名与 backlog 一致
- 代码注释或文档明确声明 `rawText` 是唯一事实源
- 文档明确说明训练中进度写入正文，结束训练时收敛为最终记录

## 默认假设

- “右侧写入 `3/5`”指该计划行正文实时变成 `20 x 8 x 5 3/5`
- 当前不支持负向修正、撤销勾选、超目标组数或实际 reps/weight 偏差
- 删除 0 组计划行只发生在“结束训练”这一显式动作上
- 最终历史记录以“实际完成结果”为准，不保留原目标组数痕迹
- `ExerciseBlock.id` 和 `PlanLine.id` 在当前阶段是运行时解析身份，不承诺跨解析稳定
