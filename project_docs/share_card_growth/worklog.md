# FastFlow 项目交接说明

最后更新：2026-04-07

## 1. 这份文档是干什么的

这不是单纯的工作日志，而是给后续新开的 Codex 线程看的项目交接文档。

目标是让新的线程快速搞清楚：

- 这个产品到底想做什么
- 现在已经做到了什么程度
- 哪些决策已经定了，不要反复推翻
- 当前代码和数据层的关键边界是什么
- 后面继续做时，哪些地方最容易踩坑

---

## 2. 产品背景与定位

### 产品名

- `FastFlow`

### 产品方向

FastFlow 不是 AI 减脂教练，也不是卡路里管理平台。

当前明确的产品定位是：

- `轻断食陪伴工具`
- 重点是帮助用户开始断食、坚持断食、理解自己的节奏
- 强调规律、真实记录、低负担坚持

### 不做什么

当前不把自己定义为：

- 医学诊断工具
- 营养师替代品
- AI 拍照识别饮食平台
- 全能减重社区

### 产品核心价值

- 让用户开始一次轻断食更简单
- 让用户在过程中更容易坚持
- 让用户结束后能看懂自己的节奏和反馈

---

## 3. 商业模式与 Pro 边界

### 当前商业模式

明确方向是：

- 免费版 + 广告
- Pro 版 = 去广告 + 高级功能

### 免费功能

- 断食计时主流程
- 预设计划
- 自定义计划
- 阶段参考与阶段提醒
- 完整历史浏览
- 单条历史查看
- 手动补录断食记录
- 编辑 / 删除断食记录
- 体重记录
- 周报
- 基础统计
- 周报分享卡基础能力

### 已落地的 Pro 功能

- 去广告
  - 目前广告位只在 `History` 和 `Insights/Stats`
- 历史高级筛选
  - 按时间范围
  - 按计划
  - 按结果状态
  - 按提前结束原因

### 计划中的 Pro 方向

- 更长周期的趋势分析
- 更深的周报 / 洞察
- 体重与断食节奏关联分析
- 更成熟的分享与增长能力
- 未来可能接入 iCloud/Health 的更完整体验

### 已确定不要做的事

- 不再把“完整历史”锁在 Pro 后面
- 不靠“把你自己的数据锁住”来卖订阅

---

## 4. 当前功能现状

### 4.1 断食主流程

当前主链路已经具备：

- 选择计划
- 开始断食
- 进行中计时
- 阶段参考提示
- 达标完成
- 未达标提前结束
- 结束时记录主观 / 客观反馈
- ongoing 纠错

### 4.2 计划体系

当前预设计划：

- `16:8`
- `18:6`
- `20:4`
- `OMAD`

补充说明：

- `5:2` 已被明确移除
- 自定义计划已支持，范围是 `12h - 23h`
- 自定义计划会显示为类似 `17:7` 的比例

### 4.3 历史记录

当前能力：

- 完整历史免费可见
- 单条记录展示完整 session 时间段
- 可新增 / 补录
- 可编辑
- 可删除
- 高级筛选是 Pro 功能

### 4.4 统计 / Insights

当前能力：

- 每日断食时长
- 完成情况统计
- streak / 连续完成
- 开始时间稳定性
- 周报
- 体重记录

### 4.5 体重记录

当前能力：

- 新增体重
- 编辑体重
- 删除体重
- 在统计页看基础趋势

### 4.6 通知

当前有 3 类通知：

- 开始提醒
- 阶段提醒
- 目标前 1 小时提醒

通知内容与阶段文案共享同一套文案源，所以阶段名改了，通知标题会一起变化。

### 4.7 分享

当前已有：

- 周报分享卡已经产品化，支持一屏分享卡、先预览再调起系统分享、右上角下载二维码
- 单次完成分享卡已经接入主流程，完成断食后可直接生成并分享，右上角带下载二维码
- 分享文案支持随机轮换，方向是更像普通人会发的中文短句

当前还不成熟：

- 下载二维码当前先写死到 Vercel 下载中转页，后面如有正式域名需要同步替换

---

## 5. 已经明确的产品决策

下面这些是已定结论，后续线程不要反复回到原点。

### 5.1 状态设计

断食结束只保留两种结果状态：

- `completed`
- `not_completed`

用户侧不再强调 `abort / give up` 这类词。

### 5.2 进行中主按钮逻辑

进行中页只保留一个主动作，按是否达标动态变化：

- 未达标：`提前结束`
- 已达标：`完成本次断食`

### 5.3 结束反馈

无论提前结束还是正常完成，都可以记录主观 / 客观反馈。

原因：

- 用户的真实感受和身体状态，是后面做高级洞察的重要依据

### 5.4 DailySummary / 统计口径

已经明确的统计原则：

- `session` 是唯一事实来源
- 每日断食时长：按自然日拆分
- 完成次数 / streak：按结束日
- 开始时间稳定性：按开始时间

### 5.5 阶段系统

阶段是“按断食时长给的参考提示”，不是医学诊断。

已经明确：

- 预设计划可以显示阶段参考
- 自定义计划不显示生理阶段，只显示进度

当前阶段文案方向已做过多轮收敛，用户非常在意“像人说的话”，不接受生硬的 AI 风格文案。

### 5.6 广告位策略

已确定只在这些免费页面放广告：

- `History` 1 个 native ad
- `Insights/Stats` 1 个 native ad

明确不放广告的位置：

- Timer 主页面
- ongoing fasting 核心流程
- 阶段弹窗
- 结束反馈
- 周报分享

### 5.7 分享 / 增长方向

已经明确：

- 先做可传播的成果卡
- 再做轻量好友监督
- 不先做重社区

---

## 6. 关键架构与数据层

### 技术栈

- iOS 原生
- SwiftUI
- SwiftData
- RevenueCat
- Google AdMob + UMP

### 核心入口

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowApp.swift`

### 当前 SwiftData 主模型

定义在：

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowModels.swift`

主要模型：

- `FastingRecord`
- `DailySummary`
- `WeightRecord`
- `SessionFeedbackRecord`
- `SyncedPreferencesRecord`

### 当前数据的事实边界

#### FastingRecord

记录每一次断食 session 的事实：

- 开始时间
- 结束时间
- 当次计划
- 目标时长
- 结果状态

注意：

- 当次采用的计划必须和 session 一起固化保存
- 不能只看用户当前设置页的计划

#### SessionFeedbackRecord

记录结束时的反馈：

- 主观感受
- 客观状态 / 原因

#### WeightRecord

记录体重：

- 体重值
- 记录时间
- 来源

#### SyncedPreferencesRecord

记录需要同步的偏好：

- 当前计划
- 自定义计划时长
- 提醒开关
- 提醒时间
- 应用语言

---

## 7. iCloud 同步现状

### 目标同步范围

当前只考虑同步这些：

- 断食记录
- 结束反馈
- 体重记录
- 当前计划与自定义计划
- 提醒偏好
- 应用语言

### 不通过 iCloud 同步的内容

- Pro 状态
  - Pro 以 RevenueCat 为准
- 广告模式
- 设备级通知授权状态

### 当前代码状态

CloudKit/SwiftData 的接入骨架已经在代码里：

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowApp.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/CloudSyncRuntime.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlow.entitlements`

并且当前 App 会优先尝试：

1. CloudKit-backed ModelContainer
2. 失败后退回 local-only
3. 再失败则退回 in-memory emergency container

### 当前结论

这部分已经进入“可继续验证”的状态，但**不要默认它已经完全稳定**。

后续线程如果继续做 iCloud，同步相关的第一优先级永远是：

- 先测双设备
- 再扩大范围
- 不要先改 UI 承诺

### 必测清单

至少要做双设备同 Apple ID 验证：

- A 新增断食记录，B 收到
- A 结束断食并记录反馈，B 收到
- A 新增 / 编辑 / 删除体重，B 收到
- A 改当前计划 / 自定义时长，B 收到
- A 改提醒偏好，B 收到
- A 改语言，B 收到

---

## 8. 本地化 / 文案现状

### 当前状态

项目已有中英文本地化：

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Resources/zh-Hans.lproj/Localizable.strings`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Resources/en.lproj/Localizable.strings`

设置页也支持切换语言。

官网静态站当前也已接入中英双语切换能力（主页 / 下载页 / 技术支持页 / 隐私页），并提供显式语言切换按钮。

### 地区默认规则

已定规则：

- 中国大陆 / 台湾：默认中文
- 其他地区：默认英文

### 当前最大风险

文案质量仍然是当前项目最容易被用户挑出来的问题之一。

具体表现：

- 有些中文像产品说明，不像用户文案
- 有些中文仍然有 AI / 翻译腔
- 本地化资源里有重复 key / 旧 key / 历史残留

### 对未来线程的要求

只要改用户可见文案，必须同时做两件事：

1. review 中文是不是正常中国人会说的话
2. 检查英文是否同步、是否过于“机翻”

另外新增一条硬约束：

- 任何线上用户可见页面、分享卡、落地页，不能直接出现写给开发者或团队自己的说明文字
- 诸如“后续接 AdMob”“以后上线后改这里”“占位策略说明”这类内容，只能留在代码注释或交接文档里，不能直接上线

---

## 9. 核心迭代历程（高层摘要）

这是截至目前最重要的迭代脉络。

### 9.1 上架与工程基础

- 修复 App Store / TestFlight 验证问题
  - AppIcon
  - `CFBundleIconName`
  - 方向配置
  - Asset Catalog 打包

### 9.2 Onboarding

- 修复首次打开引导页按钮不可点击

### 9.3 产品定位收敛

- 明确不走“AI 全能减脂教练”路线
- 明确走“轻断食陪伴工具”路线
- 删除 `5:2`

### 9.4 计划与统计体系重做

- 引入自定义计划
- Session 作为统计事实来源
- History 改成完整历史免费
- Stats 口径重做

### 9.5 数据与纠错能力

- 历史记录支持编辑 / 删除 / 补录
- ongoing session 支持修正
- 体重支持新增 / 编辑 / 删除

### 9.6 教育与反馈

- 加入阶段教育内容
- 提前结束和完成后的反馈收集
- 周报能力上线

### 9.7 变现

- AdMob 接入
- RevenueCat 接入
- Pro 边界收敛
- 购买页已补齐 App Review 所需的 `隐私政策` 与 `使用条款` 外链
- 购买主按钮现在会等待 RevenueCat offering 加载完成后才允许发起购买，避免打开付费页后立即点击时出现套餐不可用
- 应用默认语言改为优先跟随系统语言，而不是按地区猜测，减少审核机和真实设备上的订阅页语言误判
- 购买页的订阅标题、描述、按钮和功能点文案已改成语义化本地化 key，不再混用中文句子 / 英文句子作为 key，降低英文环境回退到中文文案的风险
- 购买页会随应用语言变化整页重绘，减少“部分订阅文案切语言、部分没切”的审核边缘情况

### 9.8 云同步准备

- 体重、反馈、同步偏好逐步并入 SwiftData
- CloudKit 骨架接入

### 9.9 上线落地页补齐

- 官网已包含主页、下载页、技术支持页与隐私政策页
- 隐私政策页按当前实际接入的 `AdMob / UMP`、`RevenueCat`、`iCloud / CloudKit` 能力编写
- App Store Connect 里的隐私选项必须持续和真实接入的第三方 SDK 保持一致，尤其是广告与订阅相关数据披露
- 官网根目录已补 `app-ads.txt`，用于 AdMob 抓取和验证开发者网站的广告声明
- 官网语言策略已落地：
  - 默认根据用户地区/语言环境自动切换（中文或英文）
  - 用户可通过顶部语言按钮手动切换
  - 手动选择会写入 `localStorage` 并在后续访问保持一致

---

## 10. 分享增长项目现状

这一块很重要，因为之前已经在 Stitch 里做过设计探索。

### 目标

做两类分享卡：

- 单次完成分享卡
- 周报分享卡

### 当前情况

- 周报分享卡已有代码基础，现已切到更短的一屏卡片方向
- 周报分享卡已接入“短句随机轮换”文案机制
- 单次完成分享卡已正式接入主流程
  - 完成断食并保存反馈后会弹出分享卡
  - 当前分享卡聚焦“完成结果 + 一句有情绪的短句”
  - 短句支持随机轮换，方便后续继续扩词库

### 已有 Stitch 设计项目

项目：

- Project name: `FastFlow Share Cards`
- Project ID: `263363289395043223`

主题方向：

- `FastFlow Ember`

### 已生成的 Stitch screen IDs

- Daily card: `8ca226dbafd046f3a113ed589ca1f417`
- Weekly card: `ea60e87dc2894db4a65834d7d36971f1`
- Simplified daily card: `9529c6010216442eafae4c726a9c0542`
- Simplified weekly card: `6b523255d24a4bf79598eb761f55bebf`

### 未来继续做分享卡时，应重点查看

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/WeeklyReportShareCardView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/WeeklyReportSheetView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/EndFastFeedbackSheetView.swift`

### 增长方向结论

已明确：

- 先做好单次完成分享卡
- 再做好周报分享卡
- 再考虑好友监督 / 打卡
- 暂不先做重社交

---

## 11. 当前已知问题 / 风险

### 11.1 文案仍需系统性清稿

- 中文仍有不自然表达残留
- 英文也需要同步润色

### 11.2 周报分享与单次分享还没成型

- 周报分享已进入可用状态，但短句文案池还需要继续迭代
- 单次结束分享卡已进入正式开发并接入产品链路

### 11.3 iCloud 还需要双设备验收

- 代码已经铺了不少，但不能默认已经稳定

### 11.4 用户对“像人话”非常敏感

这是很重要的产品要求：

- 任何文案如果像 AI 在写说明书，用户会直接指出来
- 所以每次改文案，都要从“这像不像中国本地产品会说的话”这个角度复核

---

## 12. 后续线程建议先读这些文件

如果新线程要高质量接手，建议先读：

### 产品主流程

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowTimerView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowTimerViewModel.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/PlanOption.swift`

### 历史 / 统计 / 周报

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/HistoryView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/StatsView.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastingAnalytics.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/WeeklyReportSheetView.swift`

### 数据模型与同步

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowModels.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastFlowApp.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/CloudSyncRuntime.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/SyncedPreferences.swift`

### 体重与反馈

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/WeightTracking.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/FastingSessionFeedback.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/EndFastFeedbackSheetView.swift`

### 变现

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Monetization.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/SubscriptionRuntime.swift`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/PaywallView.swift`

### 本地化

- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Resources/zh-Hans.lproj/Localizable.strings`
- `/Users/guxiaoqiu/Documents/trae_projects/healthy_app_analysis/Resources/en.lproj/Localizable.strings`

---

## 13. 给后续线程的工作原则

### 先保证可用性

用户很在意稳定性。每次做改动都要：

- 先想测试
- 分步骤迁移
- 每步都回归
- 不要为了“看起来更高级”破坏现在能用的主流程

### 先做高频价值，再做大而全

优先级建议：

- 主流程顺滑
- 文案自然
- 历史 / 统计准确
- 分享卡能打
- 再做更复杂的增长和社交

### 不要重新讨论已经定了的方向

不要再回到这些旧问题上反复争论：

- 要不要做 5:2
- 要不要把完整历史锁到 Pro
- 要不要把产品做成 AI 全能减脂教练

这些方向都已经定了。

---

## 14. 一句话总结

FastFlow 当前最重要的不是“加更多功能”，而是：

- 把轻断食主流程继续做顺
- 把文案做得像真正的本地产品
- 把分享卡和增长链路做出来
- 在不破坏稳定性的前提下，把数据与同步基础打稳
