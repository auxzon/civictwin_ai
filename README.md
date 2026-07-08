# CivicTwin AI

**The Digital Twin for City Decisions**

CivicTwin AI is an enterprise-grade platform that transforms civic data into live spatial intelligence. Designed for public officials and city planners, it enables seamless tracking of infrastructure projects, real-time analytics, and AI-driven mission planning on a highly interactive 3D map.

## 🚀 Key Features

- **Spatial Intelligence:** Immersive 3D map interface built with Google Maps and Flutter.
- **AI Mission Generation:** Harness the power of Gemini 2.5 Pro to generate dynamic, actionable missions based on civic context.
- **Real-time Dashboard:** Track KPIs, mission history, and ward analytics instantly.
- **Enterprise Security:** Firebase Authentication ensures only authorized officials can access constituent data.
- **Cross-Platform:** Beautiful, responsive experience accessible anywhere via the Web.

## 🏗️ System Architecture

CivicTwin AI uses a modern, serverless architecture optimized for speed and scalability:

- **Frontend:** Flutter Web (Dart) providing a polished, high-performance UI.
- **Backend:** Python FastAPI deployed on Google Cloud Run.
- **Database:** Firebase Firestore for real-time document storage.
- **Authentication:** Firebase Auth and Identity Toolkit.
- **AI Engine:** Google Gemini Developer API.

### AI & GIS Workflow
1. **User Interaction:** City official requests a new mission plan on the map.
2. **Context Aggregation:** Backend queries Firestore for localized ward data, budgets, and historical missions.
3. **AI Processing:** Gemini analyzes the spatial context and generates a structured, actionable mission.
4. **Real-time Delivery:** Firestore streams the new mission data directly to the Flutter UI via WebSockets.

## 🛠️ Tech Stack

- **Google Cloud Platform:** Cloud Run, Cloud Build
- **Firebase:** Firestore, Authentication, Hosting
- **AI:** Google Gemini (gemini-2.5-pro)
- **Frontend:** Flutter Web
- **Backend:** Python 3.12, FastAPI, Pydantic

## 📂 Project Structure

```text
civictwin_ai/
├── backend/            # Python FastAPI service
│   ├── api/            # Route handlers
│   ├── core/           # LLM and Firebase integration
│   └── scripts/        # Seeding and utility scripts
├── frontend/           # Flutter Web application
│   ├── lib/            # UI, state management (Riverpod), themes
│   └── web/            # Web entrypoint and assets
└── firebase/           # Firestore rules and indexes
```

## 💻 Installation & Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/civictwin_ai.git
   ```

2. **Frontend Setup:**
   ```bash
   cd frontend
   flutter pub get
   flutter run -d chrome
   ```

3. **Backend Setup:**
   ```bash
   cd backend
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   uvicorn main:app --reload
   ```

## 🔐 Demo Login

The application features a **Continue Demo** button for instant access during the hackathon evaluation.
Alternatively, use the following credentials to explore the platform:
- **Email:** test@civictwin.dev
- **Password:** TestPassword123!

## 📸 Screenshots

*(Hackathon organizers: Please view the live demo to experience the application in full fidelity.)*

| Dashboard View | Map Interface | AI Mission Generation |
| :---: | :---: | :---: |
| ![Dashboard](https://via.placeholder.com/400x250.png?text=Command+Center) | ![Map](https://via.placeholder.com/400x250.png?text=3D+Map) | ![AI](https://via.placeholder.com/400x250.png?text=Mission+Planning) |

## 🔮 Future Roadmap

- **Citizen Reporting Portal:** Allow citizens to submit local issues that automatically overlay onto the Digital Twin.
- **Predictive Infrastructure Analytics:** Use Vertex AI for predicting maintenance needs before they become critical.
- **Multi-City Scaling:** Expand support to thousands of constituencies with partitioned indexing.

## 📄 License

This project is licensed under the MIT License.
