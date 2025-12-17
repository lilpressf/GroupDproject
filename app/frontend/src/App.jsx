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

export default function App() {
  const [status, setStatus] = useState(null);
  const [loading, setLoading] = useState(false);
  const [employees, setEmployees] = useState([]);
  const [selectedId, setSelectedId] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [submitting, setSubmitting] = useState(false);

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
      setStatus({ ok: false, msg: "Kon lijst niet laden." });
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    setApiAuthEmail(defaultAuthUser.email);
    fetchEmployees();
  }, [fetchEmployees]);

  const isFormValid = () =>
    form.name.trim().length > 0 &&
    form.email.trim().length > 0 &&
    form.department.trim().length > 0;

  const handleOnboard = async (e) => {
    if (e) e.preventDefault();
    if (!isFormValid()) {
      setStatus({ ok: false, msg: "Vul naam, e-mail en afdeling in." });
      return;
    }
    setStatus(null);
    setSubmitting(true);

    try {
      if (selectedId) {
        await updateEmployee(selectedId, form);
        setStatus({ ok: true, msg: "Medewerker bijgewerkt." });
      } else {
        await createEmployee(form);
        setStatus({
          ok: true,
          msg: "Medewerker aangemaakt. EC2 + IAM rol worden nu uitgerold.",
        });
      }
      setForm(emptyForm);
      setSelectedId(null);
      await fetchEmployees();
    } catch (err) {
      setStatus({
        ok: false,
        msg: selectedId ? "Bijwerken mislukt." : "Er ging iets mis bij het aanmaken.",
      });
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
          msg: "Verwijderen gestart; resources worden opgeruimd. Dit kan een paar minuten duren.",
        });
      } else {
        setStatus({ ok: true, msg: "Medewerker verwijderd." });
      }
      setForm(emptyForm);
      setSelectedId(null);
      await fetchEmployees();
    } catch (err) {
      setStatus({ ok: false, msg: "Verwijderen mislukt." });
    } finally {
      setSubmitting(false);
    }
  };

  const onNewClick = () => {
    setSelectedId(null);
    setForm(emptyForm);
    setStatus(null);
  };

  return (
    <div className="min-h-screen bg-gray-900 text-gray-100">
      <nav className="bg-gray-800 border-b border-gray-700 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold">Training Platform Admin Dashboard</h1>
            <p className="text-gray-400 text-sm mt-1">
              Onboard / Offboard Students  Deploy Vulnerable Machines  System Overview
            </p>
          </div>
          <div className="text-sm text-gray-300">{defaultAuthUser.name}</div>
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
                <label className="block text-sm text-gray-300 mb-1">Naam</label>
                <input
                  type="text"
                  className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
                  placeholder="Bijv. Alex Janssen"
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  required
                />
              </div>

              <div>
                <label className="block text-sm text-gray-300 mb-1">E-mail</label>
                <input
                  type="email"
                  className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
                  placeholder="gebruiker@bedrijf.nl"
                  value={form.email}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  required
                />
              </div>

              <div>
                <label className="block text-sm text-gray-300 mb-1">Afdeling</label>
                <input
                  type="text"
                  className="w-full rounded bg-gray-900 border border-gray-700 px-3 py-2 text-gray-100"
                  placeholder="Bijv. Security, Dev, Ops"
                  value={form.department}
                  onChange={(e) => setForm({ ...form, department: e.target.value })}
                  required
                />
              </div>

              <div className="flex gap-3 text-sm text-gray-400">
                <span>Tip: vul de gegevens in en gebruik hierboven Onboard/Offboard.</span>
                <button
                  type="button"
                  className="text-blue-400 hover:text-blue-300 underline"
                  onClick={onNewClick}
                >
                  Velden leegmaken
                </button>
              </div>
            </form>

            <div>
              <div className="flex items-center gap-2 mb-3">
                <i className="fa-solid fa-list text-yellow-400"></i>
                <h3 className="text-lg font-semibold">Huidige medewerkers</h3>
              </div>

              <div className="space-y-2">
                {loading && <div className="text-gray-400">Laden...</div>}
                {!loading && employees.length === 0 && (
                  <div className="text-gray-400">Nog geen medewerkers.</div>
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
                            <span className="text-gray-400 ml-2">Opkuisen...</span>
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
          <div className="flex items-center gap-3">
            <i className="fa-solid fa-bell text-red-400 text-lg"></i>
            <div>
              <h2 className="text-xl font-semibold">Alerts & Notifications</h2>
              <p className="text-gray-400 text-sm">System operating status.</p>
            </div>
          </div>

          <div className="mt-4 bg-gray-700 p-4 rounded-lg text-gray-300">
            <strong>No active alerts.</strong>
            <p className="text-sm text-gray-400 mt-1">
              System operating normally.
            </p>
          </div>
        </section>
      </main>
    </div>
  );
}
