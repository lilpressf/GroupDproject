import os
import json
import logging
import time
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
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL", "")

eventbridge = boto3.client("events", region_name=AWS_REGION)
sqs = boto3.client("sqs", region_name=AWS_REGION)


class EmployeeCreateRequest(BaseModel):
    name: str | None = None
    email: EmailStr
    department: str
    studentId: str | None = None
    firstName: str | None = None
    lastName: str | None = None
    displayName: str | None = None


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
    # Bepaal een display naam (payload.name > displayName > first+last > email prefix)
    fallback_name = payload.displayName
    if not fallback_name:
        parts = [payload.firstName, payload.lastName]
        parts = [p for p in parts if p]
        if parts:
            fallback_name = " ".join(parts)
    name_value = payload.name or fallback_name or payload.email.split("@")[0]

    employee_id = db.create_employee(
        {
            "name": name_value,
            "email": payload.email,
            "department": payload.department,
        }
    )

    # stuur event naar EventBridge
    detail = {
        "employeeId": employee_id,
        "email": payload.email,
        "name": name_value,
        "department": payload.department,
        "studentId": payload.studentId,
        "firstName": payload.firstName,
        "lastName": payload.lastName,
        "displayName": payload.displayName or name_value,
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
    if SQS_QUEUE_URL:
        db.update_employee(employee_id, {"status": "DELETING", "updatedAt": int(time.time())})
    # enqueue delete for worker cleanup
    try:
        detail = {
            "employeeId": employee_id,
            "action": "delete",
            "email": item.get("email", ""),
            "department": item.get("department", ""),
            "workspaceId": item.get("workspaceId", ""),
        }
        sqs.send_message(QueueUrl=SQS_QUEUE_URL, MessageBody=json.dumps({"detail": detail}))
    except Exception as exc:
        # fall back to direct delete if queue fails
        db.delete_employee(employee_id)
        raise HTTPException(status_code=500, detail=f"Failed to queue delete, removed DB only: {exc}")
    logger.info(f"[DELETE] Employee {employee_id} deleted")
    return {"deleted": True, "employeeId": employee_id, "status": "DELETED"}


app.include_router(api)
