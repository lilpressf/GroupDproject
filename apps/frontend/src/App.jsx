import React, { useEffect, useMemo, useState } from "react";

const btnStyle = (bg) => ({
  background: bg,
  color: "white",
  border: "none",
  borderRadius: 10,
  padding: "16px 20px",
  fontSize: 18,
  fontWeight: 700,
  cursor: "pointer",
  minWidth: 220
});

export default function App() {
  const apiBase = useMemo(() => (window.__API_BASE__ || import.meta.env.VITE_API_BASE || "/api"), []);
  const [deployments, setDeployments] = useState([]);
  const [msg, setMsg] = useState("");

  async function refresh() {
    const r = await fetch(`${apiBase}/deployments`);
    setDeployments(await r.json());
  }

  useEffect(() => { refresh().catch(()=>{}); }, []);

  async function deploy(difficulty) {
    setMsg("");
    try {
      const r = await fetch(`${apiBase}/deploy`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ difficulty })
      });
      const j = await r.json();
      if (!r.ok) throw new Error(j?.error || "deploy_failed");
      setMsg("Deployment gestart. Onboarding pod wordt aangemaakt...");
      await refresh();
      setTimeout(() => refresh().catch(()=>{}), 3000);
    } catch (e) {
      setMsg("Starten mislukt. Controleer backend.");
    }
  }

  return (
    <div style={{
      minHeight: "100vh",
      background: "#0b1220",
      color: "#e5e7eb",
      fontFamily: "system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, Cantarell, Noto Sans, sans-serif",
      padding: 32
    }}>
      <h1 style={{ fontSize: 44, margin: 0, letterSpacing: -0.5 }}>Training Platform Admin Dashboard</h1>
      <div style={{ marginTop: 6, opacity: 0.8 }}>
        Onboard / Offboard Students • Deploy Vulnerable Machines • System Overview
      </div>

      <div style={{
        marginTop: 28,
        background: "#111b2e",
        border: "1px solid #24314d",
        borderRadius: 18,
        padding: 24,
        maxWidth: 980
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div style={{ fontSize: 24, fontWeight: 800 }}>🧪 Vulnerable Machine Deployment</div>
        </div>
        <div style={{ marginTop: 6, opacity: 0.8 }}>
          Deploy environments ranked from Easy → Hard.
        </div>

        <div style={{ display: "flex", gap: 14, marginTop: 18, flexWrap: "wrap" }}>
          <button style={btnStyle("#16a34a")} onClick={() => deploy("easy")}>🐞 Deploy Easy VM</button>
          <button style={btnStyle("#d97706")} onClick={() => deploy("medium")}>💀 Deploy Medium VM</button>
          <button style={btnStyle("#7c3aed")} onClick={() => deploy("hard")}>⚙️ Deploy Hard VM</button>
        </div>

        <div style={{
          marginTop: 18,
          background: "#0b1220",
          border: "1px solid #24314d",
          borderRadius: 14,
          padding: 14
        }}>
          <b>Deployment Status:</b> {deployments.length ? "Recent requests below." : "No active environments."}
        </div>

        {msg && (
          <div style={{
            marginTop: 18,
            background: "#3b0a1d",
            border: "1px solid #fb7185",
            borderRadius: 14,
            padding: 14,
            color: "#fecdd3"
          }}>
            {msg}
          </div>
        )}
      </div>

      <div style={{ marginTop: 22, maxWidth: 980 }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h2 style={{ margin: 0 }}>Latest deployments</h2>
          <button onClick={() => refresh()} style={{ ...btnStyle("#334155"), padding: "10px 14px", minWidth: 120, fontSize: 14 }}>
            Refresh
          </button>
        </div>

        <div style={{ overflowX: "auto", marginTop: 10 }}>
          <table style={{ width: "100%", borderCollapse: "collapse", background: "#0f172a", borderRadius: 12, overflow: "hidden" }}>
            <thead>
              <tr style={{ textAlign: "left", background: "#111b2e" }}>
                <th style={{ padding: 12, borderBottom: "1px solid #24314d" }}>Time</th>
                <th style={{ padding: 12, borderBottom: "1px solid #24314d" }}>Difficulty</th>
                <th style={{ padding: 12, borderBottom: "1px solid #24314d" }}>Status</th>
                <th style={{ padding: 12, borderBottom: "1px solid #24314d" }}>Instance</th>
                <th style={{ padding: 12, borderBottom: "1px solid #24314d" }}>ID</th>
              </tr>
            </thead>
            <tbody>
              {deployments.map((d) => (
                <tr key={d.id}>
                  <td style={{ padding: 12, borderBottom: "1px solid #1f2a44", whiteSpace: "nowrap" }}>{new Date(d.requested_at).toLocaleString()}</td>
                  <td style={{ padding: 12, borderBottom: "1px solid #1f2a44" }}>{d.difficulty}</td>
                  <td style={{ padding: 12, borderBottom: "1px solid #1f2a44" }}>{d.status}</td>
                  <td style={{ padding: 12, borderBottom: "1px solid #1f2a44", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace" }}>{d.instance_id || "-"}</td>
                  <td style={{ padding: 12, borderBottom: "1px solid #1f2a44", fontFamily: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace" }}>{d.id}</td>
                </tr>
              ))}
              {!deployments.length && (
                <tr><td colSpan="5" style={{ padding: 12, opacity: 0.8 }}>No deployments yet.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div style={{ marginTop: 26, opacity: 0.7 }}>
        Tip: check onboarding pods with <code>kubectl get pods -n training</code>
      </div>
    </div>
  );
}
