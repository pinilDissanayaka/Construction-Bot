from fastapi import APIRouter
from database.database import Base, engine
from fastapi import HTTPException
from schema import ChatRequest, ChatResponse
from agent import get_agent
from utils import config
from agent import get_chat_response

chat_router = APIRouter(
    prefix="/chat", 
    tags=["Chat-bot"]
)


@chat_router.post("/", response_model=ChatResponse)
async def chat(request: ChatRequest):
    try:
        print(request.role)
        
        if request.role == "super_admin":
            final_response=await get_chat_response(request)
            
            return ChatResponse(
                response=final_response
            )
        elif request.role == "admin":
            final_response=await get_chat_response(request)
            return ChatResponse(
                response=final_response
            )
        elif request.role == "user":
            final_response=await get_chat_response(request)

            return ChatResponse(
                response=final_response
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))




