# HabitPilot

A habit tracking iOS app built with SwiftUI. Helps users build good habits and track their progress.

## What it does

- Track daily habits with streak counters
- Set goals and monitor progress
- Create and organize tasks
- Connect with friends and share progress
- Get notifications for habit reminders
- Works offline
- Dark mode support

## How it's built

The app uses MVVM architecture:

- **Models** - Data structures for habits, goals, etc.
- **ViewModels** - Business logic and state management
- **Views** - SwiftUI components organized by feature
- **Services** - API calls and external integrations

Code is organized into folders by feature:
- Authentication (login/signup)
- Habits (habit tracking)
- Goals (goal management)
- Tasks (task lists)
- Challenges (social challenges)
- Social (friends and sharing)
- Settings (app preferences)
- Components (reusable UI parts)
- Utilities (helper functions)

## Tech stack

- SwiftUI for the UI
- Combine for reactive programming
- Core Data for local storage
- UserNotifications for push notifications
- StoreKit for in-app purchases

## Requirements

- Xcode 15+
- iOS 17+
- Swift 5.9+

## Getting started

1. Clone this repo
2. Open HabitPilot.xcodeproj in Xcode
3. Run on simulator or device

## License

MIT