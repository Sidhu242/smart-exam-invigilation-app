from fastapi import Depends, HTTPException
from app import auth, models, database
from sqlalchemy.orm import Session

# Role-based dependency

def require_role(role: str):
    def dependency(current_user: models.User = Depends(auth.get_current_user)):
        if current_user.role != role:
            raise HTTPException(status_code=403, detail=f"Only {role}s allowed")
        return current_user
    return dependency

# Student can only access own flags

def student_flag_access(flag_student_id: int, current_user: models.User = Depends(auth.get_current_user)):
    if current_user.role != "student" or current_user.id != flag_student_id:
        raise HTTPException(status_code=403, detail="Students can only access their own flags")
    return current_user
