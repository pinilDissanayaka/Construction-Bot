from typing import Optional
from pydantic import BaseModel

class ChatRequest(BaseModel):
    message: str 
    role: str = "user"

class ChatResponse(BaseModel):
    response: str


class RegisterRequest(BaseModel):
    username: str
    phone_number:str
    email:str
    password:str
    role:Optional[str]
    
    
class LoginRequest(BaseModel):
    email:str
    password:str
