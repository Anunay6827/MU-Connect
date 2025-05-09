![MU (2)](https://github.com/user-attachments/assets/031ad6f3-e82d-4c49-a181-3f023d66329e)


# MU-Connect 📱

Welcome to the GitHub repository for **MU-Connect**, a student-centered social networking app designed for the Mahindra University community.

---

## 🚀 About MU-Connect

MU-Connect is a dedicated platform for students to:
- Share posts and media with their peers
- Chat in real time with individuals and groups
- Receive campus-wide notifications and updates

> Account creation is available exclusively for users with a Mahindra University email ID.

---

## 📱 Try It Out

Download the latest `mu-connect.apk` file and install it on your Android device to join the MU community!

🎥 **Presentation Pitch Video**: [Watch here](https://drive.google.com/file/d/1NORfbxyUyZkOAuYEZ-gPo2XpyZ9901h-/view?usp=drive_link)

📥 **A detailed breakdown of our code, and a complete demo of our app:** (TBD)


📚 **Documentation**:  
- SRS, SDD, Test Plan – located in the `Documentations/` folder  
- UML Diagrams – available in the `Diagrams/` folder  

---

## 📁 Code Contents

Here's a high-level overview of the key files and folders:

### Backend (`Backend/`)

- `supabase/`  
  Contains configuration files and function handlers that serve as endpoints for various features.

- `database.sql`  
  PostgreSQL script to initialize your own local database instance.

- `mu-connect.postman_collection.json`  
  Postman collection to test, debug, and understand all API endpoints and responses.

### Frontend (`Frontend/`)

- `pubspec.yaml`  
  Defines Flutter/Dart dependencies and assets for the application.

- `android/`  
  Contains Gradle configuration and Android-specific settings to run the app smoothly on Android devices.

- `lib/`  
  Main source directory with app logic, screen UIs, models, services, and modules.

---

## 🛠 Local Development Guide

## Prerequisites

Ensure you have the following tools installed:

- **[Flutter SDK](https://flutter.dev/docs/get-started/install)**
- **[Dart SDK](https://dart.dev/get-dart)**
- **[Android Studio](https://developer.android.com/studio)** or **[VS Code](https://code.visualstudio.com/)**
- **[TypeScript](https://www.typescriptlang.org/)**
- **[PostgreSQL](https://www.postgresql.org/)**
- **[SUPABASE CLI](https://supabase.com/docs/guides/local-development/cli/getting-started)**
- **[DENO](https://docs.deno.com/runtime/getting_started/installation/)**

## 1. Set Up the Project

### Frontend Setup

1. **Copy the Frontend Folder**
   - Copy the `Frontend` folder into your local development setup.

2. **Open the Project**
   - Open the project in **Android Studio** or **VS Code**.

3. **Install Dependencies**
   - Open the terminal and run the following command to install the required dependencies:
   ```bash
   flutter pub get
   ```

4. **Configure Supabase**
   - Open the `lib` folder and locate the `main.dart` file.
   - Replace the **URL** and **ANON keys** in the file with your Supabase backend configuration.

5. **Run the App**
   - Connect your Android device or launch the Android Emulator.
   - Run the following command to simulate the application:
   ```bash
   flutter run
   ```

### Backend Setup

1. **Create a Supabase Account**
   - Sign up for a **Supabase** account at [supabase.com](https://supabase.com/).
   - Start a new project on the Supabase dashboard.

2. **Set Up the Database**
   - Set up the PostgreSQL database using the `Backend/database.sql` script.
   - Set up storage by creating media buckets.

3. **Configure Row-Level Security (RLS)**
   - Ensure no RLS policies are blocking server requests. Remove any restrictive RLS policies that may prevent your server from functioning correctly.

4. **Copy the Backend Folder**
   - Copy the `Backend` folder into your local development setup.

5. **Configure Supabase Keys**
   - Retrieve your project keys from the Supabase dashboard.
   - Replace the placeholders with your actual Supabase keys in the `.env` file located in the `Backend/supabase/.env` directory.

6. **Create Backend Functions**
   - Use the following command to create a new backend function:
   ```bash
   supabase functions new <function_name>
   ```

7. **Deploy Backend Functions**
   - Deploy the function to your backend using the following command:
   ```bash
   supabase functions deploy <function_name>
   ```

## 🛑 Important Note

Account registration is restricted to users with an official Mahindra University email address (ending in `@mahindrauniversity.edu.in`).

---

Thank you for exploring **MU-Connect!** 💬  
Feel free to contribute or raise issues if you encounter any problems.
