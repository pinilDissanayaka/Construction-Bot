from fastapi import APIRouter
from database.database import session, Base, engine
from database.models import Project_Request


admin_router = APIRouter(
    prefix="/admin", 
    tags=["Admin"]
)


@admin_router.get("/projects")
async def get_projects():
    projects = session.query(Project_Request).all()
    return {"projects": projects}


@admin_router.put("/approve/{project_id}")
def approve_project(project_id: int):
    project = session.query(Project_Request).filter_by(id=project_id).first()
    project.status = "approved"
    session.commit()
    
    return {"message": "Project approved successfully"}


@admin_router.put("/cancel/{project_id}")
def approve_project(project_id: int):
    project = session.query(Project_Request).filter_by(id=project_id).first()
    if not project:
        return {"message": "Project not found"}
    else:
        project.status = "approved"
        session.commit()
        
        return {"message": "Project cancelled successfully"}

