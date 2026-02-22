from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, Query
from sqlalchemy.orm import Session
from app import models, schemas, database, auth, dependencies
from typing import List, Dict

router = APIRouter(prefix="/api/flags", tags=["flags"])

# Connection manager for WebSocket
class ConnectionManager:
	def __init__(self):
		self.active_connections: Dict[int, List[WebSocket]] = {}

	async def connect(self, exam_id: int, websocket: WebSocket):
		await websocket.accept()
		if exam_id not in self.active_connections:
			self.active_connections[exam_id] = []
		self.active_connections[exam_id].append(websocket)

	def disconnect(self, exam_id: int, websocket: WebSocket):
		if exam_id in self.active_connections:
			self.active_connections[exam_id].remove(websocket)
			if not self.active_connections[exam_id]:
				del self.active_connections[exam_id]

	async def broadcast(self, exam_id: int, message: dict):
		if exam_id in self.active_connections:
			for connection in self.active_connections[exam_id]:
				await connection.send_json(message)

manager = ConnectionManager()

@router.post("", response_model=schemas.FlagOut)
async def create_flag(
	flag: schemas.FlagCreate,
	db: Session = Depends(database.SessionLocal),
	current_user: models.User = Depends(dependencies.require_role("student"))
):
	# Student can only create their own flag
	if flag.student_id != current_user.id:
		raise HTTPException(status_code=403, detail="Students can only create their own flags")
	new_flag = models.Flag(
		student_id=flag.student_id,
		exam_id=flag.exam_id,
		violation_type=flag.violation_type,
		confidence=flag.confidence,
		screenshot=flag.screenshot,
		resolved=flag.resolved
	)
	db.add(new_flag)
	db.commit()
	db.refresh(new_flag)
	# Broadcast to teachers
	await manager.broadcast(flag.exam_id, schemas.FlagOut.from_orm(new_flag).dict())
	return new_flag

@router.get("", response_model=List[schemas.FlagOut])
def get_flags(
	exam_id: int = Query(...),
	db: Session = Depends(database.SessionLocal),
	current_user: models.User = Depends(auth.get_current_user)
):
	query = db.query(models.Flag).filter(models.Flag.exam_id == exam_id)
	if current_user.role == "student":
		query = query.filter(models.Flag.student_id == current_user.id)
	elif current_user.role == "teacher":
		pass  # Teachers can view all flags for their exams
	else:
		raise HTTPException(status_code=403, detail="Unauthorized role")
	return query.all()

@router.websocket("/ws/flags/{exam_id}")
async def websocket_endpoint(websocket: WebSocket, exam_id: int):
	await manager.connect(exam_id, websocket)
	try:
		while True:
			await websocket.receive_text()  # Keep connection alive
	except WebSocketDisconnect:
		manager.disconnect(exam_id, websocket)
