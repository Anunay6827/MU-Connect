![MU (2)](https://github.com/user-attachments/assets/031ad6f3-e82d-4c49-a181-3f023d66329e)

# MU-Connect 📱

Welcome to **MU-Connect** — your one-stop social platform designed exclusively for the Mahindra University community.

This repository contains everything you need to know to understand, explore, and run the app on your local device.

---

## 🔗 Quick Links

- 🎥 [Team Presentation Pitch Video](https://drive.google.com/file/d/1NORfbxyUyZkOAuYEZ-gPo2XpyZ9901h-/view?usp=drive_link)
- 📘 Detailed Codebase Explanation: *[Coming Soon]*  
- 📂 [Documentations Folder](./Documentations)  
  Contains: Software Requirements Specification (SRS), Software Design Document (SDD), and Test Plan  
- 🗂️ [Diagrams Folder](./Diagrams)  
  Contains: Use Case Diagrams, State Charts, Activity Diagrams, and more

---

## 📲 Install the App

Download the **MU-Connect.apk** on your Android mobile device and install it to join the MU community.

> ⚠️ *Account creation is currently restricted to users with a Mahindra University email ID (domain: `mahindrauniversity.edu.in`).*

---

## 🚀 How to Run Locally

### ✅ Prerequisites

- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- [TypeScript](https://www.typescriptlang.org/)
- [PostgreSQL](https://www.postgresql.org/)

### 📦 Setup Instructions

1. **Create a Flutter project locally**  
   Open a terminal and run:
   ```bash
   flutter create MU-Connect

 2. **Replace Project Files**
Navigate to the created folder.

Now, copy and replace all matching files and folders from the Frontend directory of this repository.
Keep other default files like assets/ and plugin files unchanged.

3. **Backend Setup**
Place the contents of the backend folder anywhere in your local directory.

Replace the Supabase API key in the backend files with your own key from your Supabase project.

4. **Run the App**
Connect a physical Android device or use an emulator.
Navigate to the MU-Connect/ directory and run:
```bash
flutter run
