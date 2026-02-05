# 🎯 Body Tracker

A comprehensive Flutter application for tracking body measurements, visual progress, and health goals. Designed with privacy and flexibility in mind, featuring local-first storage with optional cloud synchronization.

## ✨ Features

- **📏 Measurement Tracking**: Track weight, height, chest, waist, hips, and more with a guided step-by-step measurement flow.
- **🖼️ Progress Photos**: Securely store progress photos associated with your weight. Compare photos side-by-side to visualize your journey.
- **📊 Detailed Analytics**: View progress charts and complete measurement history for every body part.
- **🎯 Goal Setting**: Set target values and dates for your measurements and track your progress with visual indicators.
- **👥 Multiple Profiles**: Support for multiple users within the same app—perfect for partners or families.
- **👗 Clothing Size Guide**: Get suggested clothing sizes (tops and pants) based on your latest body measurements (Men/Women).
- **☁️ Cloud Backup**: Securely back up your data to your private Google Drive (App Data folder) to keep your measurements and photos safe and private.
- **🔔 Reminders**: Configurable push notifications to stay consistent with your measurements.
- **🎨 Customizable Navigation**: Choose which tabs appear in the bottom navigation bar and reorder them to suit your workflow.
- **💾 Backup & Restore**: Export all your data as a ZIP file for local backups or use Google Drive sync.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Local Database**: [SQLite](https://pub.dev/packages/sqflite)
- **Cloud Backend**: [Google Drive API](https://developers.google.com/drive) (App Data Folder)
- **Charts**: [FL Chart](https://pub.dev/packages/fl_chart)
- **Notifications**: [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- A Firebase project (for cloud sync features)

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/Tentacle-Development/body-tracker.git
    cd body-tracker
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Run the app**:
    ```bash
    flutter run
    ```

## 🤖 AI Assisted Development

This project was developed with the assistance of **OpenClaw**, an agentic AI coding partner. Features like the database architecture, photo comparison logic, and the cloud sync system were designed and implemented through collaborative AI pair-programming.

## 📄 License

This project is proprietary and intended for private use.
