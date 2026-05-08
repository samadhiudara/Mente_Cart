# MenteCart — Service Booking with Cart

A full-stack service booking application.
Users can browse services, add them to a cart, select time slots, and complete bookings.

---

## Tech Stack

| Layer        | Technology                        |
|--------------|-----------------------------------|
| Mobile       | Flutter (Dart 3.x)                |
| State Mgmt   | BLoC pattern (flutter_bloc)       |
| HTTP Client  | Dio with interceptors             |
| Backend      | Node.js + Express + TypeScript    |
| Database     | MongoDB (Mongoose ODM)            |
| Auth         | JWT (bcrypt password hashing)     |
| Logging      | Pino (structured JSON logs)       |
| Containers   | Docker + docker-compose           |

---

## Project Structure

```
mentecart/
├── backend/                        # Node.js + Express API
│   ├── src/
│   │   ├── controllers/            # HTTP layer only
│   │   ├── services/               # Business logic
│   │   ├── models/                 # Mongoose schemas
│   │   ├── middleware/             # JWT auth, error handler
│   │   ├── routes/                 # Express routers
│   │   ├── validators/             # Zod schemas
│   │   └── utils/                  # logger, AppError, seed
│   ├── .env.example
│   ├── Dockerfile
│   └── package.json
│
├── mobile/                         # Flutter app (or your project folder)
│   ├── lib/
│   │   ├── blocs/                  # Auth, Services, Cart, Bookings BLoCs
│   │   ├── models/                 # Dart data classes
│   │   ├── repositories/           # API calls
│   │   ├── screens/                # UI screens
│   │   ├── services/               # ApiClient, TokenStorage
│   │   └── utils/                  # AppTheme, AppRouter, ApiFailure
│   └── pubspec.yaml
│
├── docker-compose.yml
└── README.md
```

---

## Prerequisites

Make sure these are installed before starting:

| Tool          | Version       | Download Link                                      |
|---------------|---------------|----------------------------------------------------|
| Node.js       | 20+           | https://nodejs.org                                 |
| MongoDB       | 7.0+          | https://www.mongodb.com/try/download/community     |
| Flutter       | 3.x stable    | https://flutter.dev/docs/get-started/install       |
| Android Studio| Latest        | https://developer.android.com/studio               |
| Git           | Any           | https://git-scm.com                                |

---

## STEP BY STEP — How to Run This Project

---

### STEP 1 — Start MongoDB

MongoDB must be running before starting the backend.

**Option A — If installed as a Windows Service (recommended):**

Open PowerShell as Administrator and run:
```bash
net start MongoDB
```

You should see:
```
The MongoDB service was started successfully.
```

**Option B — Run manually:**
```bash
mongod
```

Keep this terminal open.

---

### STEP 2 — Setup and Start the Backend

Open a **new PowerShell window** and run these commands one by one:

```bash
# 1. Navigate to backend folder
cd C:\Users\YourName\mentecart\mentecart\backend

# 2. Install dependencies
npm install

# 3. Install pino-pretty (for readable logs)
npm install pino-pretty

# 4. Create environment file
copy .env.example .env

# 5. Seed sample data (10 services with time slots)
npm run seed

# 6. Start the backend server
npm run dev
```

**Expected output after npm run dev:**
```
INFO: Connected to MongoDB
INFO: MenteCart API running port=3000
```

> Keep this terminal open. The server must stay running.

---

### STEP 3 — Verify Backend is Working

Open your browser and go to:
```
http://localhost:3000/health
```

You should see:
```json
{"status":"ok","timestamp":"..."}
```

---

### STEP 4 — Setup Flutter App

Open a **third PowerShell window** and run:

```bash
# 1. Navigate to your Flutter project folder
cd E:\mentecart

# 2. Generate Android/iOS folders (only needed once)
flutter create --org com.mentecart --project-name mentecart .

# 3. Install Flutter dependencies
flutter pub get
```

---

### STEP 5 — Add Internet Permission to Android

Open this file in Android Studio:
```
android/app/src/main/AndroidManifest.xml
```

Add this line **above** the `<application>` tag:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

---

### STEP 6 — Start the Android Emulator

In Android Studio:
1. Go to **Tools → Device Manager**
2. Click the **▶ Play** button next to your emulator
3. Wait for it to fully boot

---

### STEP 7 — Run the Flutter App

In your Flutter terminal (E:\mentecart) run:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

> `10.0.2.2` is the Android emulator's IP for your computer's localhost.
> For iOS simulator use `localhost` instead of `10.0.2.2`.

---

### STEP 8 — Reseed Data (if slots show "No available slots")

If time slots are expired, reseed the database:

```bash
# In the backend terminal (Ctrl+C to stop server first, or open new terminal)
cd C:\Users\YourName\Downloads\mentecart\mentecart\backend
npm run seed
```

Then press **R** in Flutter terminal to hot restart.

---

## All Commands Summary

### Backend Commands
```bash
# Go to backend folder
cd C:\Users\YourName\mentecart\mentecart\backend

# Install all packages
npm install

# Install pino-pretty logger
npm install pino-pretty

# Create .env from example
copy .env.example .env

# Seed 10 sample services into MongoDB
npm run seed

# Start development server (port 3000)
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

### Flutter Commands
```bash
# Go to Flutter project
cd E:\mentecart

# Get all packages
flutter pub get

# Run on Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Run on iOS simulator
flutter run --dart-define=API_BASE_URL=http://localhost:3000

# Hot reload (while app is running)
# Press: r

# Hot restart (while app is running)
# Press: R

# Build release APK
flutter build apk --dart-define=API_BASE_URL=http://YOUR_SERVER_IP:3000

# Check Flutter setup
flutter doctor
```

### MongoDB Commands
```bash
# Start MongoDB service (run as Administrator)
net start MongoDB

# Stop MongoDB service
net stop MongoDB

# Check if MongoDB is running
Get-Service MongoDB
```

### Docker Commands (Alternative to manual setup)
```bash
# From project root (where docker-compose.yml is)
docker-compose up --build

# Run in background
docker-compose up -d --build

# Stop containers
docker-compose down

# Seed data inside Docker
docker exec -it mentecart-backend npm run seed
```

---

## Environment Variables

Copy `backend/.env.example` to `backend/.env` and fill in values:

```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/mentecart
JWT_SECRET=your_super_secret_key_change_this_in_production
JWT_EXPIRES_IN=24h
CART_EXPIRY_MINUTES=15
MAX_BOOKINGS_PER_DAY=3
NODE_ENV=development
```

| Variable               | Description                      | Default                               |
|------------------------|----------------------------------|---------------------------------------|
| PORT                   | API server port                  | 3000                                  |
| MONGODB_URI            | MongoDB connection string        | mongodb://localhost:27017/mentecart   |
| JWT_SECRET             | JWT signing secret (change this!)| —                                     |
| JWT_EXPIRES_IN         | Token expiry duration            | 24h                                   |
| CART_EXPIRY_MINUTES    | Minutes cart items are held      | 15                                    |
| MAX_BOOKINGS_PER_DAY   | Max bookings per user per day    | 3                                     |

> **IMPORTANT:** Never commit `.env` to Git. Share secrets using:
> https://one-time-secret.de/en

---

## REST API Endpoints

### Auth
| Method | Endpoint     | Auth | Description           |
|--------|--------------|------|-----------------------|
| POST   | /auth/signup | ✗    | Register + get JWT    |
| POST   | /auth/login  | ✗    | Login + get JWT       |
| GET    | /auth/me     | ✓    | Get current user      |

### Services
| Method | Endpoint            | Auth | Description                      |
|--------|---------------------|------|----------------------------------|
| GET    | /services           | ✗    | List services (paginated)        |
| GET    | /services/categories| ✗    | Get all categories               |
| GET    | /services/:id       | ✗    | Service detail with slots        |

Query params: `?page=1&limit=20&category=Cleaning&search=home`

### Cart
| Method | Endpoint              | Auth | Description       |
|--------|-----------------------|------|-------------------|
| GET    | /cart                 | ✓    | Get current cart  |
| POST   | /cart/items           | ✓    | Add item to cart  |
| PATCH  | /cart/items/:itemId   | ✓    | Update cart item  |
| DELETE | /cart/items/:itemId   | ✓    | Remove cart item  |

### Bookings
| Method | Endpoint              | Auth | Description            |
|--------|-----------------------|------|------------------------|
| POST   | /bookings/checkout    | ✓    | Convert cart to booking|
| GET    | /bookings             | ✓    | List all bookings      |
| GET    | /bookings/:id         | ✓    | Get booking detail     |
| POST   | /bookings/:id/cancel  | ✓    | Cancel a booking       |

---

## App Screens

| Screen           | Description                                     |
|------------------|-------------------------------------------------|
| Splash Screen    | Auto-detects login state and redirects          |
| Login Screen     | Email + password login                          |
| Signup Screen    | Create new account                              |
| Services Screen  | Browse services grid with category filter       |
| Service Detail   | View details, select date/time slot, add to cart|
| Cart Screen      | View cart items, update quantity, remove items  |
| Checkout Screen  | Select payment method and place order           |
| Bookings Screen  | View all past and upcoming bookings             |
| Booking Detail   | View booking info, status, and cancel option    |
| Profile Screen   | User info and logout                            |

---

## Common Errors and Fixes

| Error | Fix |
|---|---|
| `connect ECONNREFUSED 127.0.0.1:27017` | MongoDB not running. Run `net start MongoDB` as admin |
| `unable to determine transport target for pino-pretty` | Run `npm install pino-pretty` in backend folder |
| `The request connection took longer than...` | Backend not running. Run `npm run dev` in backend folder |
| `No available slots` on service detail | Slots expired. Run `npm run seed` to refresh data |
| `AndroidManifest.xml could not be found` | Run `flutter create .` inside the mobile/Flutter folder |
| App stuck on splash screen | Check backend is running and reachable at port 3000 |
| `npm error Missing script: "dev"` | Wrong folder. Navigate to the `backend/` subfolder |

---

## What's Done

- [x] Email + password auth (JWT, bcrypt 12 rounds)
- [x] Service catalogue with pagination, category filter, search
- [x] Server-side cart with 15-minute slot expiry
- [x] Duplicate slot prevention in cart
- [x] Atomic capacity decrement with rollback (overbooking prevention)
- [x] Per-user per-day booking limit (configurable)
- [x] Full booking status lifecycle with audit log
- [x] Cancel with cutoff enforcement and capacity release
- [x] Cash/pay-on-arrival confirmed immediately
- [x] Flutter BLoC state management throughout
- [x] Dio API client with auth interceptor
- [x] Typed API failure mapping
- [x] Docker + docker-compose setup
- [x] Pino structured logging
- [x] Seed script with 10 sample services

## What's Stubbed / Known Limitations

- **PayHere integration** — Payment method `payhere` is accepted but webhook handler not implemented
- **Refresh tokens** — Not implemented. Re-login required after token expiry
- **Push notifications** — Not implemented
- **Image upload** — Service images use external URLs
- **Real-time slot updates** — App requires manual refresh to see capacity changes

---

## All 3 Things Must Run Simultaneously

| Terminal | Command                  | Purpose         |
|----------|--------------------------|-----------------|
| 1        | `net start MongoDB`      | Database        |
| 2        | `npm run dev`            | Backend API     |
| 3        | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` | Mobile App |