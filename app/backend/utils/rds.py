import os
import uuid
import time
import psycopg2
from typing import Dict, Any, List

DB_HOST = os.getenv("DB_HOST", "")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "cs3_db")
DB_USER = os.getenv("DB_USER", "dbadmin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")

EMPLOYEE_FIELDS = [
    "employeeId",
    "name",
    "email",
    "department",
    "status",
    "workspaceId",
    "instanceId",
    "rdp_file",
    "error",
    "updatedAt",
]
ALLOWED_UPDATE_FIELDS = set(EMPLOYEE_FIELDS) - {"employeeId"}


def _connect():
    if not DB_HOST or not DB_PASSWORD:
        raise RuntimeError("RDS not configured (DB_HOST/DB_PASSWORD missing)")
    conn = psycopg2.connect(
        host=DB_HOST,
        port=DB_PORT,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
    )
    conn.autocommit = True
    return conn


def _ensure_tables():
    conn = _connect()
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS employees (
            employeeId TEXT PRIMARY KEY,
            name TEXT,
            email TEXT UNIQUE,
            department TEXT,
            status TEXT,
            workspaceId TEXT,
            instanceId TEXT,
            rdp_file TEXT,
            error TEXT,
            updatedAt BIGINT
        )
        """
    )
    # backfill for existing deployments that predate the extra columns
    cur.execute("ALTER TABLE employees ADD COLUMN IF NOT EXISTS instanceId TEXT")
    cur.execute("ALTER TABLE employees ADD COLUMN IF NOT EXISTS rdp_file TEXT")
    cur.execute("ALTER TABLE employees ADD COLUMN IF NOT EXISTS error TEXT")
    cur.execute("ALTER TABLE employees ADD COLUMN IF NOT EXISTS updatedAt BIGINT")

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS employee_passwords (
            employeeId TEXT PRIMARY KEY,
            email TEXT,
            password TEXT,
            updatedAt BIGINT
        )
        """
    )
    cur.close()
    conn.close()


_ensure_tables()


def _row_to_employee(row) -> Dict[str, Any]:
    return {
        "employeeId": row[0],
        "name": row[1],
        "email": row[2],
        "department": row[3],
        "status": row[4],
        "workspaceId": row[5],
        "instanceId": row[6],
        "rdp_file": row[7],
        "error": row[8],
        "updatedAt": row[9],
    }


def create_employee(data: Dict[str, Any]) -> str:
    employee_id = str(uuid.uuid4())
    conn = _connect()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO employees(employeeId, name, email, department, status, updatedAt)
        VALUES (%s,%s,%s,%s,%s,%s)
        """,
        (
            employee_id,
            data.get("name"),
            data.get("email"),
            data.get("department"),
            "CREATED",
            int(time.time()),
        ),
    )
    cur.close()
    conn.close()
    return employee_id


def get_employee(employee_id: str) -> Dict[str, Any]:
    conn = _connect()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT employeeId, name, email, department, status, workspaceId, instanceId, rdp_file, error, updatedAt
        FROM employees
        WHERE employeeId=%s
        """,
        (employee_id,),
    )
    row = cur.fetchone()
    cur.close()
    conn.close()
    if not row:
        return None
    return _row_to_employee(row)


def list_employees() -> List[Dict[str, Any]]:
    conn = _connect()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT employeeId, name, email, department, status, workspaceId, instanceId, rdp_file, error, updatedAt
        FROM employees
        """
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [_row_to_employee(r) for r in rows]


def find_employee_by_email(email: str) -> Dict[str, Any] | None:
    if not email:
        return None
    conn = _connect()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT employeeId, name, email, department, status, workspaceId, instanceId, rdp_file, error, updatedAt
        FROM employees
        WHERE email=%s
        """,
        (email,),
    )
    row = cur.fetchone()
    cur.close()
    conn.close()
    if not row:
        return None
    return _row_to_employee(row)


def store_employee_password(employee_id: str, email: str, password: str):
    conn = _connect()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO employee_passwords(employeeId,email,password,updatedAt) VALUES (%s,%s,%s,%s) ON CONFLICT (employeeId) DO UPDATE SET password = EXCLUDED.password, email = EXCLUDED.email, updatedAt = EXCLUDED.updatedAt",
        (employee_id, email, password, int(time.time())),
    )
    cur.close()
    conn.close()


def get_employee_password(employee_id: str) -> Dict[str, Any] | None:
    conn = _connect()
    cur = conn.cursor()
    cur.execute("SELECT employeeId,email,password,updatedAt FROM employee_passwords WHERE employeeId=%s", (employee_id,))
    row = cur.fetchone()
    cur.close()
    conn.close()
    if not row:
        return None
    return {"employeeId": row[0], "email": row[1], "password": row[2], "updatedAt": row[3]}


def find_password_by_email(email: str) -> Dict[str, Any] | None:
    if not email:
        return None
    conn = _connect()
    cur = conn.cursor()
    cur.execute("SELECT employeeId,email,password,updatedAt FROM employee_passwords WHERE email=%s LIMIT 1", (email,))
    row = cur.fetchone()
    cur.close()
    conn.close()
    if not row:
        return None
    return {"employeeId": row[0], "email": row[1], "password": row[2], "updatedAt": row[3]}


def update_employee(employee_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
    if not data:
        return get_employee(employee_id)
    keys: list[str] = []
    values: list[Any] = []
    for k, v in data.items():
        if k not in ALLOWED_UPDATE_FIELDS:
            continue
        keys.append(f"{k} = %s")
        values.append(v)
    if not keys:
        return get_employee(employee_id)
    values.append(employee_id)
    sql = f"""
        UPDATE employees
        SET {', '.join(keys)}
        WHERE employeeId = %s
        RETURNING employeeId, name, email, department, status, workspaceId, instanceId, rdp_file, error, updatedAt
    """
    conn = _connect()
    cur = conn.cursor()
    cur.execute(sql, tuple(values))
    row = cur.fetchone()
    cur.close()
    conn.close()
    if not row:
        return None
    return _row_to_employee(row)


def delete_employee(employee_id: str) -> None:
    conn = _connect()
    cur = conn.cursor()
    cur.execute("DELETE FROM employees WHERE employeeId=%s", (employee_id,))
    cur.close()
    conn.close()
