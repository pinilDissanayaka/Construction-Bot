from encodings import unicode_escape
from enum import auto
from gc import disable
from os import access
from sqlalchemy import create_engine, Column, Integer, String, ForeignKey, DECIMAL, Enum, Text, TIMESTAMP, Float, DateTime, Boolean
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from database.database import Base
from datetime import datetime


# Define the User model
class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(50), nullable=False)
    phone_number = Column(String(100), nullable=False)
    email=Column(String(100), nullable=False, unique=True)
    role = Column(String(50), nullable=False, default='user')
    password = Column(String(255), nullable=False, unique=True)
    disabled = Column(Boolean, default=False)
    
class Token(Base):
    __tablename__ = 'tokens'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    access_token = Column(String(255), nullable=False)
    refresh_token = Column(String(255), nullable=False)
    


class Equipment_Request(Base):
    __tablename__ = 'equipment_requests'
    
    id = Column(Integer, primary_key=True)
    location = Column(String(255), nullable=True)
    number_of_dates=Column(Integer, default=1)
    start_date = Column(DateTime, nullable=True)
    quantity = Column(Integer, nullable=False)
    status = Column(String(50), default="pending")  # e.g., pending, approved, cancelled
    
    equipment_id = Column(Integer, ForeignKey('equipment.id'))  
    equipment = relationship('Equipment', back_populates='requests')

class Equipment(Base):
    __tablename__ = 'equipment'
    
    id = Column(Integer, primary_key=True)
    name = Column(String(200), nullable=False)
    description = Column(String(500), nullable=True)
    price_per_day = Column(Float, nullable=False)
    available = Column(Boolean, default=True)  # Indicates if the equipment is available for hire
    
    requests = relationship('Equipment_Request', back_populates='equipment', cascade="all, delete-orphan")
    
    
class Labour(Base):
    __tablename__ = 'labours'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(200), nullable=False)
    skillset = Column(String(300), nullable=True)  # Example: "Mason, Electrician, Carpenter"
    hourly_rate = Column(Float, nullable=False)
    available = Column(Boolean, default=True)  # Indicates if the worker is available for hire
    

    def __repr__(self):
        return f'<Labour {self.name}>'
    
    
class Project_Request(Base):
    __tablename__ = 'project_requests'
    
    id = Column(Integer, primary_key=True)
    location = Column(String(255), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    status = Column(String(50), default="pending")  # e.g. pending, approved, cancelled
    start_date = Column(DateTime, nullable=True)

    
    def __str__(self):
        return self.title
    
    
class Hire(Base):
    __tablename__ = 'hires'
    
    id = Column(Integer, primary_key=True)
    number_of_dates=Column(Integer, default=1)
    hire_date = Column(DateTime, default=datetime.utcnow)
    status = Column(String(50), default="pending")  # e.g., pending, completed, cancelled
    

    def __repr__(self):
        return f'<Hire {self.id} by User {self.user_id}>'
    
    
class ProjectHistory(Base):
    __tablename__ = 'project_history'
    
    id = Column(Integer, primary_key=True)
    actual_cost = Column(Float, nullable=False)  # Actual amount spent on the project
    initial_budget = Column(Float, nullable=False)  # The original budget estimated for the project
    start_date = Column(DateTime, nullable=False)  # Project start date
    completion_date = Column(DateTime, nullable=False)  # Project completion date
    location = Column(String(255), nullable=True)  # Project location
    workers_used = Column(Integer, nullable=True)  # Number of workers involved
    description = Column(Text, nullable=True)  # Short summary of the project
    
    def __repr__(self):
        return f'<ProjectHistory {self.id} for Project {self.description}>'
    
    
    

    
    


    
    
    

    

