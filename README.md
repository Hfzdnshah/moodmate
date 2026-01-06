# MoodMate 🌙🧠  
*A lightweight mood check-in & reflection app (Flutter)*

[![Flutter](https://img.shields.io/badge/Flutter-Framework-blue)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-Language-informational)](https://dart.dev/)
[![Status](https://img.shields.io/badge/Status-In%20Progress-yellow)](#)

---

## ✨ Overview
**MoodMate** helps users track their emotions through quick daily mood check-ins, short notes (optional), and a simple mood history view for reflection.  
Built with **Flutter**, designed to be clean, fast, and easy to use.

---

## 🎯 Objectives
- Enable fast mood check-in (under 1 minute)
- Store mood entries with optional notes
- Display mood history clearly (list + details)
- Provide basic self-care tips (MVP)

---

## ✅ MVP Features
- Mood check-in (mood + optional note)
- Mood history (sorted by date/time)
- Entry details view
- Tips page (static content)
- Clean navigation + empty states

### 🔜 Future Improvements
- Reminders / notifications
- Weekly summary / simple analytics
- Tags (work, family, study, etc.)
- Cloud sync (optional)

---

## 🧩 Tech Stack
- **Flutter / Dart**
- Storage: *(choose one based on your implementation)*
  - Local storage (simple MVP)  
  - Firebase/Firestore (if enabled)

---

## 📂 Project Structure (Main)
```text
moodmate/
├─ lib/                 # Flutter source code
├─ test/                # Unit/widget tests (if any)
├─ android/ ios/ web/   # Platform folders
├─ docs/                # Evidence & documentation (proposal, UML, etc.)
└─ README.md
