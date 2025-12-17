import os
import json
import logging
from fastapi import FastAPI, HTTPException, APIRouter
from pydantic import BaseModel, EmailStr
import boto3
from fastapi.middleware.cors import CORSMiddleware

DB_ENGINE = os.getenv("DB_ENGINE", "dynamodb").lower()
if DB_ENGINE == "rds":
    from utils import rds as db
else:
    from utils import dynamodb as db


class LoginRequest(BaseModel):
    email: EmailStr
    password: str

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="CS3 NCA Employee API")
api = APIRouter(prefix="/api")

allowed_origins = os.getenv("CORS_ALLOW_ORIGINS", "*")
origins = [origin.strip() for origin in allowed_origins.split(",") if origin.strip()]

# Allow the frontend load balancer to call the backend API from the browser
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins if origins else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

EVENT_SOURCE = "eks.backend"
AWS_REGION = os.getenv("AWS_REGION", "eu-central-1")
ALLOWED_EMAILS = [e.strip().lower() for e in os.getenv("PORTAL_ALLOWED_EMAILS", "hr@innovatech.com").split(",") if e.strip()]

eventbridge = boto3.client("events", region_name=AWS_REGION)


class EmployeeCreateRequest(BaseModel):
    name: str
    email: EmailStr
    department: str


@api.get("/health")
def health():
    return {"status": "ok"}


@api.post("/auth/login")
def login(payload: LoginRequest):
    email_lower = payload.email.lower()
    if ALLOWED_EMAILS and email_lower not in ALLOWED_EMAILS:
        raise HTTPException(status_code=403, detail="Geen toegang")
    emp = db.find_employee_by_email(payload.email)
    if not emp:
        raise HTTPException(status_code=401, detail="Login mislukt")
    pwd_record = db.get_employee_password(emp["employeeId"]) or db.find_password_by_email(payload.email)
    if not pwd_record or pwd_record.get("password") != payload.password:
        raise HTTPException(status_code=401, detail="Login mislukt")
    name = emp.get("name") or payload.email.split("@")[0]
    return {"email": payload.email, "name": name}


@api.post("/employees")
def create_employee_endpoint(payload: EmployeeCreateRequest):
    employee_id = db.create_employee(payload.dict())

    # stuur event naar EventBridge
    detail = {
        "employeeId": employee_id,
        "email": payload.email,
        "name": payload.name,
        "department": payload.department,
    }

    eventbridge.put_events(
        Entries=[
            {
                "Source": EVENT_SOURCE,
                "DetailType": "employeeCreated",
                "Detail": json.dumps(detail),
            }
        ]
    )

    return {"employeeId": employee_id, "status": "CREATED"}


@api.get("/employees/{employee_id}")
def get_employee_endpoint(employee_id: str):
    item = db.get_employee(employee_id)
    if not item:
        raise HTTPException(status_code=404, detail="Employee not found")
    return item


@api.get("/employees")
def list_employees_endpoint():
    return db.list_employees()


@api.put("/employees/{employee_id}")
def update_employee_endpoint(employee_id: str, payload: EmployeeCreateRequest):
    item = db.get_employee(employee_id)
    if not item:
        raise HTTPException(status_code=404, detail="Employee not found")

    updated = db.update_employee(
        employee_id,
        {
            "name": payload.name,
            "email": payload.email,
            "department": payload.department,
        },
    )
    return updated


@api.delete("/employees/{employee_id}")
def delete_employee_endpoint(employee_id: str):
    item = db.get_employee(employee_id)
    if not item:
        raise HTTPException(status_code=404, detail="Employee not found")
    # direct delete for now (skip async worker cleanup)
    db.delete_employee(employee_id)
    logger.info(f"[DELETE] Employee {employee_id} deleted")
    return {"deleted": True, "employeeId": employee_id, "status": "DELETED"}


app.include_router(api)
