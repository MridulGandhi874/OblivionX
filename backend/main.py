# main.py - UPDATED VERSION for Faculty Grades and Counselor-only Sessions

from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from pymongo import MongoClient
from typing import List, Optional  # Added Optional for grade update
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
import uvicorn
from contextlib import asynccontextmanager
from enum import Enum
import uuid

# --- Configuration ---
MONGO_URI = "mongodb+srv://oblivionx2025_db_user:RKEXOw5UHtiKlbvX@cluster0.0czwexl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
SECRET_KEY = "your_super_secret_key_for_jwt"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30


# --- Enums ---
class FinancialStatus(str, Enum):
    paid = "Paid"
    unpaid = "Unpaid"


class SessionStatus(str, Enum):
    open = "Open"
    closed = "Closed"


# --- Lifespan & App Initialization ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    print("Application startup...")
    create_admin_on_startup()
    yield
    print("Application shutdown.")


app = FastAPI(
    title="OblivionX API",
    description="API for the AI-based Drop-out Prediction and Counseling System.",
    version="Final - R2",  # Updated version number
    lifespan=lifespan
)

# --- Database & Security Setup ---
client = MongoClient(MONGO_URI)
db = client.sih_db
users_collection = db.users
students_collection = db.students
faculty_collection = db.faculty
counselors_collection = db.counselors
classes_collection = db.classes
sessions_collection = db.counseling_sessions
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


# --- Security Helper Functions ---
def verify_password(plain_password, hashed_password): return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password): return pwd_context.hash(password)


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# --- Pydantic Models ---
class StudentModel(BaseModel):
    student_id: str
    name: str
    attendance_percentage: float
    latest_grade: float
    financial_status: FinancialStatus
    risk_status: str


class FacultyModel(BaseModel):
    faculty_id: str
    name: str
    department: str


class CounselorModel(BaseModel):
    counselor_id: str
    name: str
    specialization: str


class SessionModel(BaseModel):
    session_id: str
    student_id: str
    initiator_id: str
    session_date: datetime
    notes: str
    status: SessionStatus


class ClassModel(BaseModel):
    class_id: str
    class_name: str
    faculty_id: str
    student_ids: List[str]


class UserBase(BaseModel):
    username: str
    password: str
    name: str


class StudentCreate(UserBase):
    student_id: str
    initial_attendance: float
    initial_grade: float
    financial_status: FinancialStatus


class FacultyCreate(UserBase):
    department: str


class CounselorCreate(UserBase):
    specialization: str


class SessionCreate(BaseModel):
    student_id: str
    notes: str


class SessionUpdate(BaseModel):
    notes: str
    status: SessionStatus


class ClassCreate(BaseModel):
    class_name: str
    faculty_id: str


class AssignStudentToClass(BaseModel):
    student_id: str


class Token(BaseModel):
    access_token: str
    token_type: str
    user_role: str


# NEW: Model for Faculty Grade Update
class GradeUpdate(BaseModel):
    new_grade: float


# --- Startup, Dependency, and Intelligence Layer ---
def create_admin_on_startup():
    if not users_collection.find_one({"username": "admin@app.com"}):
        users_collection.insert_one(
            {"username": "admin@app.com", "hashed_password": get_password_hash("admin@123"), "role": "admin"})
        print("✅ Admin user 'admin@app.com' created.")


async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                                          detail="Could not validate credentials")
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if not username: raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = users_collection.find_one({"username": username})
    if not user: raise credentials_exception
    return user


def calculate_risk_status(attendance: float, grade: float, financial: FinancialStatus) -> str:
    risk_score = 0
    if attendance < 80: risk_score += 1
    if grade < 60: risk_score += 1
    if financial == FinancialStatus.unpaid: risk_score += 1
    if risk_score >= 3: return "High Risk"
    if risk_score == 2: return "Medium Risk"
    return "Low Risk"


# --- API Endpoints ---
@app.post("/token", response_model=Token, tags=["Authentication"])
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = users_collection.find_one({"username": form_data.username})
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Incorrect username or password")
    token_data = {"sub": user["username"], "role": user["role"]}
    access_token = create_access_token(data=token_data)
    return {"access_token": access_token, "token_type": "bearer", "user_role": user["role"]}


def _create_user_entry(username, password, role):
    if users_collection.find_one({"username": username}):
        raise HTTPException(status_code=400, detail=f"User '{username}' already exists.")
    users_collection.insert_one({"username": username, "hashed_password": get_password_hash(password), "role": role})


@app.post("/admin/create_student", status_code=status.HTTP_201_CREATED, tags=["Admin - User Management"])
async def create_student(data: StudentCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    _create_user_entry(data.username, data.password, "student")
    if students_collection.find_one({"student_id": data.student_id}): raise HTTPException(status_code=400,
                                                                                          detail=f"Student ID '{data.student_id}' already exists.")
    risk = calculate_risk_status(data.initial_attendance, data.initial_grade, data.financial_status)
    students_collection.insert_one(
        {"student_id": data.student_id, "name": data.name, "attendance_percentage": data.initial_attendance,
         "latest_grade": data.initial_grade, "financial_status": data.financial_status.value, "risk_status": risk})
    return {"message": "Student created successfully"}


@app.post("/admin/create_faculty", status_code=status.HTTP_201_CREATED, tags=["Admin - User Management"])
async def create_faculty(data: FacultyCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    _create_user_entry(data.username, data.password, "faculty")
    faculty_collection.insert_one({"faculty_id": data.username, "name": data.name, "department": data.department})
    return {"message": "Faculty created successfully"}


@app.post("/admin/create_counselor", status_code=status.HTTP_201_CREATED, tags=["Admin - User Management"])
async def create_counselor(data: CounselorCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    _create_user_entry(data.username, data.password, "counselor")
    counselors_collection.insert_one(
        {"counselor_id": data.username, "name": data.name, "specialization": data.specialization})
    return {"message": "Counselor created successfully"}


@app.get("/admin/faculty", response_model=List[FacultyModel], tags=["Admin - Data Retrieval"])
async def get_all_faculty(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    return list(faculty_collection.find({}, {"_id": 0}))


@app.get("/admin/counselors", response_model=List[CounselorModel], tags=["Admin - Data Retrieval"])
async def get_all_counselors(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    return list(counselors_collection.find({}, {"_id": 0}))


@app.patch("/admin/students/{student_id}/financials", response_model=StudentModel, tags=["Admin - Student Management"])
async def update_financial_status(student_id: str, status_update: FinancialStatus,
                                  current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    student = students_collection.find_one({"student_id": student_id})
    if not student: raise HTTPException(status_code=404, detail="Student not found")
    new_risk = calculate_risk_status(student["attendance_percentage"], student["latest_grade"], status_update)
    students_collection.update_one({"student_id": student_id},
                                   {"$set": {"financial_status": status_update.value, "risk_status": new_risk}})
    updated_student = students_collection.find_one({"student_id": student_id}, {"_id": 0})
    # Recalculate risk status to ensure it's up-to-date with current values
    updated_student["risk_status"] = calculate_risk_status(updated_student["attendance_percentage"],
                                                           updated_student["latest_grade"],
                                                           FinancialStatus(updated_student["financial_status"]))
    return updated_student


@app.post("/admin/classes", status_code=status.HTTP_201_CREATED, tags=["Admin - Class Management"])
async def create_class(class_data: ClassCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    class_id = str(uuid.uuid4())
    classes_collection.insert_one(
        {"class_id": class_id, "class_name": class_data.class_name, "faculty_id": class_data.faculty_id,
         "student_ids": []})
    return {"message": "Class created successfully", "class_id": class_id}


@app.post("/admin/classes/{class_id}/assign_student", tags=["Admin - Class Management"])
async def assign_student(class_id: str, assignment: AssignStudentToClass,
                         current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    result = classes_collection.update_one({"class_id": class_id},
                                           {"$addToSet": {"student_ids": assignment.student_id}})
    if result.matched_count == 0: raise HTTPException(status_code=404,
                                                      detail="Class not found or student already assigned")
    return {"message": f"Student {assignment.student_id} assigned to class {class_id}"}


@app.get("/admin/classes", response_model=List[ClassModel], tags=["Admin - Data Retrieval"])
async def get_all_classes(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    return list(classes_collection.find({}, {"_id": 0}))


# NEW: Faculty can update student grades
@app.patch("/faculty/students/{student_id}/grade", response_model=StudentModel, tags=["Faculty"])
async def update_student_grade(student_id: str, grade_update: GradeUpdate,
                               current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'faculty': raise HTTPException(status_code=403, detail="Only faculty can update grades")

    # Optional: Verify if this faculty member teaches the student's class
    # For simplicity, we'll allow any faculty to update any student's grade for now.
    # In a real system, you'd check `classes_collection` to see if `current_user["username"]`
    # is the `faculty_id` for any class that `student_id` is in.

    student = students_collection.find_one({"student_id": student_id})
    if not student: raise HTTPException(status_code=404, detail="Student not found")

    new_grade = grade_update.new_grade
    # Recalculate risk based on new grade
    current_financial_status = FinancialStatus(student["financial_status"])
    new_risk = calculate_risk_status(student["attendance_percentage"], new_grade, current_financial_status)

    students_collection.update_one(
        {"student_id": student_id},
        {"$set": {"latest_grade": new_grade, "risk_status": new_risk}}
    )
    updated_student = students_collection.find_one({"student_id": student_id}, {"_id": 0})
    return updated_student


@app.get("/faculty/my_classes", response_model=List[ClassModel], tags=["Faculty"])
async def get_my_classes(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'faculty': raise HTTPException(status_code=403, detail="Not authorized")
    classes = list(classes_collection.find({"faculty_id": current_user["username"]}, {"_id": 0}))
    return classes


@app.get("/faculty/classes/{class_id}/students", response_model=List[StudentModel], tags=["Faculty"])
async def get_students_in_class(class_id: str, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'faculty': raise HTTPException(status_code=403, detail="Not authorized")
    target_class = classes_collection.find_one({"class_id": class_id})
    if not target_class or target_class["faculty_id"] != current_user["username"]:
        raise HTTPException(status_code=403, detail="You are not assigned to this class")
    student_ids = target_class.get("student_ids", [])
    if not student_ids: return []
    return list(students_collection.find({"student_id": {"$in": student_ids}}, {"_id": 0}))


@app.get("/students", response_model=List[StudentModel], tags=["Students"])
async def get_all_students(current_user: dict = Depends(get_current_user)):
    if current_user["role"] not in ["admin", "counselor"]:  # Faculty will get students via their classes
        raise HTTPException(status_code=403, detail="Not authorized")
    return list(students_collection.find({}, {"_id": 0}))


@app.get("/students/me", response_model=StudentModel, tags=["Students"])
async def get_my_data(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'student': raise HTTPException(status_code=403, detail="Not authorized")
    student_data = students_collection.find_one({"student_id": current_user["username"]}, {"_id": 0})
    if not student_data: raise HTTPException(status_code=404, detail="Student data not found")
    return student_data


@app.post("/sessions", response_model=SessionModel, status_code=status.HTTP_201_CREATED, tags=["Counseling"])
async def create_session(session_data: SessionCreate, current_user: dict = Depends(get_current_user)):
    # ✅ FIX: Only counselors can create sessions now
    if current_user["role"] != "counselor":
        raise HTTPException(status_code=403, detail="Only counselors can create sessions")
    new_session = {"session_id": str(uuid.uuid4()), "student_id": session_data.student_id,
                   "initiator_id": current_user["username"], "session_date": datetime.utcnow(),
                   "notes": session_data.notes, "status": SessionStatus.open.value}
    sessions_collection.insert_one(new_session)
    new_session.pop("_id", None)
    return new_session


@app.get("/sessions/student/{student_id}", response_model=List[SessionModel], tags=["Counseling"])
async def get_sessions_for_student(student_id: str, current_user: dict = Depends(get_current_user)):
    # This endpoint is accessible by anyone who has access to student data (admin, faculty, counselor)
    # The 'get_current_user' decorator already handles basic authentication.
    # Further checks like "can this faculty see this student's sessions?" might be added for more strict security.
    return list(sessions_collection.find({"student_id": student_id}, {"_id": 0}))


@app.patch("/sessions/{session_id}", response_model=SessionModel, tags=["Counseling"])
async def update_session(session_id: str, session_update: SessionUpdate,
                         current_user: dict = Depends(get_current_user)):
    # ✅ FIX: Only counselors can update sessions now (if faculty could initiate, they might update)
    if current_user["role"] != "counselor":
        raise HTTPException(status_code=403, detail="Only counselors can update sessions")
    result = sessions_collection.update_one({"session_id": session_id}, {"$set": session_update.dict()})
    if result.matched_count == 0: raise HTTPException(status_code=404, detail="Session not found")
    return sessions_collection.find_one({"session_id": session_id}, {"_id": 0})


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)