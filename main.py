from database.database import Base, engine
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from schema import ChatRequest, ChatResponse, RegisterRequest
from agent import get_agent
from utils import config
from dotenv import load_dotenv, find_dotenv
from database.models import User
from database.database import session
from routes.admin import admin_router
from routes.auth import auth_router
from routes.chat import chat_router


app = FastAPI()

app.include_router(admin_router)
app.include_router(auth_router)
app.include_router(chat_router)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def health_check():
    return {"status": "Server running"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}



if __name__ == "__main__":
    load_dotenv(find_dotenv())
    Base.metadata.create_all(engine)
    uvicorn.run(app, port=8000)
    
