# Smart Farm Application 🌾🛸

A futuristic, AI-powered agricultural dashboard built for the "Building Satellite-Powered Smart Farming Solutions for Rural India" Hackathon.

## Overview
This Flutter application provides an immersive, 3D-enhanced UI capable of transforming raw satellite data into easily understandable agricultural insights for farmers. It relies on a scalable MVVM architecture and secure integration with Sat2Farm APIs.

## Architecture & Code Structure
The application strictly leverages **MVVM (Model-View-ViewModel)** using Riverpod for state management.
- `lib/models/`: Data classes for Farm, Satellite metrics, NDVI scores, Weather.
- `lib/services/`: Stubbed API integration layers using `dio` and local caching using `hive`.
- `lib/viewmodels/`: Riverpod state notifiers representing app states.
- `lib/views/screens/`: Splitted into Dashboard, AI Insights, Maps, etc.
- `lib/views/widgets/`: Reusable futuristic widgets (`glass_card.dart`).

## Building the App
1. Navigate to the project folder (`smart_farm`).
2. Run `flutter pub get`.
3. (Optional) Configure Google Maps API Key in `android/app/src/main/AndroidManifest.xml` if testing Maps functionality on physical device.
4. Run using `flutter run` on an emulator or device.

## Design Identity
We designed the app with a dark, minimalist tech aesthetic adapted for agriculture:
- **Glowing Neon Green** highlights representing both high-tech precision and natural health.
- **Floating Glassmorphism Cards** with blurred backdrops for a 3D layered look.
- **Deep Charcoal** backgrounds to improve contrast and battery life in the field.
