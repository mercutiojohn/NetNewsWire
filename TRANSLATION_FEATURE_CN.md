# NetNewsWire 翻译功能实现说明

## 功能概述

本次更新为 NetNewsWire 添加了完整的翻译功能，使用 Apple Translation Framework 实现：

### 主要功能

1. **Feed 级别的翻译开关**
   - 在 Feed 设置中添加了翻译开关按钮
   - 可以为每个 Feed 单独启用或禁用翻译

2. **文章标题自动翻译**
   - 在信息流（Timeline）中自动翻译文章标题
   - 支持双语对照和纯译文两种显示模式
   - 翻译结果自动缓存，避免重复翻译

3. **文章内容自动翻译**
   - 打开文章时自动进行段落级翻译
   - 支持双语对照模式（原文+译文）
   - 支持纯译文模式（仅显示译文）
   - 翻译结果持久化缓存

4. **应用级翻译设置**
   - 配置目标语言（默认使用系统显示语言）
   - 切换双语对照 / 纯译文模式
   - 支持 15+ 种常用语言

## 实现架构

### 核心模块

#### 1. TranslationManager（翻译管理器）
- 位置：`Shared/Translation/TranslationManager.swift`
- 功能：
  - 管理 Apple Translation Framework 交互
  - 提供异步翻译接口
  - 支持单个和批量翻译
  - 管理翻译会话生命周期

#### 2. TranslationCache（翻译缓存）
- 位置：`Shared/Translation/TranslationCache.swift`
- 功能：
  - 内存缓存（NSCache）+ 磁盘缓存
  - 按文章 ID、内容类型和目标语言组织缓存
  - 支持缓存清理和大小管理
  - 持久化存储，应用重启后依然有效

### 数据模型扩展

#### FeedMetadata 扩展
- 位置：`Modules/Account/Sources/Account/FeedMetadata.swift`
- 新增属性：`isTranslationEnabled` - 控制该 Feed 是否启用翻译

#### AppDefaults 扩展
- Mac 版：`Mac/AppDefaults.swift`
- iOS 版：`iOS/AppDefaults.swift`
- 新增设置：
  - `translationTargetLanguage` - 目标语言（nil 表示系统语言）
  - `translationMode` - 翻译模式（双语/纯译文）

### UI 组件

#### Feed 检查器（Feed Inspector）
- Mac 版：添加了翻译开关复选框
- iOS 版：添加了翻译开关按钮

#### 偏好设置（Preferences/Settings）
- Mac 版：创建了翻译偏好设置视图控制器
- iOS 版：创建了翻译设置视图控制器
- 功能：
  - 语言选择器（支持 15+ 种语言）
  - 翻译模式切换

### 翻译集成

#### 文章内容翻译
- 位置：`Shared/Article Rendering/ArticleRenderer+Translation.swift`
- 功能：
  - 扩展 ArticleRenderer 支持翻译
  - 段落级 HTML 翻译
  - 双语和纯译文两种渲染模式
  - 自动缓存翻译结果

#### 时间线标题翻译
- 位置：`Shared/Extensions/ArticleStringFormatter+Translation.swift`
- 功能：
  - 扩展 ArticleStringFormatter 支持标题翻译
  - 异步获取翻译标题
  - 自动缓存

#### CSS 样式
- 位置：`Shared/Article Rendering/stylesheet.css`
- 新增样式类：
  - `.translated-title` - 翻译标题样式
  - `.translation` - 翻译内容样式
  - 支持浅色和深色模式

## 使用方法

### 启用 Feed 翻译

1. 右键点击 Feed，选择"Get Info"（Mac）或点击 Feed 后选择"Get Info"（iOS）
2. 勾选/打开"启用翻译"选项
3. 翻译将根据应用级设置自动应用

### 配置翻译设置

**macOS：**
1. 打开偏好设置（⌘,）
2. 进入翻译标签页
3. 选择目标语言（或保持系统语言）
4. 选择翻译模式（双语对照或纯译文）

**iOS：**
1. 打开设置
2. 进入翻译部分
3. 选择目标语言（或保持系统语言）
4. 选择翻译模式（双语对照或纯译文）

### 翻译模式说明

**双语对照模式：**
- 显示原文和译文
- 文章标题显示两个版本
- 文章内容在原文段落下方显示译文
- 译文使用视觉样式区分

**纯译文模式：**
- 仅显示译文
- 替换原始内容
- 不显示原文

## 技术特点

### 缓存策略

1. **内存缓存**：快速访问最近翻译的内容
2. **磁盘缓存**：持久化存储，应用重启后可用
3. **缓存键格式**：`{文章ID}_{内容类型}_{目标语言}`

### 支持的语言

- 英语 (en)
- 简体中文 (zh-Hans)
- 繁体中文 (zh-Hant)
- 日语 (ja)
- 韩语 (ko)
- 西班牙语 (es)
- 法语 (fr)
- 德语 (de)
- 意大利语 (it)
- 葡萄牙语 (pt)
- 俄语 (ru)
- 阿拉伯语 (ar)
- 印地语 (hi)
- 泰语 (th)
- 越南语 (vi)

## 系统要求

- iOS 15.0+ 或 macOS 12.0+
- 需要网络连接（首次翻译特定语言对时）
- 需要存储空间用于翻译模型和缓存

## 集成步骤（Xcode 中需要完成）

### 1. 添加文件到项目
- 将所有新的 Swift 文件添加到适当的 target
- 确保 Translation 文件夹的文件包含在 Mac 和 iOS target 中

### 2. 更新界面构建器文件

**Mac Feed Inspector XIB：**
需要添加翻译复选框并连接 outlet 和 action

**iOS Feed Inspector Storyboard：**
需要添加翻译开关并连接 outlet 和 action

### 3. 创建偏好设置 UI

**Mac：**
- 为 TranslationPreferencesViewController 创建 XIB
- 添加到 PreferencesWindowController 的标签页

**iOS：**
- 将 TranslationSettingsViewController 添加到设置导航
- 更新 Settings.storyboard

### 4. 更新文章渲染

在文章详情视图控制器中使用新的翻译感知渲染：

```swift
// 替换原来的：
let rendering = ArticleRenderer.articleHTML(article: article, theme: theme)

// 使用新的：
let rendering = await ArticleRenderer.articleHTMLWithTranslation(
    article: article, 
    theme: theme, 
    feed: feed
)
```

### 5. 更新时间线加载

修改时间线数据加载以使用翻译感知的单元格数据：

```swift
// 替换原来的：
let cellData = TimelineCellData(article: article, ...)

// 使用新的：
let cellData = await TimelineCellData.withTranslation(
    article: article, 
    ..., 
    feed: feed
)
```

## 文件清单

### 核心翻译功能
- `Shared/Translation/TranslationManager.swift` - 翻译管理器
- `Shared/Translation/TranslationCache.swift` - 翻译缓存

### 数据模型扩展
- `Mac/AppDefaults.swift` - Mac 应用设置扩展
- `iOS/AppDefaults.swift` - iOS 应用设置扩展
- `Modules/Account/Sources/Account/FeedMetadata.swift` - Feed 元数据扩展
- `Modules/Account/Sources/Account/Feed.swift` - Feed 模型扩展

### UI 组件
- `Mac/Inspector/FeedInspectorViewController.swift` - Mac Feed 检查器
- `iOS/Inspector/FeedInspectorViewController.swift` - iOS Feed 检查器
- `Mac/Preferences/Translation/TranslationPreferencesViewController.swift` - Mac 翻译偏好设置
- `iOS/Settings/TranslationSettingsViewController.swift` - iOS 翻译设置

### 翻译集成
- `Shared/Article Rendering/ArticleRenderer+Translation.swift` - 文章渲染翻译扩展
- `Shared/Extensions/ArticleStringFormatter+Translation.swift` - 字符串格式化翻译扩展
- `Mac/MainWindow/Timeline/Cell/TimelineCellData.swift` - Mac 时间线单元格数据
- `iOS/MainTimeline/Cells/MainTimelineCellData.swift` - iOS 时间线单元格数据

### 样式
- `Shared/Article Rendering/stylesheet.css` - 翻译样式

### 文档
- `TRANSLATION_FEATURE.md` - 英文详细文档
- `TRANSLATION_FEATURE_CN.md` - 中文说明文档（本文件）

## 待测试项目

- [ ] Feed 检查器中显示翻译开关（Mac 和 iOS）
- [ ] 偏好设置/设置中显示翻译选项（Mac 和 iOS）
- [ ] 语言选择功能正常
- [ ] 翻译模式切换功能正常
- [ ] 启用 Feed 翻译后时间线标题被翻译
- [ ] 查看文章时内容被翻译
- [ ] 双语模式同时显示原文和译文
- [ ] 纯译文模式仅显示译文
- [ ] 翻译结果被缓存并重用
- [ ] 缓存在应用重启后保持
- [ ] 翻译在浅色和深色模式下都正常工作
- [ ] 翻译样式视觉效果良好
- [ ] 启用翻译时性能可接受
- [ ] 翻译过程中无崩溃或错误

## 注意事项

1. **首次翻译延迟**：首次使用特定语言对时可能需要下载语言模型
2. **离线功能**：首次使用语言对时需要网络连接
3. **HTML 保留**：复杂的 HTML 结构可能无法保留所有格式
4. **翻译质量**：取决于 Apple Translation Framework 的质量

## 后续改进方向

1. 手动触发重新翻译
2. 翻译历史记录
3. 自定义源-目标语言对
4. 选择性翻译（仅标题或仅内容）
5. 翻译指示器
6. 离线模型预下载
7. 翻译统计信息
8. 后台批量翻译

## 问题排查

### 翻译不工作

1. 检查 Feed 是否启用了翻译
2. 验证网络连接
3. 检查目标语言设置是否正确
4. 清除翻译缓存后重试
5. 确认设备支持 Apple Translation Framework

### 翻译质量差

1. 尝试不同的目标语言
2. 检查源内容是否干净（无过多 HTML）
3. 通过反馈助理向 Apple 报告问题

### 性能问题

1. 如果缓存过大，清除翻译缓存
2. 对包含很长文章的 Feed 禁用翻译
3. 使用纯译文模式而不是双语模式

## 技术支持

如有问题或疑问：
1. 查阅本文档
2. 查看代码中的内联注释
3. 参考 Apple Translation Framework 文档
4. 在 NetNewsWire 仓库中创建 issue
