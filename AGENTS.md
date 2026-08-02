# AGENTS.md

## 项目定位
这是一个基于 SwiftUI 的 iOS App，核心场景围绕：
- 旅行照片导入与整理
- 地图可视化打卡地点
- 徒步 / 爬山路线记录
- 个人旅行内容沉淀与回顾

开发时优先追求：
- 小而完整的改动
- 清晰、可 review 的提交
- 尽量复用已有模块与模式
- 不为了“看起来更高级”而引入额外复杂度

## 架构原则
本项目整体以 DDD（Domain-Driven Design）方式组织代码。

### 分层约定
- `App/`
  负责应用入口、依赖注入、Tab 组装、全局启动配置。
- `Domain/`
  负责领域模型、领域规则、仓储协议、用例与服务。
- `Features/`
  负责具体页面和功能模块，每个 feature 自己维护 UI、状态、页面内交互。
- `Shared/Infrastructure/`
  负责数据落地、系统能力接入、定位、照片、持久化、仓储实现等基础设施。
- `Shared/UI/`
  负责跨 feature 复用的 UI 组件、地图组件、展示组件和轻量视觉支持代码。

### DDD 开发要求
- SwiftUI `View` 只负责渲染、布局和简单事件转发。
- 核心业务规则不要直接写在 SwiftUI 视图里。
- 只要逻辑具备“可复用”或“可测试”价值，优先进入 `Domain/Services/`、`Domain/Repositories/` 或 feature 对应的 `ViewModel`。
- 仓储协议定义放在 `Domain/Repositories/`，具体实现放在 `Shared/Infrastructure/Repositories/`。
- 系统框架能力接入，例如 Photos、CoreLocation、MapKit 的底层使用，优先封装在 `Shared/Infrastructure/`。
- 如果一个改动只影响某个 feature，不要随意抽成全局工具文件。
- 没有明确收益时，不要引入新的架构模式、状态管理框架或第三方库。

## Repo Map
下面是当前项目的快速目录地图，便于定位代码：

- `PHOTOIN/App/`
  App 入口、依赖容器、根 Tab、页面组装。

- `PHOTOIN/Domain/Models/`
  领域模型，例如旅行照片、徒步路线、定位采样等。

- `PHOTOIN/Domain/Repositories/`
  领域仓储协议，例如照片仓储、路线历史仓储、定位跟踪协议。

- `PHOTOIN/Domain/Services/`
  核心业务规则，例如照片筛选、路线记录规则。

- `PHOTOIN/Features/Home/`
  首页功能，包括地图、搜索、上传、底部展示区、首页状态。

- `PHOTOIN/Features/Route/`
  徒步 / 爬山路线记录页，包括路线状态、开始记录、记录点、地图交互。

- `PHOTOIN/Features/Profile/`
  “我的”页面，包括全部照片、打卡地点聚合、旅行足迹、权限、导出等。

- `PHOTOIN/Shared/Infrastructure/Photos/`
  照片导入、元数据提取、Photos 相关系统接入。

- `PHOTOIN/Shared/Infrastructure/Location/`
  定位能力接入与实时位置流。

- `PHOTOIN/Shared/Infrastructure/Repositories/`
  仓储实现与本地持久化，例如导入照片持久化、路线历史持久化。

- `PHOTOIN/Shared/Infrastructure/Fixtures/`
  示例数据与本地开发期占位数据。

- `PHOTOIN/Shared/UI/Components/`
  可复用 UI 组件，例如地图视图、照片卡片、底部浮层、路线地图组件。

- `PHOTOIN/Shared/UI/Support/`
  UI 支撑代码，例如投影、样式辅助、轻量支持类型。

- `PHOTOINTests/Domain/`
  领域服务和规则测试。

- `PHOTOINTests/Features/`
  Feature 级状态和交互测试。

- `PHOTOINUITests/`
  UI 自动化测试。

## 开发约束

### 页面修改
- 改用户可见页面前，先查看对应 `Features/` 目录。
- 首页相关优先看 `Features/Home/`。
- 路线相关优先看 `Features/Route/`。
- “我的”页相关优先看 `Features/Profile/`。

### 业务逻辑修改
- 改业务规则时，优先检查 `Domain/Services/` 和 `Domain/Repositories/`。
- 不要把核心逻辑直接堆进 `body`、`task`、`onAppear`、`onChange`。
- 如果逻辑需要测试，优先提取到 `ViewModel` 或 `Domain`。

### 数据与持久化
- 会影响用户数据的改动，优先考虑是否需要持久化。
- 内存级实现如果只是过渡方案，需要在最终说明里明确指出。
- 新增数据存储时，保持模型边界清晰：
  领域模型用于业务表达；
  持久化模型用于编码 / 解码 / 存储；
  二者不要无边界混用。

### 并发与线程
- UI 状态更新必须发生在主线程 / 主 actor。
- 避免阻塞主线程。
- 优先使用 async/await，不新增 callback 风格 API，除非系统边界强制要求。

### Map / Photo / Location 相关
- 涉及地图显示时，优先延续现有 MapKit 封装，而不是直接在页面里堆系统细节。
- 涉及照片导入时，优先复用现有导入链路与 metadata 提取逻辑。
- 涉及定位时，要同时考虑：
  权限状态
  空状态回退中心
  持续记录时的更新频率
  记录结束后的持久化

## 测试要求
- 业务规则改动必须补或改对应单元测试。
- Bug 修复尽量补回归测试。
- 小型视觉微调可以不强制补测试，但不要破坏现有测试。
- 如果删除或跳过测试，需要在总结里明确说明原因。

优先关注的测试位置：
- 领域规则：`PHOTOINTests/Domain/`
- 首页状态：`PHOTOINTests/Features/Home/`
- 路线记录：`PHOTOINTests/Features/Route/`
- 我的页面数据聚合：`PHOTOINTests/Features/Profile/`

## Summary 文件约定
如果我明确要求“写一个 summary 文件”来总结当日改动，必须创建一个实际文件，不要只在回复里口头总结。

### 约定
- summary 文件默认放在仓库根目录的 `summaries/` 下。
- 如果目录不存在，需要一并创建。
- 文件名格式建议：
  `summaries/YYYY-MM-DD-summary.md`
- 如果我指定文件名或路径，按我指定的来。

### summary 内容建议至少包含
- 当日改动概览
- 涉及模块 / 目录
- 用户可见变化
- 关键技术实现
- 测试与验证结果
- 风险点 / 未完成项
- 下一步建议

## 变更策略
- 优先做最小充分修改，不做无关重构。
- 尽量保持现有公共接口稳定，除非任务本身要求调整。
- 代码改动要和当前项目风格一致，不要突然切到另一套命名或结构体系。
- 改动前先理解现有实现，不凭空假设。

## 代码注释
- 新增函数时，补一条清晰注释，说明这个函数的职责。
- 注释要解释“为什么存在”或“做了什么”，不要写无信息量废话。
- 少写重复代码字面含义的注释。

## Review Checklist
提交前至少自查以下内容：
- 是否有主线程违规
- 是否有状态竞争或异步时序问题
- 是否有 retain cycle / 生命周期问题
- 是否重复实现了已有映射或仓储逻辑
- 是否缺失错误处理
- 是否缺失测试覆盖
- 是否把不该持久化的 Xcode 用户文件带进仓库
- 是否误改了无关文件

## 最终输出要求
在说明改动时，优先告诉我：
- 做了什么
- 用户侧会看到什么变化
- 是否跑过 build / test
- 还存在哪些风险或后续建议

如果我要求提交总结、日报、summary 或变更记录，记得创建实际文件，而不是只在聊天里描述。
