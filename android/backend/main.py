# main.py - FINAL CORRECTED VERSION

from fastapi import FastAPI, HTTPException, status, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from pydantic import BaseModel, Field
from pymongo import MongoClient
from typing import List
from passlib.context import CryptContext
from jose import JWTError, jwt
from datetime import datetime, timedelta
import uvicorn
from contextlib import asynccontextmanager # <--- IMPORT THIS

# --- Configuration ---
MONGO_URI = "mongodb+srv://oblivionx2025_db_user:RKEXOw5UHtiKlbvX@cluster0.0czwexl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
SECRET_KEY = "your_super_secret_key_for_jwt"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# --- Lifespan Event Handler (The Fix for Deprecation Warning) ---
@asynccontextmanager
async def lifespan(app: FastAPI):
    # This code runs on startup
    print("Application startup...")
    create_admin_on_startup()
    yield
    # This code runs on shutdown
    print("Application shutdown.")

# --- App Initialization ---
app = FastAPI(
    title="OblivionX API",
    description="API for the AI-based Drop-out Prediction and Counseling System.",
    version="2.0.0",
    lifespan=lifespan # <--- ADD THIS
)

# --- Database Connection ---
try:
    client = MongoClient(MONGO_URI)
    db = client.sih_db
    students_collection = db.students
    users_collection = db.users
    client.admin.command('ping')
    print("✅ Successfully connected to MongoDB Atlas!")
except Exception as e:
    print(f"🔥 Failed to connect to MongoDB Atlas: {e}")

# --- Security & Hashing ---
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

# --- Security Helper Functions ---
def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

# --- Pydantic Models ---
class StudentModel(BaseModel):
    student_id: str = Field(...)
    name: str = Field(...)
    attendance_percentage: float = Field(...)
    latest_grade: float = Field(...)
    risk_status: str = Field(default="Not Assessed")

class UserModel(BaseModel):
    username: str
    role: str

class UserCreate(UserModel):
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user_role: str

# --- Startup Function (now called from lifespan) ---
def create_admin_on_startup():
    admin_username = "admin@app.com"
    admin_password = "admin@123"
    if not users_collection.find_one({"username": admin_username}):
        hashed_password = get_password_hash(admin_password)
        admin_user = {
            "username": admin_username,
            "hashed_password": hashed_password,
            "role": "admin"
        }
        users_collection.insert_one(admin_user)
        print(f"✅ Admin user '{admin_username}' created.")

# (The rest of the file remains the same... just paste this over your old code)
# --- Dependency for getting current user ---
async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    user = users_collection.find_one({"username": username})
    if user is None:
        raise credentials_exception
    return user

# --- Intelligence Layer ---
def calculate_risk_status(attendance: float, grade: float) -> str:
    if attendance < 75 and grade < 50: return "High Risk"
    elif attendance < 80 or grade < 60: return "Medium Risk"
    else: return "Low Risk"

# --- API Endpoints ---
@app.post("/token", response_model=Token, tags=["Authentication"])
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    user = users_collection.find_one({"username": form_data.username})
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token_data = {"sub": user["username"], "role": user["role"]}
    access_token = create_access_token(data=token_data)
    return {"access_token": access_token, "token_type": "bearer", "user_role": user["role"]}

@app.post("/users", response_model=UserModel, tags=["Admin"])
async def create_user(user: UserCreate, current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'admin':
        raise HTTPException(status_code=403, detail="Not authorized to create users")
    if users_collection.find_one({"username": user.username}):
        raise HTTPException(status_code=400, detail="Username already registered")
    hashed_password = get_password_hash(user.password)
    user_data = user.dict()
    user_data["hashed_password"] = hashed_password
    del user_data["password"]
    users_collection.insert_one(user_data)
    return user

@app.get("/students", response_model=List[StudentModel], tags=["Students"])
async def get_all_students(current_user: dict = Depends(get_current_user)):
    if current_user["role"] not in ["admin", "faculty", "counselor"]:
        raise HTTPException(status_code=403, detail="Not authorized for this action")
    students = list(students_collection.find({}, {"_id": 0}))
    return students

@app.get("/students/me", response_model=StudentModel, tags=["Students"])
async def get_my_data(current_user: dict = Depends(get_current_user)):
    if current_user["role"] != 'student':
        raise HTTPException(status_code=403, detail="Only students can access this route")
    student_data = users_collection.find_one({"student_id": current_user["username"]}, {"_id": 0})
    if not student_data:
        raise HTTPException(status_code=404, detail="Student data not found for logged-in user")
    return student_data

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )