from fastapi import FastAPI
from app.routers import users, exams, flags

app = FastAPI()

app.include_router(users.router)
app.include_router(exams.router)
app.include_router(flags.router)
