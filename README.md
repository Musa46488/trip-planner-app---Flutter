# Adventure Scape (venture_scape)

Flutter frontend for an AI-powered travel planning app focused on Pakistan. It is the mobile client for the [AdventureScape backend](https://github.com/Musa46488/Trip-Planner-App---FastAPI) — users browse places and hotels, explore them in Google Street View, save favorites, and chat with an AI assistant that plans trips and estimates fuel costs.

## Features

- **Authentication** — sign-up / login via Firebase Authentication; auth state decides whether the app opens on the welcome screen or the dashboard.
- **Dashboard** — bottom-nav home with search, plus *Places* and *Hotels* sections loaded from Firestore.
- **AI chatbot** — chat UI wired to the AdventureScape backend (`/text_processing`, `/plan_trip`, `/get_directions`): natural-language trip planning, itinerary plans, and route/fuel-cost answers.
- **Place & hotel details** — detail screens with images (cached network images served from Firebase Storage).
- **360° panoramas** — Google Street View embeds (Maps Embed API) rendered in a WebView for supported landmarks.
- **Favorites** — per-user favorites persisted in Firestore under `favorites/{uid}/items`.
- **Place search** — Google Places SDK autocomplete while typing a destination.

## Project Structure

```
venture_scape/
├── lib/
│   ├── main.dart                  # App entry, Firebase init, auth-state routing
│   ├── auth_service.dart          # Firebase Authentication helpers
│   ├── storage_service.dart       # Firebase Storage (place/hotel images)
│   ├── login_page.dart            # Login screen
│   ├── signup_page.dart           # Sign-up screen
│   ├── dashboard.dart             # Home dashboard (places, hotels, search, nav)
│   ├── chatbot.dart               # AI chat screen (talks to the FastAPI backend)
│   ├── find_places.dart           # Google Places SDK search
│   ├── new_places.dart / see_all.dart  # Place listings
│   ├── place_info_screen.dart     # Place details
│   ├── hotel_info_screen.dart     # Hotel details
│   ├── pano_view.dart             # Street View panoramas (WebView)
│   ├── favourite.dart             # Favorites screen
│   ├── profile_page.dart          # User profile
│   └── models/
│       ├── tour_place.dart        # Tour place model
│       └── hotel.dart             # Hotel model
├── assets/                        # App background, logo
├── firebase.json                  # FlutterFire platform configuration
└── .env                           # GOOGLE_API_KEY (not committed)
```

## Tech Stack

- **Flutter / Dart** (SDK `^3.7.2`)
- **Firebase** — Authentication, Cloud Firestore (`places`, `hotels`, `favorites`), Storage
- **flutter_chat_ui / flutter_chat_types** — chatbot UI
- **flutter_google_places_sdk** — place autocomplete
- **webview_flutter** — Street View panoramas
- **flutter_dotenv** — environment variables
- **cached_network_image, url_launcher, fluttertoast, scroll_to_index, flutter_launcher_icons**

## Getting Started

### Prerequisites

- Flutter SDK (Dart `^3.7.2`) — `flutter doctor` to verify
- A Firebase project with Authentication (email/password), Firestore, and Storage enabled — the app currently targets the `booking-app-f38d1` project (`firebase_options.dart` / `firebase.json` are already generated)
- A Google Maps Platform API key (Maps Embed / Street View + Places)
- The AdventureScape FastAPI backend running and reachable (see the chatbot section below)

### Installation

```bash
git clone https://github.com/Musa46488/Trip-Planner-App---Flutter.git
cd venture_scape

flutter pub get
```

### Environment Variables

Create a `.env` file in the project root:

```
GOOGLE_API_KEY   # Google Maps Platform key (Street View embeds, Places)
```

The `.env` file is loaded at startup via `flutter_dotenv` and is listed as a Flutter asset in `pubspec.yaml`.

### Running

```bash
flutter run
```

First-time Firebase setup for a new project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## Backend Connection (Chatbot)

The AI chat screen calls the AdventureScape FastAPI backend. The base URL is currently a hardcoded ngrok tunnel in `lib/chatbot.dart`:

```dart
final String link = "https://<ngrok-id>.ngrok-free.app";
```

Start the backend, expose it (e.g. `ngrok http 8000`), and update that URL to your own tunnel before using the chat features.

## Firestore Data Layout

| Collection | Contents |
|---|---|
| `places` | Tourist places (name, location, rating, image URL) |
| `hotels` | Hotels (same shape as places) |
| `favorites/{uid}/items` | Per-user saved places |

Images referenced by these documents are uploaded to Firebase Storage.
