# Construction-Bot

## Overview
Construction AI Agent is an AI-powered platform that streamlines construction management through a smart chat interface. Users can:

- Ask AI-powered construction-related questions
- Rent construction machinery
- Hire skilled labor
- Upload projects and request quotations

No complicated menus—just chat with the AI, and it will guide you through everything!

## Tech Stack
- Backend: FastAPI, LangChain, LangGraph, PostgreSQL, OpenAI GPT-4o
- Frontend: Flutter (Mobile UI)
- Authentication: Google Auth
- AI Capabilities: OpenAI GPT-4o for intelligent responses
- Orchestration: LangChain + LangGraph for structured AI workflows
- Database: PostgreSQL for storing user data, projects, and transactions

## How It Works 
### AI-Powered Construction Q&A

Simply ask the AI any construction-related question in chat. Whether you need material recommendations, safety guidelines, or cost estimates, the AI has you covered.

1. Machine Rentals
- Tell the AI, "I need an excavator for 3 days."
- The AI will find available machines, show pricing, and complete the rental process.

2. Labor Hiring
- Say, "I need 5 electricians for a week."
- The AI filters available workers based on skills, experience, and availability.

3. Project Gallery & Uploads
- Ask, "Show me past projects like mine." The AI will display similar projects.
- Want to upload your project? Just send images and details in chat, and the AI will process it.

4. Project Requests & Quotations
- Type, "I have a new project. Can I get a cost estimate?"
- The AI will guide you through the details and generate a preliminary quotation.

5. Admin & Super Admin Features
Admins and Super Admins have additional privileges. They can manage users, resources, and system settings—all through chat commands.

## Installation Guide 
1. Clone the Repository
```
git clone https://github.com/pinilDissanayaka/Construction-Bot.git
cd Construction-Bot
```

2. Backend Setup (FastAPI + LangChain + PostgreSQL)
- Create a virtual environment and install dependencies
```
python -m venv env
source env/bin/activate  # Windows: env\Scripts\activate
pip install -r requirements.txt
```

- Set up PostgreSQL and update the .env file
```
DATABASE_URL=postgresql://username:password@localhost:5432/rise_construction_db
OPENAI_API_KEY=your-openai-key
```

- Start the FastAPI Server
```
python main.py
```

- API Docs Available at:
Swagger UI: http://127.0.0.1:8000/docs

3. Frontend Setup (Flutter)
```
cd Frontend
flutter pub get
flutter run
```

- Ensure Google Auth is configured in Firebase before running the app.

## License 
This project is licensed under the MIT License.


Now, Just Chat & Build! 

Everything you need is in the chat. Just start typing!
