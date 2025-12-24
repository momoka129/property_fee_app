# 智慧物业管理系统 Smart Property Management App

## 📱 项目简介

这是一个功能完整的物业管理移动应用，使用Flutter开发，不依赖后端数据库，完全基于本地数据运行。适合作为毕业设计项目或原型演示。

**作者**: 黄天竞 (Huang Tianjing)  
**学号**: SWE2209518  
**学校**: 厦门大学马来西亚分校

## ✨ 主要功能

### 1. 📊 仪表盘
- 实时显示未支付账单统计
- 待取包裹提醒
- 紧急通知展示
- 社区公告滚动展示
- 快速功能入口

### 2. 💰 账单管理
- 查看所有未支付/已支付账单
- 账单详情查看
- 支付模拟功能
- 账单分类（物业费、停车费、水电费等）
- 逾期账单提醒

### 3. 🔧 报修维护
- 在线提交维修请求
- 上传问题照片
- 实时追踪维修进度
- 维修历史记录
- 优先级设置（紧急/高/中/低）

### 4. 📢 社区公告
- 浏览社区通知
- 活动预告
- 设施维护通知
- 紧急公告
- 图文并茂展示

### 5. 👥 访客管理
- 预约访客
- 生成访客二维码
- 访客签到/签退
- 访客历史记录
- 车辆登记

### 6. 📦 包裹管理
- 包裹到达通知
- 快递公司信息
- 取件码显示
- 包裹照片查看
- 待取包裹列表

### 7. 🏊 设施预订
- 游泳池
- 健身房
- 多功能厅
- 网球场
- 烧烤区
- 儿童游乐场
- 设施详情和开放时间
- 在线预订功能

### 8. 🚗 停车管理
- 查看停车位信息
- 车辆登记管理
- 月费记录
- 访客停车位

### 9. 👤 个人中心
- 用户资料展示
- 房产信息
- 设置选项
- 帮助与支持

## 🎨 技术亮点

1. **Material Design 3** - 现代化UI设计
2. **网络图片加载** - 使用cached_network_image加载和缓存图片
3. **流畅动画** - 自定义过渡动画和微交互
4. **响应式布局** - 适配不同屏幕尺寸
5. **本地数据模拟** - 完整的数据模型和模拟数据
6. **优雅的错误处理** - 用户友好的提示信息

## 📦 依赖包

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1           # 字体
  cupertino_icons: ^1.0.8        # iOS图标
  provider: ^6.1.1                # 状态管理
  intl: ^0.19.0                  # 国际化和日期格式化
  shared_preferences: ^2.2.2      # 本地存储
  flutter_staggered_grid_view: ^0.7.0  # 瀑布流布局
  cached_network_image: ^3.3.1    # 网络图片缓存
  shimmer: ^3.0.0                 # 加载动画效果
  fl_chart: ^0.66.2               # 图表
  image_picker: ^1.0.7            # 图片选择
  qr_flutter: ^4.1.0              # 二维码生成
  url_launcher: ^6.2.4            # URL启动
```

## 🚀 快速开始

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd property_fee_app
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行项目

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## 📁 项目结构

```
lib/
├── data/                   # 数据层
│   └── mock_data.dart     # 模拟数据
├── models/                # 数据模型
│   ├── user_model.dart
│   ├── bill_model.dart
│   ├── repair_model.dart
│   ├── announcement_model.dart
│   ├── package_model.dart
│   └── parking_model.dart
├── screens/               # 界面页面
│   ├── home.dart          # 主页
│   ├── bills_screen.dart  # 账单
│   ├── repairs_screen.dart # 报修
│   ├── announcements_screen.dart # 公告
│   ├── packages_screen.dart # 包裹
│   └── parking_screen.dart # 停车
├── widgets/               # 自定义组件
│   ├── bill_card.dart
│   └── section_header.dart
├── app_theme.dart         # 主题配置
├── routes.dart            # 路由配置
└── main.dart              # 入口文件
```

## 🎯 功能演示

### 主页截图
- 用户欢迎卡片
- 快速统计卡片（未付账单、待取包裹）
- 重要提醒（逾期账单、待处理报修）
- 社区公告卡片
- 快速功能入口网格

### 账单管理
- 未支付/已支付标签页
- 账单卡片显示
- 总欠费金额统计
- 一键支付所有账单
- 账单详情弹窗

### 报修系统
- 待处理/已完成标签页
- 报修请求卡片（带图片）
- 状态标签（待处理/进行中/已完成）
- 优先级标签
- 新建报修表单

## 🌐 网络图片来源

项目使用以下免费图片资源：
- **Unsplash** - 高质量免版权图片
- **Pravatar** - 头像占位图
- 所有图片均通过URL动态加载

图片分类：
- 社区公告图片
- 设施展示图片（游泳池、健身房等）
- 包裹照片
- 报修问题照片

## 📊 数据模型说明

### 用户模型 (UserModel)
- 基本信息：姓名、邮箱、电话
- 房产信息：单元号、地址
- 角色：居民/管理员
- 头像URL

### 账单模型 (BillModel)
- 账单标题和描述
- 金额
- 账单日期和到期日
- 状态：未支付/已支付/逾期
- 分类：物业费、停车费、水电费等

### 报修模型 (RepairModel)
- 问题描述
- 照片列表
- 状态：待处理/进行中/已完成
- 优先级：紧急/高/中/低
- 位置信息
- 指派维修人员

### 其他模型
- 公告、访客、包裹、设施、停车位等

## 🔄 数据更新

所有数据存储在 `lib/data/mock_data.dart` 中：

```dart
// 修改用户信息
MockData.currentUser = UserModel(...);

// 添加新账单
MockData.bills.add(BillModel(...));

// 更新报修状态
// 直接修改MockData中的对应数据
```

## 🎨 自定义主题

在 `lib/app_theme.dart` 中修改主题颜色：

```dart
colorSchemeSeed: const Color(0xFF2E7D32), // 更改主色调
```

## 📝 待扩展功能

- [ ] 本地数据持久化（SharedPreferences）
- [ ] 推送通知
- [ ] 多语言支持（中文/英文切换）
- [ ] 深色模式
- [ ] 数据导出功能
- [ ] 社区论坛/聊天
- [ ] 智能设备控制

## 🐛 已知问题

- 部分图片加载可能需要网络连接
- 支付功能为模拟实现，不涉及真实交易

## 📄 许可证

此项目仅供教育和学习用途。

## 👨‍💻 开发者

**黄天竞** (Huang Tianjing)  
厦门大学马来西亚分校 - 软件工程专业  
学号: SWE2209518  
邮箱: swe2209518@xmu.edu.my

---

### 运行截图

由于这是本地模拟数据项目，所有功能都可以在无需配置数据库的情况下直接运行！

```bash
flutter run
```

即可体验完整功能！🎉












