
# Kasuwa - Northern Nigeria's Premier E-Commerce Marketplace 🛍️

**Kasuwa** is a robust multi-vendor e-commerce platform designed to bridge the gap between major trade hubs (like Kano) and consumer markets (like Jos). Built with a mobile-first approach, it features a cross-platform mobile app and a powerful backend administration system.

## 🚀 Project Overview

The problem: High-quality goods (Electronics, Textiles) are cheap in Kano but expensive in Jos due to fragmented logistics.
The Solution: **Kasuwa** digitizes this trade route. It connects buyers directly to vendors in major markets (Farm Center, Kwari Market) with an integrated logistics and payment layer.

**Current Status:** 🟢 Live / Beta Testing (Jos & Kano Operations)

## 🛠️ Tech Stack

### Mobile App (Frontend)
* **Framework:** Flutter (Dart)
* **Architecture:** MVVM / Clean Architecture
* **State Management:** Provider / Riverpod (Update this to what you use)
* **Payment Integration:** OPay SDK (Strictly Pre-paid model)

### Backend API
* **Framework:** Laravel (PHP)
* **Database:** MySQL
* **Authentication:** Laravel Sanctum
* **Admin Panel:** FilamentPHP / Nova (Or custom Blade templates)



## ✨ Key Features

### 🛒 Multi-Vendor System
* **Shop Profiles:** Sellers can create stores, manage inventory, and track earnings.
* **Dynamic Onboarding:** Admin can onboard vendors directly from markets (e.g., uploading products on behalf of non-tech-savvy traders).

### 🚚 Smart Logistics Algorithm
* **Location-Based Shipping:** Automatically calculates fees based on Vendor vs. User state (e.g., Kano -> Jos).
* **Risk Premium Logic:** Shipping fees dynamically adjust for high-value carts (>₦50k) to cover insurance/handling.
* **Last-Mile Tracking:** Integration for local bike delivery and inter-state waybill management.

### 💳 Secure Payments
* **Cashless Operation:** 100% Pre-paid model to eliminate "Pay on Delivery" risks.
* **Escrow System:** Funds are held safely until delivery is confirmed.
* **Refund Automation:** Wallet system for instant refunds on failed orders.


## 📸 Screenshots

| Shop Home | Product Details | user profile |
|:---:|:---:|:---:|
| ![Screenshot_20251221_173942](https://github.com/user-attachments/assets/d179bc1c-f433-4f8d-8f86-e087a283d8f0) | ![Screenshot_20251221_174027](https://github.com/user-attachments/assets/2db4cf95-1cd6-4760-b0e3-fdd102ca8eb8) | ![Screenshot_20251221_174250](https://github.com/user-attachments/assets/20739a1b-14e1-43e8-9f2f-0c9229de3b04) |


## ⚙️ Installation & Setup

### Backend (Laravel)


2. Install dependencies:
```bash
composer install

```


3. Setup environment:
```bash
cp .env.example .env
php artisan key:generate

```


4. Run migrations:
```bash
php artisan migrate --seed

```



### Mobile App (Flutter)

1. Navigate to app directory:
```bash
cd kasuwa-mobile

```


2. Get packages:
```bash
flutter pub get

```


3. Run app:
```bash
flutter run

```



## 🗺️ Roadmap

* [x] Vendor Onboarding Module
* [x] OPay Payment Integration
* [x] Inter-state Shipping Logic
* [ ] Real-time Driver Tracking
* [ ] AI-based Product Recommendations

## 👨‍💻 Author

**Isa Usman Musa**
*Full-Stack Software Developer & Founder*

* **Focus:** Building scalable tech solutions for African commerce.
* **Location:** Jos, Plateau State.


*© 2026 Kaswa Ng Ventures. All Rights Reserved.*

### 💡 **Pro-Tip for your GitHub:**
Since you are meeting investors soon:
1.  **Add 3 actual screenshots** to the "Screenshots" section. It makes the repo look alive.
2.  **Pin this repository** to the top of your GitHub profile so it's the first thing they see.
