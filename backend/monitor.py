active_sessions = {}
warnings = []

def start_session(student_id, exam_id):
    active_sessions[student_id] = {"exam_id": exam_id, "warnings": []}

def add_warning(student_id, message):
    if student_id in active_sessions:
        active_sessions[student_id]["warnings"].append(message)
        warnings.append({"student": student_id, "warning": message})

def get_all_warnings():
    return warnings
