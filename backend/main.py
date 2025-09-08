# main.py - FINAL VERSION with Detailed Profiles for All Roles

from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from pymongo import MongoClient
from typing import List
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
import uvicorn
from contextlib import asynccontextmanager
from enum import Enum

# --- Configuration ---
MONGO_URI = "mongodb+srv://oblivionx2025_db_user:RKEXOw5UHtiKlbvX@cluster0.0czwexl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
SECRET_KEY = "your_super_secret_key_for_jwt"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30


# --- Enums for validation ---
class FinancialStatus(str, Enum):
    paid = "Paid"
    unpaid = "Unpaid"


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
    version="5.0.0",
    lifespan=lifespan
)

# --- Database & Security Setup ---
client = MongoClient(MONGO_URI)
db = client.sih_db
users_collection = db.users
students_collection = db.students
faculty_collection = db.faculty  # <-- NEW COLLECTION
counselors_collection = db.counselors  # <-- NEW COLLECTION
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


def verify_password(p, h): return pwd_context.verify(p, h)


def get_password_hash(p): return pwd_context.hash(p)


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


# --- Pydantic Models (Updated) ---
# Base models for user creation
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


# Models for data retrieval
class StudentModel(BaseModel):
    student_id: str
    name: str
    attendance_percentage: float
    latest_grade: float
    financial_status: FinancialStatus
    risk_status: str


class FacultyModel(BaseModel):
    faculty_id: str  # Will be the same as username
    name: str
    department: str


class CounselorModel(BaseModel):
    counselor_id: str  # Will be the same as username
    name: str
    specialization: str


class Token(BaseModel):
    access_token: str
    token_type: str
    user_role: str


# --- Startup, Dependency, and Intelligence Layer (Same as before) ---
def create_admin_on_startup():
    if not users_collection.find_one({"username": "admin@app.com"}):
        hashed_password = get_password_hash("admin@123")
        users_collection.insert_one({"username": "admin@app.com", "hashed_password": hashed_password, "role": "admin"})
        print("✅ Admin user 'admin@app.com' created.")


async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if not username: raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token")
    user = users_collection.find_one({"username": username})
    if not user: raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
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
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect username or password")
    token_data = {"sub": user["username"], "role": user["role"]}
    access_token = create_access_token(data=token_data)
    return {"access_token": access_token, "token_type": "bearer", "user_role": user["role"]}


# --- Admin Endpoints for User Creation ---
def _create_user_entry(username, password, role):
    if users_collection.find_one({"username": username}):
        raise HTTPException(status_code=400, detail=f"User '{username}' already exists.")
    hashed_password = get_password_hash(password)
    users_collection.insert_one({"username": username, "hashed_password": hashed_password, "role": role})


@app.post("/admin/create_student", status_code=status.HTTP_201_CREATED, tags=["Admin"])
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


@app.post("/admin/create_faculty", status_code=status.HTTP_201_CREATED, tags=["Admin"])
async def create_faculty(data: FacultyCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    _create_user_entry(data.username, data.password, "faculty")
    faculty_collection.insert_one({"faculty_id": data.username, "name": data.name, "department": data.department})
    return {"message": "Faculty created successfully"}


@app.post("/admin/create_counselor", status_code=status.HTTP_201_CREATED, tags=["Admin"])
async def create_counselor(data: CounselorCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    _create_user_entry(data.username, data.password, "counselor")
    counselors_collection.insert_one(
        {"counselor_id": data.username, "name": data.name, "specialization": data.specialization})
    return {"message": "Counselor created successfully"}


# --- Admin Endpoints for Data Retrieval ---
@app.get("/admin/faculty", response_model=List[FacultyModel], tags=["Admin"])
async def get_all_faculty(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    return list(faculty_collection.find({}, {"_id": 0}))


@app.get("/admin/counselors", response_model=List[CounselorModel], tags=["Admin"])
async def get_all_counselors(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    return list(counselors_collection.find({}, {"_id": 0}))


# (Remaining endpoints for students, financials, etc., are the same as before)
@app.patch("/admin/students/{student_id}/financials", response_model=StudentModel, tags=["Admin"])
async def update_financial_status(student_id: str, status_update: FinancialStatus,
                                  current_user: dict = Depends(get_current_user)):
    # ... (code is the same as the previous version)
    if current_user["role"] != 'admin': raise HTTPException(status_code=403, detail="Not authorized")
    student = students_collection.find_one({"student_id": student_id})
    if not student: raise HTTPException(status_code=404, detail="Student not found")
    new_risk = calculate_risk_status(student["attendance_percentage"], student["latest_grade"], status_update)
    students_collection.update_one({"student_id": student_id},
                                   {"$set": {"financial_status": status_update.value, "risk_status": new_risk}})
    return students_collection.find_one({"student_id": student_id}, {"_id": 0})


@app.get("/students", response_model=List[StudentModel], tags=["Students"])
async def get_all_students(current_user: dict = Depends(get_current_user)):
    if current_user["role"] not in ["admin", "faculty", "counselor"]: raise HTTPException(status_code=403,
                                                                                          detail="Not authorized")
    return list(students_collection.find({}, {"_id": 0}))


@app.get("/students/me", response_model=StudentModel, tags=["Students"])
async def get_my_data(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'student': raise HTTPException(status_code=403,
                                                              detail="Only students can access this route")
    student_data = students_collection.find_one({"student_id": current_user["username"]}, {"_id": 0})
    if not student_data: raise HTTPException(status_code=404, detail="Student data not found for this user")
    return student_data


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)