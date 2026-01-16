import React, { useCallback, useEffect, useMemo, useState } from "react";
import {
  createEmployee,
  listEmployees,
  updateEmployee,
  deleteEmployee,
  setAuthEmail as setApiAuthEmail,
} from "./api";
import "./style.css";

const emptyForm = { name: "", email: "", department: "" };
const defaultAuthUser = { email: "demo@local", name: "Dashboard User" };
const LOCAL_OPS_KEY = "narrekappe-recent-ops";
const AUTH_TOKEN_KEY = "narrekappe-admin-auth";
const DEMO_ADMIN_USER = { email: "admin@narrekappe.com", password: "LetMeIn123!" };

export default function App() {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const [employees, setEmployees] = useState([]);
  const [selectedId, setSelectedId] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [submitting, setSubmitting] = useState(false);
  const [recentOps, setRecentOps] = useState([]); // array of { id, severity, msg, ts }
  const [session, setSession] = useState(false);
  const [loginForm, setLoginForm] = useState({ email: "", password: "" });

  const selectedEmployee = useMemo(
    () => employees.find((e) => e.employeeId === selectedId) || null,
    [employees, selectedId]
  );

  const fetchEmployees = useCallback(async () => {
    try {
      setLoading(true);
      const res = await listEmployees();
      setEmployees(res.data || []);
    } catch (err) {
      setStatus({ ok: false, msg: "Failed to load list." });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    setApiAuthEmail(defaultAuthUser.email);
    // restore recent ops from localStorage
    if (typeof window !== "undefined") {
      try {
        const storedAuth = window.localStorage.getItem(AUTH_TOKEN_KEY);
        if (storedAuth === "true") {
          setSession(true);
        }
        const raw = window.localStorage.getItem(LOCAL_OPS_KEY);
        if (raw) {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setRecentOps(parsed);
          }
        }
      } catch (e) {
        // ignore parse errors
      }
    }
    fetchEmployees();
  }, [fetchEmployees]);

  // persist recent ops to localStorage
  useEffect(() => {
    if (typeof window !== "undefined") {
      try {
        window.localStorage.setItem(LOCAL_OPS_KEY, JSON.stringify(recentOps));
      } catch (e) {
        // ignore storage errors (private mode, etc.)
      }
    }
  }, [recentOps]);

  const clearAlerts = () => {
    setRecentOps([]);
    if (typeof window !== "undefined") {
      try {
        window.localStorage.removeItem(LOCAL_OPS_KEY);
      } catch (e) {
        // ignore storage errors
      }
    }
  };

  const handleLogin = (e) => {
    if (e) e.preventDefault();
    const ok =
      loginForm.email.trim().toLowerCase() === DEMO_ADMIN_USER.email &&
      loginForm.password === DEMO_ADMIN_USER.password;
    if (ok) {
      setSession(true);
      if (typeof window !== "undefined") {
        window.localStorage.setItem(AUTH_TOKEN_KEY, "true");
      }
    } else {
      setStatus({ ok: false, msg: "Invalid admin credentials." });
    }
  };

  const handleLogout = () => {
    setSession(false);
    setStatus(null);
    if (typeof window !== "undefined") {
      window.localStorage.removeItem(AUTH_TOKEN_KEY);
    }
  };

  const isFormValid = () =>
    form.name.trim().length > 0 &&
    form.email.trim().length > 0 &&
    form.department.trim().length > 0;

  const handleOnboard = async (e) => {
    if (e) e.preventDefault();
    if (!isFormValid()) {
      setStatus({ ok: false, msg: "Please fill name, email, and class." });
      return;
    }
    setStatus(null);
    setSubmitting(true);

    try {
      if (selectedId) {
        await updateEmployee(selectedId, form);
        setStatus({ ok: true, msg: "Employee updated." });
        setRecentOps((prev) => [
          { id: `op-${Date.now()}`, severity: "success", msg: `Updated ${form.name || selectedId}.`, ts: Date.now() },
          ...prev,
        ].slice(0, 3));
      } else {
        await createEmployee(form);
        setStatus({
          ok: true,
          msg: "Employee created. AD account is being provisioned.",
        });
        setRecentOps((prev) => [
          { id: `op-${Date.now()}`, severity: "success", msg: `Onboarding started for ${form.name}.`, ts: Date.now() },
          ...prev,
        ].slice(0, 3));
      }
      setForm(emptyForm);
      setSelectedId(null);
      await fetchEmployees();
    } catch (err) {
      setStatus({
        ok: false,
        msg: selectedId ? "Update failed." : "Something went wrong creating the employee.",
      });
      setRecentOps((prev) => [
        { id: `op-${Date.now()}`, severity: "danger", msg: selectedId ? "Update failed." : "Onboarding failed to start.", ts: Date.now() },
        ...prev,
      ].slice(0, 3));
    } finally {
      setSubmitting(false);
    }
  };

  const onSelectEmployee = (emp) => {
    setSelectedId(emp.employeeId);
    setForm({
      name: emp.name || "",
      email: emp.email || "",
      department: emp.department || "",
    });
    setStatus(null);
  };

  const onDelete = async () => {
    if (!selectedId) return;
    setSubmitting(true);
    setStatus(null);
    try {
      const res = await deleteEmployee(selectedId);
      if (res?.data?.status === "DELETING") {
        setStatus({
          ok: true,
          msg: "Delete started; resources are being cleaned up. This can take a few minutes.",
        });
        setRecentOps((prev) => [
          { id: `op-${Date.now()}`, severity: "warning", msg: "Offboarding in progress...", ts: Date.now() },
          ...prev,
        ].slice(0, 3));
      } else {
        setStatus({ ok: true, msg: "Employee removed." });
        setRecentOps((prev) => [
          { id: `op-${Date.now()}`, severity: "success", msg: "Offboarding completed.", ts: Date.now() },
          ...prev,
        ].slice(0, 3));
      }
      setForm(emptyForm);
      setSelectedId(null);
      await fetchEmployees();
    } catch (err) {
      setStatus({ ok: false, msg: "Delete failed." });
      setRecentOps((prev) => [
        { id: `op-${Date.now()}`, severity: "danger", msg: "Offboarding failed to start.", ts: Date.now() },
        ...prev,
      ].slice(0, 3));
    } finally {
      setSubmitting(false);
    }
  };

  const onNewClick = () => {
    setSelectedId(null);
    setForm(emptyForm);
    setStatus(null);
  };

  const alerts = useMemo(() => {
    const a = [];
    // derive from employee statuses
    employees.forEach((emp) => {
      if (emp.status === "FAILED") {
        a.push({
          id: `fail-${emp.employeeId}`,
          title: "Onboarding/Offboarding failed",
          detail: `${emp.name || emp.employeeId} (${emp.employeeId})`,
          severity: "danger",
        });
      }
      if (emp.status === "PROVISIONING" || emp.status === "DELETING") {
        a.push({
          id: `pending-${emp.employeeId}`,
          title: "In progress",
          detail: `${emp.name || emp.employeeId} is still ${emp.status?.toLowerCase()}`,
          severity: "warning",
        });
      }
    });
    // recent ops history (max 3)
    recentOps.forEach((op) => {
      a.push({
        id: op.id,
        title: op.severity === "success" ? "Completed" : op.severity === "warning" ? "In progress" : "Failed",
        detail: op.msg,
        severity: op.severity,
      });
    });
    return a;
  }, [employees, recentOps]);

  if (!session) {
    return (
      <div className="min-h-screen bg-gray-900 text-gray-100 flex items-center justify-center px-4">
        <form
          onSubmit={handleLogin}
          className="bg-gray-800 border border-gray-700 rounded-xl p-6 w-full max-w-md space-y-4 shadow-lg"
        >
          <div className="text-center">
            <h1 className="text-2xl font-semibold">Admin Login</h1>
            <p className="text-gray-400 text-sm mt-2">
              Sign in to manage onboarding/offboarding.
            </p>
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-1">Admin Email</label>
            <input
              type="email"
              className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
              placeholder="admin@narrekappe.com"
              value={loginForm.email}
              onChange={(e) => setLoginForm({ ...loginForm, email: e.target.value })}
              required
            />
          </div>
          <div>
            <label className="block text-sm text-gray-300 mb-1">Password</label>
            <input
              type="password"
              className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
              placeholder="••••••••"
              value={loginForm.password}
              onChange={(e) => setLoginForm({ ...loginForm, password: e.target.value })}
              required
            />
          </div>
          {status?.msg && !status.ok && (
            <div className="bg-red-900/30 border border-red-500/60 text-red-100 rounded p-3 text-sm">
              {status.msg}
            </div>
          )}
          <button
            type="submit"
            className="w-full bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded-lg font-medium shadow"
          >
            Sign In
          </button>
          <div className="text-xs text-gray-500 text-center">
            Demo credentials: {DEMO_ADMIN_USER.email} / {DEMO_ADMIN_USER.password}
          </div>
        </form>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100">
      <nav className="bg-gray-800 border-b border-gray-700 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">Training Platform Admin Dashboard</h1>
            <p className="text-gray-400 text-sm mt-1">
              Onboard / Offboard Students System Overview
            </p>
          </div>
          <div className="text-sm text-gray-300">{defaultAuthUser.name}</div>
          <button
            onClick={handleLogout}
            className="ml-4 text-xs text-gray-400 hover:text-gray-200 border border-gray-600 px-3 py-1 rounded"
          >
            Log out
          </button>
        </div>
      </nav>

      <main className="max-w-6xl mx-auto p-6 space-y-8">
        <section className="bg-gray-800 rounded-xl p-6 shadow-lg">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <i className="fa-solid fa-users-gear text-blue-400 text-lg"></i>
              <div>
                <h2 className="text-xl font-semibold">Student Management</h2>
                <p className="text-gray-400 text-sm">Onboard or offboard students quickly.</p>
              </div>
            </div>
            <div className="flex gap-3">
              <button
                className="bg-blue-600 hover:bg-blue-700 px-4 py-2 rounded-lg font-medium shadow"
                onClick={handleOnboard}
                disabled={submitting || !isFormValid()}
              >
                <i className="fa-solid fa-user-plus mr-2"></i>
                {selectedId ? "Update Student" : "Onboard Student"}
              </button>
              <button
                className="bg-red-600 hover:bg-red-700 px-4 py-2 rounded-lg font-medium shadow"
                onClick={onDelete}
                disabled={!selectedId || submitting || selectedEmployee?.status === "DELETING"}
              >
                <i className="fa-solid fa-user-minus mr-2"></i> Offboard Student
              </button>
            </div>
          </div>

          <div className="mt-5 bg-gray-700 rounded-lg p-4 text-gray-300">
            <strong>Status:</strong>{" "}
            {status?.msg ? status.msg : "Ready for the next action..."}
          </div>

          <div className="grid md:grid-cols-2 gap-6 mt-6">
            <form onSubmit={handleOnboard} className="space-y-4">
              <div>
                <label className="block text-sm text-gray-300 mb-1">Name</label>
                <input
                  type="text"
                  className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
                  placeholder="e.g. Alex Janssen"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                />
              </div>

              <div>
                <label className="block text-sm text-gray-300 mb-1">Email</label>
                <input
                  type="email"
                  className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
                  placeholder="user@example.com"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  required
                />
              </div>

              <div>
                <label className="block text-sm text-gray-300 mb-1">Class</label>
                <input
                  type="text"
                  className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
                  placeholder="e.g. Class A, Class B"
                  value={form.department}
                  onChange={(e) => setForm({ ...form, department: e.target.value })}
                  required
                />
              </div>

              <div className="flex gap-3 text-sm text-gray-400">
                <span>Tip: fill the fields and use Onboard/Offboard above.</span>
                <button
                  type="button"
                  className="text-blue-400 hover:text-blue-300 underline"
                  onClick={onNewClick}
                >
                  Clear fields
                </button>
              </div>
            </form>

            <div>
              <div className="flex items-center gap-2 mb-3">
                <i className="fa-solid fa-list text-yellow-400"></i>
                <h3 className="text-lg font-semibold">Current employees</h3>
              </div>

              <div className="space-y-2">
                {loading && <div className="text-gray-400">Loading...</div>}
                {!loading && employees.length === 0 && (
                  <div className="text-gray-400">No employees yet.</div>
                )}
                {!loading &&
                  employees.map((emp) => (
                    <button
                      key={emp.employeeId}
                      className={`w-full text-left p-3 rounded-lg flex items-center justify-between border ${
                        selectedId === emp.employeeId
                          ? "border-blue-500 bg-gray-700"
                          : "border-gray-700 bg-gray-900"
                      }`}
                      onClick={() => onSelectEmployee(emp)}
                    >
                      <div>
                        <p className="font-medium text-gray-100">
                          {emp.name}
                          {emp.status === "DELETING" && (
                            <span className="text-gray-400 ml-2">Cleaning up...</span>
                          )}
                        </p>
                        <p className="text-sm text-gray-400">
                          {emp.email}  {emp.department}
                        </p>
                      </div>
                      <div className="text-xs px-2 py-1 rounded bg-gray-700 text-gray-200">
                        {emp.status || "UNKNOWN"}
                      </div>
                    </button>
                  ))}
              </div>
            </div>
          </div>
        </section>

        <section className="bg-gray-800 rounded-xl p-6 shadow-lg">
          <div className="flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <i className="fa-solid fa-bell text-red-400 text-lg"></i>
              <div>
                <h2 className="text-xl font-semibold">Alerts & Notifications</h2>
                <p className="text-gray-400 text-sm">Quick health signals and manual checks.</p>
              </div>
            </div>
            {alerts.length > 0 && (
              <button
                className="text-sm text-gray-300 border border-gray-600 px-3 py-1 rounded hover:text-white"
                onClick={clearAlerts}
              >
                Clear alerts
              </button>
            )}
          </div>

          <div className="mt-4 space-y-3">
            {alerts.length === 0 && (
              <div className="bg-gray-700 p-4 rounded-lg text-gray-300">
                <strong>No active alerts.</strong>
                <p className="text-sm text-gray-400 mt-1">System operating normally.</p>
              </div>
            )}
            {alerts.map((a) => (
              <div
                key={a.id}
                className={`p-4 rounded-lg border ${
                  a.severity === "success"
                    ? "border-green-500/60 bg-green-900/20"
                    : a.severity === "warning"
                    ? "border-yellow-500/60 bg-yellow-900/20"
                    : "border-red-500/60 bg-red-900/20"
                }`}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <div className="font-semibold">{a.title}</div>
                    <div className="text-sm text-gray-200">{a.detail}</div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      </main>
    </div>
  );
}
