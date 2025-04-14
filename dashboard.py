import streamlit as st
from PIL import Image
import numpy as np
import time
from datetime import datetime
import plotly.express as px
import plotly.graph_objects as go
import matplotlib.pyplot as plt
import pandas as pd
from sklearn.metrics import roc_curve, roc_auc_score, confusion_matrix
# ──────────────── PAGE CONFIG ────────────────
st.set_page_config(
    page_title="Advanced Bone Fracture Detection Dashboard",
    layout="wide",
    initial_sidebar_state="expanded"
)


# ──────────────── CUSTOM CSS ────────────────
custom_css = """
<style>
#MainMenu, footer {visibility: hidden;}

/* Global fonts */
body, h1, h2, h3, h4, p, div, span, button, label, input, textarea {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    font-size: 14px !important;
    line-height: 1.4;
}

/* Light & dark containers */
.light-mode .stApp {
    background: #ffffff;
    color: #000000;
}
.dark-mode .stApp {
    background: #1e1e1e;
    color: #e0e0e0;
}
.card {
    background: #2c2f33;
    padding: 1.25rem;
    border-radius: 0.75rem;
    box-shadow: 0 2px 10px rgba(0,0,0,0.08);
    margin-bottom: 1rem;
}

/* Header style */
.header {
    background: linear-gradient(90deg, #4b6cb7, #182848);
    padding: 1.2rem 1rem 0.8rem;
    border-radius: 0.75rem;
    color: white;
    text-align: center;
    margin-bottom: 0.8rem !important;
}
.header h1 {
    margin: 0;
    font-size: 2rem !important;
    font-weight: 700;
}
.header p, .header em {
    margin: 0.2rem 0;
    font-style: italic;
    font-size: 1rem !important;
}

/* Sidebar block */
.sidebar-info {
    background: #3A3F58;
    padding: 0.75rem 1rem;
    border-radius: 0.6rem;
    font-size: 0.9rem;
    margin-top: 1rem;
    line-height: 1.6;
}
.dark-mode .sidebar-info {
    background: #292d33;
    color: #ddd;
}

/* Responsive */
@media (max-width: 768px) {
    .header h1 { font-size: 1.5rem !important; }
    .header p { font-size: 0.95rem !important; }
}
</style>
"""
st.markdown(custom_css, unsafe_allow_html=True)

# ──────────────── THEME TOGGLE ────────────────
theme = st.sidebar.selectbox(
    "Select Theme",
    ["Light", "Dark"],
    index=0,
    help="Choose Light for a bright interface or Dark for a modern look."
)
st.session_state.theme_mode = theme.lower()
st.markdown(f"<div class='{theme.lower()}-mode'>", unsafe_allow_html=True)

# ──────────────── DETECTION MODE ────────────────
mode = st.sidebar.radio(
    "Detection Mode",
    ["Basic", "Advanced"],
    index=1,
    help="Basic = Simple scan. Advanced = Deep analysis."
)
mode_icon = "🧪" if mode == "Basic" else "🧬"

# ──────────────── HEADER ────────────────
st.markdown("""
<div class="header">
  <h1>🦴 Bone Fracture Detection System</h1>
  <p>Advanced Dashboard for Diagnosis & Reporting</p>
  <div><em>Empowering doctors with AI-driven insights for faster decision making</em></div>
</div>
""", unsafe_allow_html=True)

# ──────────────── SESSION STATE INIT ────────────────
if "patient_data" not in st.session_state:
    st.session_state["patient_data"] = []
if "predictions" not in st.session_state:
    st.session_state["predictions"] = []

# ──────────────── SIDEBAR SUMMARY ────────────────
current_date = datetime.now().strftime("%Y-%m-%d")
st.sidebar.markdown("### 📋 Current Settings")
st.sidebar.markdown(f"""
<div class="sidebar-info">
<strong>🌗 Theme:</strong> {theme}<br>
<strong>{mode_icon} Mode:</strong> {mode}<br>
<strong>📅 Date:</strong> {current_date}
</div>
""", unsafe_allow_html=True)

# ──────────────── CLOSE THE THEME CONTAINER ────────────────
st.markdown("</div>", unsafe_allow_html=True)
# ──────────────── MAIN TABS ────────────────
tabs = st.tabs(["📁 Patient Info", "📸 Prediction", "📊 Analysis & Stats", "✉️ Email Results", "⚙️ Settings"])

# ──────────────── TAB 1: PATIENT INFO ────────────────
with tabs[0]:
    st.markdown('<div class="card">', unsafe_allow_html=True)
    st.subheader("Enter Patient Information")

    with st.form(key="patient_form"):
        col1, col2, col3 = st.columns(3)
        with col1:
            patient_name = st.text_input("Name", placeholder="John Doe")
        with col2:
            patient_id = st.text_input("Patient ID", placeholder="12345")
        with col3:
            date_of_visit = st.date_input("Date of Visit", value=datetime.now())

        col_email, col_upload = st.columns(2)
        with col_email:
            patient_email = st.text_input("Email", placeholder="example@domain.com")
        with col_upload:
            patient_files = st.file_uploader("Attach Files (Optional)", type=["png", "jpg", "jpeg", "pdf"], accept_multiple_files=True)

        st.write("Symptoms / Comments:")
        symptoms = st.text_area("Observations", placeholder="Describe the symptoms here...")

        col_submit, col_clear = st.columns(2)
        with col_submit:
            submit = st.form_submit_button("💾 Save Patient Info")
        with col_clear:
            clear = st.form_submit_button("🧹 Clear Fields")

        if submit:
            if not patient_name or not patient_id or not patient_email:
                st.error("Name, Patient ID, and Email are required.")
            else:
                entry = {
                    "name": patient_name,
                    "id": patient_id,
                    "date": str(date_of_visit),
                    "email": patient_email,
                    "symptoms": symptoms,
                    "files": [f.name for f in patient_files] if patient_files else []
                }
                st.session_state["patient_data"].append(entry)
                st.success("✅ Patient info saved successfully!")

        if clear:
            st.experimental_rerun()

    st.markdown('</div>', unsafe_allow_html=True)

    if st.session_state["patient_data"]:
        st.markdown('<div class="card">', unsafe_allow_html=True)
        st.subheader("🗂 Existing Patient Records")
        for idx, record in enumerate(st.session_state["patient_data"]):
            with st.expander(f"Record {idx+1}: {record['name']} ({record['id']})"):
                st.markdown(f"**Visit Date:** {record['date']}")
                st.markdown(f"**Email:** {record['email']}")
                st.markdown(f"**Symptoms:** {record['symptoms']}")
                if record['files']:
                    st.markdown("**Uploaded Files:**")
                    for f in record['files']:
                        st.markdown(f"- {f}")
        st.markdown('</div>', unsafe_allow_html=True)

# ──────────────── TAB 2: PREDICTION ────────────────
with tabs[1]:
    st.markdown('<div class="card">', unsafe_allow_html=True)
    st.subheader("Upload X‑ray Image for Prediction")
    st.write("Use the zoom slider to adjust the displayed image size. Interactive zoom & pan available via Plotly.")

    # Global controls
    global_zoom = st.slider("Global Zoom Factor", min_value=0.5, max_value=3.0, value=1.0, step=0.1)
    global_opacity = st.slider("Default Heatmap Opacity", 0.0, 1.0, 0.4, step=0.05)

    uploaded_files = st.file_uploader("Upload Image(s)", type=["png", "jpg", "jpeg"], accept_multiple_files=True)

    if uploaded_files:
        for idx, file in enumerate(uploaded_files):
            st.markdown('<div class="card">', unsafe_allow_html=True)
            original_img = Image.open(file).convert("RGB")
            width, height = original_img.size

            col_img, col_ctrls = st.columns([3, 1])

            with col_ctrls:
                zoom_factor = st.slider(f"Zoom (Img {idx+1})", 0.5, 3.0, global_zoom, step=0.1, key=f"zoom_{idx}")
                show_heatmap = st.checkbox("Show Heatmap", key=f"heatmap_{idx}")
                opacity = st.slider("Heatmap Opacity", 0.0, 1.0, global_opacity, key=f"opacity_{idx}") if show_heatmap else 0

            with col_img:
                new_size = (int(width * zoom_factor), int(height * zoom_factor))
                img = original_img.resize(new_size)

                if show_heatmap:
                    resized_for_heatmap = original_img.resize((224, 224))
                    heat_data = np.random.rand(224, 224)
                    fig_heat = go.Figure()
                    fig_heat.add_trace(go.Image(z=np.array(resized_for_heatmap)))
                    fig_heat.add_trace(go.Heatmap(z=heat_data, colorscale='jet', opacity=opacity, showscale=False))
                    fig_heat.update_layout(margin=dict(l=0, r=0, t=30, b=0))
                    st.plotly_chart(fig_heat, use_container_width=True)
                else:
                    fig = px.imshow(np.array(img))
                    fig.update_layout(margin=dict(l=0, r=0, t=30, b=0))
                    st.plotly_chart(fig, use_container_width=True)

            with st.spinner("Analyzing image..."):
                time.sleep(1.5)

            score = np.random.rand()
            label = "Fracture Detected" if score > 0.5 else "No Fracture"
            delta = f"{score*100:.1f}%" if score > 0.5 else f"{(1-score)*100:.1f}%"

            st.markdown("<hr>", unsafe_allow_html=True)
            col1, col2, col3 = st.columns(3)
            with col1:
                st.metric("Prediction", label, delta)
            with col2:
                st.progress(int(score * 100 if score > 0.5 else (1 - score) * 100))
            with col3:
                st.caption(f"Confidence Score: {score:.4f}")

            st.session_state["predictions"].append({
                "image_index": idx+1,
                "score": score,
                "label": label
            })
            st.markdown('</div>', unsafe_allow_html=True)


# ──────────────── TAB 3: ANALYSIS & STATS ────────────────
with tabs[2]:
    st.markdown('<div class="card">', unsafe_allow_html=True)
    st.subheader("📈 Model Performance Metrics")

    col1, col2, col3, col4 = st.columns(4)
    col1.metric("Accuracy", "92.5%")
    col2.metric("Precision", "90.2%")
    col3.metric("Recall", "88.7%")
    col4.metric("Inference Time", "~120 ms")
    st.markdown('</div>', unsafe_allow_html=True)

    if mode == "Advanced":
        # Simulated model outputs
        y_true = np.random.randint(0, 2, size=100)
        y_scores = np.random.rand(100)
        y_pred = (y_scores > 0.5).astype(int)

        st.markdown('<div class="card">', unsafe_allow_html=True)
        st.subheader("📊 Advanced Analysis")

        # Prediction Distribution
        st.markdown("#### Prediction Probability Distribution")
        fig_hist = px.histogram(y_scores, nbins=10, title="Distribution of Fracture Probability", labels={"value": "Fracture Probability"})
        st.plotly_chart(fig_hist, use_container_width=True)

        # ROC Curve
        st.markdown("#### ROC Curve & AUC")
        fpr, tpr, _ = roc_curve(y_true, y_scores)
        auc = roc_auc_score(y_true, y_scores)
        fig_roc = go.Figure()
        fig_roc.add_trace(go.Scatter(x=fpr, y=tpr, mode='lines', name='ROC Curve'))
        fig_roc.add_trace(go.Scatter(x=[0, 1], y=[0, 1], mode='lines', name='Random Classifier', line=dict(dash='dash')))
        fig_roc.update_layout(xaxis_title='False Positive Rate', yaxis_title='True Positive Rate', title=f'ROC Curve (AUC = {auc:.2f})')
        st.plotly_chart(fig_roc, use_container_width=True)

        # Confusion Matrix
        st.markdown("#### Confusion Matrix")
        cm = confusion_matrix(y_true, y_pred)
        fig_cm = px.imshow(cm, text_auto=True, color_continuous_scale='blues', 
                           x=["No Fracture", "Fracture"], y=["No Fracture", "Fracture"],
                           labels=dict(x="Predicted", y="Actual", color="Count"))
        st.plotly_chart(fig_cm, use_container_width=True)

        # Metrics Download
        st.markdown("#### Export Performance Metrics")
        if st.button("Download as CSV"):
            metrics_data = {
                "Metric": ["Accuracy", "Precision", "Recall", "AUC"],
                "Value": [0.925, 0.902, 0.887, auc]
            }
            df_metrics = pd.DataFrame(metrics_data)
            csv_data = df_metrics.to_csv(index=False).encode("utf-8")
            st.download_button("Click to Download", data=csv_data, file_name="model_metrics.csv", mime="text/csv")

        st.markdown('</div>', unsafe_allow_html=True)


# ──────────────── TAB 4: EMAIL RESULTS ────────────────
with tabs[3]:
    st.markdown('<div class="card">', unsafe_allow_html=True)
    st.subheader("Send Prediction Results by Email")

    if not st.session_state["patient_data"]:
        st.warning("Please add a patient record in the Patient Info tab first!")
    else:
        # Select the patient record
        selected_record = st.selectbox(
            "Select Patient Record", 
            st.session_state["patient_data"], 
            format_func=lambda x: f'{x["name"]} ({x["email"]})'
        )
        
        # Email customization fields
        st.markdown("### Customize Email")
        email_subject = st.text_input("Email Subject", value="Your Bone Fracture Detection Results")
        email_message = st.text_area("Email Message", value="Dear Patient,\n\nPlease find attached your bone fracture detection results.\n\nRegards,\nMedical Team")
        additional_attachment = st.file_uploader("Attach Additional File (Optional)", type=["pdf","png","jpg"], key="email_attachment")

        # Preview the email content
        st.markdown("#### Email Preview:")
        with st.expander("Show Preview", expanded=True):
            st.write(f"**To:** {selected_record['email']}")
            st.write(f"**Subject:** {email_subject}")
            st.write("**Message:**")
            st.text(email_message)
            if additional_attachment:
                st.write(f"**Attachment:** {additional_attachment.name}")
        
        # Send Email simulation
        if st.button("Send Results"):
            with st.spinner("Sending email..."):
                time.sleep(1.5)  # Simulate delay for sending email
            st.success(f"Results have been sent to {selected_record['email']}!")
    st.markdown('</div>', unsafe_allow_html=True)

# ──────────────── TAB 5: SETTINGS ────────────────
with tabs[4]:
    st.markdown('<div class="card">', unsafe_allow_html=True)
    st.subheader("Advanced Settings & Configurations")
    st.write("Configure logs, export reports, manage compliance alerts, customize your dashboard, and set security options.")
    
    st.markdown("### Logging & Alerts Settings")
    enable_logging = st.checkbox("Enable Detailed Logging")
    if enable_logging:
        log_level = st.selectbox("Select Logging Level", ["DEBUG", "INFO", "WARNING", "ERROR"], index=1)
        st.info(f"Detailed logging is enabled at the **{log_level}** level.")
    else:
        st.info("Detailed logging is disabled.")

    st.markdown("---")
    
    st.markdown("### Notification Settings")
    email_notifications = st.checkbox("Enable Email Notifications")
    if email_notifications:
        email_interval = st.slider("Notification Frequency (minutes)", min_value=5, max_value=60, value=15, step=5)
        st.info(f"Email notifications will be sent every **{email_interval}** minutes.")
    else:
        st.info("Email notifications are disabled.")
    
    st.markdown("---")
    
    st.markdown("### Dashboard Customization")
    custom_bg_color = st.color_picker("Select Custom Background Color", "#ffffff")
    custom_text_color = st.color_picker("Select Custom Text Color", "#000000")
    st.write("*Note: These colors will be applied after restarting the app or refreshing the page.*")
    
    st.markdown("---")
    
    st.markdown("### Data Export Settings")
    export_format = st.selectbox("Select Data Export Format", ["CSV", "JSON", "Excel"])
    if st.button("Download Logs"):
        # Here you would integrate your data exporting logic.
        st.success(f"Logs are being downloaded in **{export_format}** format (simulated).")
    
    st.markdown("---")
    
    st.markdown("### Security Settings")
    otp_required = st.checkbox("Enable OTP Verification for Sensitive Actions")
    if otp_required:
        st.info("OTP verification will be required for sending emails, exporting data, and clearing logs.")
    else:
        st.info("OTP verification is disabled. Proceed with caution when performing sensitive actions.")
    
    st.markdown('</div>', unsafe_allow_html=True)


# ──────────────── FOOTER ────────────────
st.markdown("""
<div style="text-align:center; color:gray; margin-top:2rem;">
  © 2025 Bone Fracture Detection Advanced Dashboard
</div>
""", unsafe_allow_html=True)

# End theme container
st.markdown("</div>", unsafe_allow_html=True)
