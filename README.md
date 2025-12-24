# Property Fee Management App 物业费管理系统

A comprehensive mobile application for property fee management designed for Chinese residential communities, developed as a Final Year Project (FYP) by Huang Tianjing (SWE2209518).

## 项目简介 Project Overview

This Flutter-based mobile application aims to digitalize and streamline property fee management in residential communities, providing residents with convenient bill viewing and payment features, while offering property managers efficient administrative tools.

本项目是一个基于Flutter开发的物业费管理移动应用，旨在数字化和简化住宅小区的物业费管理，为居民提供便捷的账单查看和支付功能，同时为物业管理人员提供高效的管理工具。

## 主要功能 Key Features

### 居民功能 Resident Features
- 🔐 **User Authentication**: Secure login and registration with Firebase Auth
- 📱 **Dashboard**: View unpaid bills and payment status at a glance
- 💰 **Bill Management**: View detailed bill information and payment history
- 💳 **Payment Simulation**: Simulated payment process supporting WeChat Pay, Alipay, and Bank Transfer
- 📜 **Payment History**: Track all payment records and bill history
- 👤 **Profile Management**: View and edit personal information
- 🔔 **Notifications**: (Coming soon) Payment reminders and notifications

### 管理员功能 Admin Features
- 📊 **Admin Dashboard**: Overview of bills, payments, and revenue statistics
- 📝 **Bill Creation**: Create and manage bills for residents
- 👥 **User Management**: View all residents and their property information
- 💼 **Payment Tracking**: Monitor all payments and transactions
- 🗑️ **Bill Management**: Delete or modify bills as needed

## 技术栈 Tech Stack

- **Frontend**: Flutter 3.8.0+
- **Backend**: Firebase
  - Firebase Authentication (User login/registration)
  - Cloud Firestore (Data storage)
  - Firebase Database (Real-time updates)
- **State Management**: StatefulWidget (可扩展为Provider/Riverpod)
- **UI/UX**: Material Design 3
- **Typography**: Google Fonts (Inter)

## 项目结构 Project Structure

```
lib/
├── models/              # 数据模型
│   ├── user_model.dart
│   ├── bill_model.dart
│   └── payment_model.dart
├── services/            # Firebase服务层
│   ├── auth_service.dart
│   ├── bill_service.dart
│   └── payment_service.dart
├── screens/             # 界面页面
│   ├── login.dart
│   ├── register.dart
│   ├── home.dart
│   ├── bill_detail.dart
│   ├── payment_screen.dart
│   ├── history.dart
│   ├── profile.dart
│   ├── admin_panel.dart
│   └── create_bill_screen.dart
├── widgets/             # 自定义组件
│   ├── bill_card.dart
│   └── section_header.dart
├── app_theme.dart       # 主题配置
├── routes.dart          # 路由配置
├── firebase_options.dart
└── main.dart            # 应用入口
```

## 安装与运行 Installation & Setup

### 前置要求 Prerequisites
- Flutter SDK 3.8.0 or higher
- Dart 3.0.0 or higher
- Android Studio / VS Code
- Firebase account

### 安装步骤 Installation Steps

1. **克隆项目 Clone the repository**
```bash
git clone <repository-url>
cd property_fee_app
```

2. **安装依赖 Install dependencies**
```bash
flutter pub get
```

3. **配置Firebase Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android/iOS apps to your Firebase project
   - Download and add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Run Firebase FlutterFire configuration:
```bash
flutterfire configure
```

4. **配置Firestore规则 Set up Firestore Rules**
   在Firebase Console中设置以下Firestore规则:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /accounts/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null &&
                    get(/databases/$(database)/documents/accounts/$(request.auth.uid)).data.role == 'admin';
    }

    match /bills/{billId} {
      allow read: if request.auth != null &&
                    (resource.data.userId == request.auth.uid ||
                     get(/databases/$(database)/documents/accounts/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/accounts/$(request.auth.uid)).data.role == 'admin';
    }

    match /payments/{paymentId} {
      allow read: if request.auth != null &&
                    (resource.data.userId == request.auth.uid ||
                     get(/databases/$(database)/documents/accounts/$(request.auth.uid)).data.role == 'admin');
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }

    match /announcements/{announcementId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/accounts/$(request.auth.uid)).data.role == 'admin';
    }

    match /packages/{packageId} {
      allow read: if request.auth != null &&
                    (resource.data.userId == request.auth.uid ||
                     get(/databases/$(database)/documents/accounts/$(request.auth.uid)).data.role == 'admin');
      allow write: if request.auth != null &&
                     get(/databases/$(database)/documents/accounts/$(request.auth.uid)).data.role == 'admin';
    }
  }
}
```

5. **运行应用 Run the app**
```bash
flutter run
```

## 测试账号 Test Accounts

### 居民账号 Resident Account
- Email: `resident@test.com`
- Password: `123456`

### 管理员账号 Admin Account  
- Email: `admin@test.com`
- Password: `123456`

**注意**: 需要在Firebase Console中手动创建这些测试账号，并在Firestore的`users`集合中设置相应的用户信息和角色。

## 功能演示 Feature Demonstration

### 居民端流程 Resident Flow
1. 注册/登录账号
2. 查看主页显示的未支付账单
3. 点击账单查看详细信息
4. 选择支付方式（微信/支付宝/银行转账）
5. 模拟支付流程
6. 查看支付历史记录

### 管理员端流程 Admin Flow
1. 使用管理员账号登录
2. 访问管理面板
3. 查看统计数据（账单、支付、收入）
4. 创建新账单并分配给居民
5. 查看所有账单和支付记录
6. 管理账单（删除等操作）

## 数据模型 Data Models

### User Model
```dart
- id: String
- email: String
- name: String
- phoneNumber: String?
- propertyUnit: String
- propertyAddress: String
- role: String (resident/admin)
- createdAt: DateTime
```

### Bill Model
```dart
- id: String
- userId: String
- title: String
- description: String
- amount: double
- dueDate: DateTime
- billingDate: DateTime
- status: String (unpaid/paid/overdue)
- category: String
- paymentId: String?
```

### Payment Model
```dart
- id: String
- userId: String
- billId: String
- amount: double
- paymentDate: DateTime
- paymentMethod: String (wechat/alipay/bank_transfer)
- transactionId: String
- status: String (success/pending/failed)
```

## 依赖包 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.1
  cupertino_icons: ^1.0.8
  firebase_core: ^4.2.0
  cloud_firestore: ^6.0.3
  firebase_auth: ^6.1.1
  firebase_database: ^12.1.1
```

## 开发进度 Development Progress

- [x] 用户认证系统（登录、注册）
- [x] 主页仪表板
- [x] 账单查看与详情
- [x] 支付模拟功能
- [x] 支付历史记录
- [x] 个人资料管理
- [x] 管理员面板
- [x] 账单创建与管理
- [ ] 推送通知
- [ ] 多语言支持
- [ ] 数据导出功能

## 注意事项 Important Notes

1. **支付模拟**: 本应用的支付功能为模拟实现，不涉及真实的金融交易。
2. **数据安全**: 请确保在生产环境中配置适当的Firebase安全规则。
3. **测试数据**: 开发阶段建议使用测试数据，避免真实用户信息泄露。

## 致谢 Acknowledgments

This project is developed as part of the Final Year Project (FYP) at Xiamen University Malaysia under the supervision of Dr. Noor Hafizah Binti Ismail.

本项目是在厦门大学马来西亚分校Dr. Noor Hafizah Binti Ismail博士的指导下完成的毕业设计项目。

## 许可证 License

This project is for educational purposes only.

## 联系方式 Contact

- **Student**: Huang Tianjing
- **Student ID**: SWE2209518
- **Email**: swe2209518@xmu.edu.my

---

© 2025 Xiamen University Malaysia - School of Computing and Data Science
