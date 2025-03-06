from logging import root
import re
from langchain_community.utilities import SQLDatabase
from regex import T
from typing_extensions import TypedDict
from langchain import hub
from typing_extensions import Annotated
import os
from dotenv import load_dotenv
from langchain_community.tools.sql_database.tool import QuerySQLDatabaseTool
from utils import llm
from langchain_core.tools import tool
import os
from dotenv import load_dotenv, find_dotenv
from database.database import Base, engine, session
from database.models import Equipment, Labour, Project_Request, Equipment_Request


load_dotenv(find_dotenv())


@tool
def get_details(question: str) -> str:
    """
    Retrieves equipment and labour details and project history based on a user's question by constructing and executing an SQL query.

    Args:
        question (str): The user's question about equipment ,labour details or project history.

    Returns:
        str: The response generated from the queried information.
    """
    # Establish a connection to the database
    db = SQLDatabase.from_uri(os.getenv("DATABASE_URL"))

    class QueryOutput(TypedDict):
        """Generated SQL query."""
        query: Annotated[str, ..., "Syntactically valid SQL query."]

    # Pull the query prompt template from the hub
    query_prompt_template = hub.pull("langchain-ai/sql-query-system-prompt")

    # Ensure the prompt template contains exactly one message
    assert len(query_prompt_template.messages) == 1

    # Invoke the prompt template with the necessary parameters
    prompt = query_prompt_template.invoke(
        {
            "dialect": db.dialect,
            "top_k": 10,
            "table_info": db.get_table_info(),
            "input": question,
        }
    )

    # Use the language model to generate a structured SQL query
    structured_llm = llm.with_structured_output(QueryOutput)
    result = structured_llm.invoke(prompt)

    # Execute the generated SQL query
    execute_query_tool = QuerySQLDatabaseTool(db=db)
    result = execute_query_tool.invoke(result)

    # Formulate a response using the retrieved SQL result
    answer_prompt = (
        "Given the following user question, corresponding SQL query, "
        "and SQL result, answer the user question.\n\n"
        f'Question: {question}\n'
        f'SQL Result: {result}\n'
        "When making answer, dont include sql query."
    )
    response = llm.invoke(answer_prompt)

    return response.content



@tool
def place_request_for_project(title:str, description:str, start_date, location=None)-> str:
    """
        Saves a project request in the database with the given title, description, and location.

        Args:
            title (str): The title of the project request.
            description (str): A detailed description of the project request.
            start_date (Date Time) : A start date for the project.
            location (str): The location where the project is required.

        Returns:
            str: A message confirming whether the project request was successfully saved in the database.
    """

    
    try:
        new_booking=Project_Request(title=title, description=description, location=location, start_date=start_date)
        
        session.add(new_booking)
        session.commit()
        
        return "Booking placed successfully"
    except Exception as e:
        return "Booking placed unsuccessfully"
    
    
@tool
def place_request_for_equipment(equipment_name: str, number_of_dates: int, quantity: int, location: str, start_date)-> str:
    """
        Makes a request to hire the given equipment for a certain number of dates in a certain location.

        Args:
            equipment_name (str): The name of the equipment to request.
            number_of_dates (int): The number of dates the equipment is needed for.
            quantity (int): The quantity of the equipment needed.
            location (str): The location where the equipment is needed.
            start_date (datetime): The date when the equipment is needed.

        Returns:
            str: A message confirming whether the equipment request was successfully saved in the database.
    """
    equipment_name=equipment_name.lower()
    
    existing_equipment = session.query(Equipment).filter_by(name=equipment_name).first()

    if existing_equipment:
        if existing_equipment.available:
            new_equipment_request = Equipment_Request(equipment_id=existing_equipment.id, location=location, start_date=start_date)
            
            session.add(new_equipment_request)
            session.commit()
            
            return f"Equipment {equipment_name} request placed successfully. confirmation will be sent to your email" 
        else:
            return f"Equipment {equipment_name} is already unavailable."
    else:
        return f"Equipment {equipment_name} not found."
    
@tool
def add_new_equipment(equipment_name: str, description: str, price_per_day: float)-> str:
    """
    Adds a new equipment to the database with the given name, description, and price per day.

    Args:
        equipment_name (str): The name of the equipment to add.
        description (str): A detailed description of the equipment.
        price_per_day (float): The rental price of the equipment per day.

    Returns:
        str: A message confirming whether the equipment was successfully added to the database.
    """
    try:
        new_equipment = Equipment(name=equipment_name, description=description, price_per_day=price_per_day)
        if not new_equipment:
            return f"Equipment {equipment_name} already exists"
        else:
            session.add(new_equipment)
            session.commit()
            return f"Equipment {equipment_name} added successfully"
    except Exception as e:
        return f"Error adding equipment: {str(e)}"
    
    
@tool
def add_new_labour(name: str, skill_set: str, hourly_rate: float)-> str:
    """
    Adds a new labour to the database with the given name, skill set, and hourly rate.

    Args:
        name (str): The name of the labour to add.
        skill_set (str): A detailed description of the skills of the labour.
        hourly_rate (float): The hourly rate of the labour.

    Returns:
        str: A message confirming whether the labour was successfully added to the database.
    """
    try:
        new_labour = Labour(name=name, skillset=skill_set, hourly_rate=hourly_rate)
        if not new_labour:
            return f"Labour {name} already exists"
        else:
            session.add(new_labour)
            session.commit()
            return f"Labour {new_labour} added successfully"
    except Exception as e:
        return f"Error adding Labour: {str(e)}"
    
@tool 
def approve_or_reject_project(project_id: int, status:str)-> str:

    """
    Approves or rejects a project request given its id and status.

    Args:
        project_id (int): The id of the project request to approve or reject.
        status (str): The status to set the project request to. Should be either "approved" or "rejected".

    Returns:
        str: A message confirming whether the project request was successfully approved or rejected.
    """
    
    project = session.query(Project_Request).filter_by(id=project_id).first()
    if not project:
        return {"message": "Project not found"}
    else:
        project.status = status
        session.commit()
    
        return {"message": "Project approved successfully"}
    
@tool
def remove_project(project_id: int)-> str:
    """
    Removes a project request from the database given its id.

    Args:
        project_id (int): The id of the project request to remove.

    Returns:
        str: A message confirming whether the project request was successfully removed from the database.
    """
    project = session.query(Project_Request).filter_by(id=project_id).first()
    if not project:
        return {"message": "Project not found"}
    else:
        session.delete(project)
        session.commit()
    
        return {"message": "Project removed successfully"}

@tool
def remove_equipment(equipment_id: int)-> str:
    """
    Removes an equipment from the database given its id.

    Args:
        equipment_id (int): The id of the equipment to remove.

    Returns:
        str: A message confirming whether the equipment was successfully removed from the database.
    """
    equipment = session.query(Equipment).filter_by(id=equipment_id).first()
    if not equipment:
        return {"message": "Equipment not found"}
    else:
        session.delete(equipment)
        session.commit()
    
        return {"message": "Equipment removed successfully"}
    
    
@tool
def remove_labour(labour_id: int)-> str:
    """
    Removes a labour from the database given its id.

    Args:
        labour_id (int): The id of the labour to remove.

    Returns:
        str: A message confirming whether the labour was successfully removed from the database.
    """
    labour = session.query(Labour).filter_by(id=labour_id).first()
    if not labour:
        return {"message": "Labour not found"}
    else:
        session.delete(labour)
        session.commit()
    
        return {"message": "Labour removed successfully"}
    


    

    

    



