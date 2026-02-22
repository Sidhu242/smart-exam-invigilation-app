from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    name: str
    email: EmailStr
    role: str

class UserCreate(UserBase):
    password: str

class UserOut(UserBase):
    id: int

    class Config:
        orm_mode = True

class ExamBase(BaseModel):
    title: str
    start_time: datetime
    end_time: datetime

class ExamCreate(ExamBase):
    pass

class ExamOut(ExamBase):
    id: int

    class Config:
        orm_mode = True

class FlagBase(BaseModel):
    violation_type: str
    confidence: float
    screenshot: Optional[str]
    timestamp: Optional[datetime]
    resolved: Optional[bool] = False

class FlagCreate(FlagBase):
    student_id: int
    exam_id: int

class FlagOut(FlagBase):
    id: int
    student_id: int
    exam_id: int

    class Config:
        orm_mode = True
