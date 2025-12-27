# Smart Property Management App

## 📱 Project Overview

This is a comprehensive property management mobile application developed with Flutter, running on local mock data without requiring a backend database. Suitable for graduation projects or prototype demonstrations.

**Author**: Huang Tianjing (黄天竞)  
**Student ID**: SWE2209518  
**School**: Xiamen University Malaysia  
**Major**: Software Engineering

## ✨ Main Features

### 1. 🔐 User Authentication System
- Support for resident and admin dual-role login
- Quick account filling functionality
- Password visibility toggle

### 2. 📊 Home Dashboard
- Personalized user greeting
- Real-time statistics cards (unpaid bills, total arrears, pending packages)
- Emergency notifications
- Community announcements preview
- Quick function entries
- Bottom navigation bar

### 3. 💰 Bill Management System
- Bill classification display (unpaid/overdue/paid)
- Bill detail viewing
- Simulated payment functionality (WeChat/Alipay/Bank Transfer)
- Overdue bill automatic processing
- Penalty calculation

### 4. 🔧 Repair Management System
- Online repair request submission
- Photo upload functionality
- Progress status tracking
- Priority settings (emergency/high/medium/low)
- Repair history records

### 5. 📦 Package Management System
- Package status classification (pending/picked up)
- Courier company information display
- Package photo viewing
- Location information display
- Mark as picked up function

### 6. 📢 Community Announcement System
- Announcement filtering functions (status/priority)
- Classification display (events/maintenance/notices/facilities/emergency)
- Announcement detail viewing
- Rich text display

### 7. 👤 Personal Center
- User profile display and management
- Password change functionality
- Help & support
- About page

### 8. 👨‍💼 Admin Functions
- Statistical dashboard
- User management interface
- Bill statistics viewing
- Repair request management
- Package status monitoring

## 🎨 Technical Highlights

1. **Material Design 3** - Modern UI design
2. **Network Image Loading** - Image caching and loading using cached_network_image
3. **Smooth Animations** - Custom transition animations and micro-interactions
4. **Responsive Layout** - Adapts to different screen sizes
5. **Local Data Simulation** - Complete data models and mock data
6. **Elegant Error Handling** - User-friendly error messages

## 📦 Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # UI related
  google_fonts: ^6.2.1                    # Google Fonts
  cupertino_icons: ^1.0.8                 # iOS Icons
  flutter_staggered_grid_view: ^0.7.0     # Staggered Grid Layout

  # State management
  provider: ^6.1.1                        # Provider State Management

  # Utilities
  intl: ^0.20.2                           # Date and Internationalization
  shared_preferences: ^2.2.2              # Local Storage

  # Network and Images
  cached_network_image: ^3.3.1            # Network Image Caching
  url_launcher: ^6.2.4                    # URL Launcher

  # UI Enhancements
  shimmer: ^3.0.0                         # Loading Animations

  # Image Processing
  image_picker: ^1.0.7                    # Image Picker

  # QR Code
  qr_flutter: ^4.1.0                      # QR Code Generation

  # Charts
  fl_chart: ^1.1.1                        # Chart Library

  # Firebase related
  firebase_core: ^4.2.0                   # Firebase Core
  cloud_firestore: ^6.0.3                 # Firestore Database
  firebase_auth: ^6.1.1                   # Firebase Authentication

  # Payment
  flutter_stripe: ^12.1.1                 # Stripe Payment
  pinput: ^2.3.0                          # PIN Input Component
```

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd property_fee_app
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run Project

```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

## 📁 Project Structure

```
lib/
├── data/                   # Data Layer
│   └── mock_data.dart     # Mock Data
├── models/                # Data Models
│   ├── user_model.dart    # User Model
│   ├── bill_model.dart    # Bill Model
│   ├── repair_model.dart  # Repair Model
│   ├── announcement_model.dart # Announcement Model
│   ├── package_model.dart # Package Model
│   ├── parking_model.dart # Parking Model
│   └── payment_model.dart # Payment Model
├── screens/               # UI Screens
│   ├── home.dart          # Home Page
│   ├── home_tabs/         # Home Tabs
│   ├── login_screen.dart  # Login Screen
│   ├── bills_screen.dart  # Bill Management
│   ├── repairs_screen.dart # Repair Management
│   ├── announcements_screen.dart # Announcement Management
│   ├── packages_screen.dart # Package Management
│   ├── admin_home_screen.dart # Admin Home
│   └── edit_profile_screen.dart # Profile Editing
├── services/              # Services Layer
│   ├── firestore_service.dart # Firebase Service
│   └── avatar_service.dart # Avatar Service
├── providers/             # State Management
│   └── app_provider.dart  # App State
├── utils/                 # Utilities
│   ├── url_utils.dart     # URL Utilities
│   └── bill_message.dart  # Bill Messages
├── widgets/               # Custom Widgets
│   ├── bill_card.dart     # Bill Card
│   ├── glass_container.dart # Glass Container
│   └── section_header.dart # Section Header
├── app_theme.dart         # Theme Configuration
├── routes.dart            # Route Configuration
└── main.dart              # Application Entry
```

## 🎯 Feature Demonstration

### User Authentication
- Login interface dual role account selection
- Resident account experience daily functions
- Admin account view management panel

### Home Dashboard
- Personalized greeting and user information
- Real-time statistics: unpaid bills count, total arrears amount, pending packages count
- Emergency reminders: overdue bills, pending repairs
- Community announcements preview (latest 3)
- Function entries grid (bills, repairs, announcements, packages)

### Bill Management System
- Three tabs: unpaid bills/overdue bills/paid bills
- Bill cards: display amount, due date, category labels
- Detail page: complete bill information and payment options
- Payment process: select payment method (WeChat/Alipay/Bank Transfer)
- Overdue processing: automatic penalty calculation

### Repair Management System
- Repair list: status classification display
- Repair details: problem description, photos, progress tracking
- Submission form: title, description, location, priority, photo upload
- Status management: pending → in progress → completed
- Worker assignment: display maintenance personnel information

### Package Management System
- Status classification: pending packages/picked up packages
- Package information: courier company, arrival time, location, photos
- Operation functions: mark as picked up
- Statistical information: waiting days

### Admin Functions
- Statistical dashboard: chart display of various data
- User management: view resident information
- Bill monitoring: view all property bill statistics
- Repair management: handle all repair requests
- Package monitoring: monitor all property package status

## 🌐 Network Image Resources

The project uses the following free image resources:
- **Unsplash** - High-quality copyright-free images
- **Pravatar** - Avatar placeholder images
- All images are loaded and cached dynamically through URLs

Images currently used:
- User avatars (dynamically generated)
- Repair problem photos (kitchen leaks, air conditioning, door locks, etc.)
- Package photos (courier package physical objects)
- Community announcement pictures (reserved, current data empty)

## 📊 Data Model Descriptions

### User Model (UserModel)
- Basic information: ID, name, email, phone
- Property information: unit address
- Role distinction: resident(admin)/admin(admin)
- Avatar URL and registration time

### Bill Model (BillModel)
- Bill information: title, description, amount, penalty
- Time information: bill date, due date
- Status management: unpaid/paid/overdue
- Category labels: property fee, parking fee, utilities, etc.
- Payment association: payment ID record

### Repair Model (RepairModel)
- Repair details: title, description, location, priority
- Status tracking: pending/in progress/completed/cancelled/rejected
- Image support: multiple problem photos
- Worker assignment: worker name, ID, appointment time
- Rejection processing: rejection reason record

### Package Model (PackageModel)
- Basic information: tracking number, courier company, arrival time
- Status management: pending/picked up
- Location information: storage location description
- Photo display: physical package photos

### Announcement Model (AnnouncementModel)
- Announcement content: title, content, author, publication date
- Category labels: events/maintenance/notices/facilities/emergency
- Priority: high/medium/low
- Status management: upcoming/ongoing/expired

### Payment Model (PaymentModel)
- Payment information: amount, method, status
- Time records: payment time, creation time
- Association information: bill ID, user ID

## 🔄 Data Updates

All data is stored in `lib/data/mock_data.dart`:

### Current Data Scale
- **User Accounts**: 2 (1 resident + 1 admin)
- **Bill Records**: 5 (including unpaid, paid, overdue statuses)
- **Repair Records**: 3 (different statuses and priorities)
- **Package Records**: 3 (pending and picked up statuses)
- **Announcement Records**: 0 (interface completed, data can be added)
- **Parking Records**: 1 (data model completed, interface placeholder)

### Data Modification Examples
```dart
// Modify current user information
MockData.currentUser = UserModel(
  name: 'New Username',
  email: 'new.email@example.com',
  // ... other fields
);

// Add new bill
MockData.bills.add(BillModel(
  id: 'bill_new',
  userId: 'user_001',
  title: 'New Bill Title',
  amount: 100.0,
  // ... other fields
));

// Update repair status
final repairIndex = MockData.repairs.indexWhere((r) => r.id == 'repair_001');
if (repairIndex != -1) {
  MockData.repairs[repairIndex] = MockData.repairs[repairIndex].copyWith(
    status: 'completed'
  );
}
```

## 🎨 Custom Theme

Modify theme colors in `lib/app_theme.dart`:

```dart
colorSchemeSeed: const Color(0xFF2E7D32), // Change main theme color
```

## 📝 Feature Extension Directions

### Planned but not implemented features
- [ ] Visitor management system (appointment, check-in, QR code)
- [ ] Facility booking system (swimming pool, gym, etc.)
- [ ] Parking management functions (parking space viewing, fee management)
- [ ] Multi-language support (Chinese/English switching)

### Technical optimization directions
- [ ] Local data persistence (SharedPreferences/SQLite)
- [ ] Push notification integration
- [ ] Dark mode theme
- [ ] Data export functions (PDF/Excel)
- [ ] Image local cache optimization
- [ ] Offline mode support

## 🐛 Known Issues

- Some images may require network connection for loading
- Payment functionality is simulated and does not involve real transactions

## 📄 License

This project is intended for educational and learning purposes only.

## 👨‍💻 Developer

**Huang Tianjing (黄天竞)**  
Xiamen University Malaysia - Software Engineering  
Student ID: SWE2209518  
Email: swe2209518@xmu.edu.my

---

## 🎯 Project Highlights Summary

✅ **Core Functions Complete** - 6 implemented modules, 2 interface completed modules  
✅ **Zero Configuration** - No database required, ready to use out of the box  
✅ **Professional UI** - Material Design 3, modern design  
✅ **Real Data** - Rich mock data, close to real scenarios  
✅ **Easy to Extend** - Clear architecture, easy for secondary development  
✅ **Complete Documentation** - Detailed Chinese and English documentation  

### Technical Implementation Statistics
- **Total Code Lines**: ~6000+ lines
- **Interface Files**: 15+ screens
- **Data Models**: 10 complete model classes
- **Core Function Modules**: 8 main functions
- **Dependencies**: 17 core packages
- **Test Accounts**: 2 accounts

### How to Run

Since this is a local mock data project, all implemented functions can run without configuring a database!

```bash
flutter run
```

Experience the complete functions! 🎉