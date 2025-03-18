from fastapi import FastAPI, APIRouter
from database.database import Base, engine
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from schema import RegisterRequest, LoginRequest
from database.models import User
from database.database import session
from utils import hash_pass, verify_password


auth_router=APIRouter(
    prefix="/auth", 
    tags=["Auth"]
)


@auth_router.post("/register")
async def register(request:RegisterRequest):
    try:
        existing_user=session.query(User).filter_by(username=request.username).first()
        if existing_user:
            return {"message": "User already exists"}
        else:
            hashed_password = hash_pass(request.password)
            new_user=User(username=request.username, email=request.email, password=hashed_password, phone_number=request.phone_number, role=request.role)
            session.add(new_user)
            session.commit()
            
            return {"message": "User registered successfully",
                    "role": new_user.role
                    }
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=str(e))
    
    
@auth_router.post("/login")
async def login(request:LoginRequest):
    try:
        existing_user=session.query(User).filter_by(email=request.email).first()
        if existing_user:
            if verify_password(request.password, existing_user.password):
                return {"message": "Login successful",
                        "role": existing_user.role}
            else:
                return {"message": "Invalid credentials"}
        else:    
            return {"message": "User not found"}
    except Exception as e:
        session.rollback()
        raise HTTPException(status_code=500, detail=str(e))