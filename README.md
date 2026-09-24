# Bio-Medical Waste Logistics & Tracking System

Complete Full-Stack Application:
- **Backend**: Node.js, TypeScript, Express, PostgreSQL, Prisma ORM, and node-cron.
- **Frontend**: Flutter Mobile App with Camera QR Scanner, QR Code Generator, Image Picker, and Dio REST client.

---

## 📁 Project Structure

```
waste_management_system/
├── backend/                  # Node.js + TypeScript + PostgreSQL
│   ├── prisma/
│   │   └── schema.prisma     # Complete PostgreSQL schema & relations
│   ├── src/
│   │   ├── controllers/      # API Controllers for Screens 1 to 6
│   │   ├── cron/             # 6:00 PM Auto-disposal Background Scheduler
│   │   ├── middleware/       # Multer driver photo upload
│   │   ├── routes/           # Express API routes
│   │   ├── prisma.ts         # Prisma DB client
│   │   └── server.ts         # Server entry point
│   ├── .env                  # DB connection string
│   ├── package.json
│   └── tsconfig.json
│
└── frontend/                 # Flutter Mobile App
    ├── lib/
    │   ├── core/api_client.dart          # Configurable Dio API client
    │   ├── widgets/qr_scanner_dialog.dart# Camera QR Scanner
    │   ├── screens/
    │   │   ├── home_dashboard_screen.dart
    │   │   ├── screen1_vehicle_registration.dart  # Screen 1
    │   │   ├── screen2_route_mapping.dart         # Screen 2
    │   │   ├── screen3_driver_registration.dart   # Screen 3
    │   │   ├── screen4_shift_assignment.dart      # Screen 4
    │   │   ├── screen5_bag_collection.dart        # Screen 5
    │   │   └── screen6_plant_receival.dart        # Screen 6
    │   └── main.dart
    └── pubspec.yaml
```

---

## 🚀 How to Run the Entire Project

### Step 1: Start Backend & Database
1. Create PostgreSQL database:
   ```sql
   CREATE DATABASE waste_management_db;
   ```
2. Open terminal in `backend/`:
   ```bash
   cd backend
   npm install
   npm run prisma:push
   npm run dev
   ```
   *(Backend runs on `http://localhost:5000`)*
3. View Database visually in your browser:
   ```bash
   npm run prisma:studio
   ```

### Step 2: Run Flutter App
1. Open a new terminal in `frontend/`:
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```
2. Tap the **⚙️ Settings icon** in the mobile app header to configure the backend API URL for your device/emulator.
