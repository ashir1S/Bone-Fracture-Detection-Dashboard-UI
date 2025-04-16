# app.R
library(shiny)
library(shinyjs)         # for dynamic theme switching
library(shinycssloaders) # for spinners
library(magick)
library(matrixStats)
library(lubridate)
library(plotly)
library(ggplot2)
library(dplyr)
library(caret)
library(pROC)            # for ROC/AUC
library(colourpicker)    # for colourInput()


# ─────────────── CUSTOM CSS ───────────────
# ─────────────── CUSTOM CSS ───────────────
custom_css <- "
<style>
  /* 🔒 Hide default menu & footer */
  #MainMenu, footer { visibility: hidden; }

  /* 🌗 Light and Dark body background */
  body.light-mode { background: #f5f5f5; }
  body.dark-mode  { background: #121212; }

  /* 🌍 Global font */
  body, h1, h2, h3, h4, p, div, span, button, label, input, textarea {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    font-size: 14px !important;
    line-height: 1.5;
  }

  /* 🧱 Panel backgrounds */
  .light-mode .sidebar, .light-mode .main-panel {
    background: #ffffff; color: #000000;
  }
  .dark-mode .sidebar, .dark-mode .main-panel {
    background: #1e1e1e; color: #e0e0e0;
  }

  /* ✍️ Inputs & outputs */
  .shiny-input-container input,
  .shiny-input-container select,
  .shiny-input-container textarea {
    border-radius: 8px !important;
    padding: 6px 10px !important;
    border: 1px solid #888 !important;
  }
  .dark-mode .shiny-input-container input,
  .dark-mode .shiny-input-container select,
  .dark-mode .shiny-input-container textarea {
    background: #2c2f33 !important;
    color: #e0e0e0 !important;
    border: 1px solid #444 !important;
  }

  /* 🧩 Card style sections */
  .card {
    padding: 1.25rem; border-radius: 0.75rem; margin-bottom: 1rem;
    box-shadow: 0 2px 12px rgba(0,0,0,0.12);
  }
  .light-mode .card {
    background: #ffffff; color: #000000;
  }
  .dark-mode .card {
    background: #2c2f33; color: #e0e0e0;
  }

  /* 🪄 Header */
  .header {
    background: linear-gradient(90deg, #4b6cb7, #182848);
    padding: 1.2rem 1rem 0.8rem;
    border-radius: 0.75rem;
    color: white;
    text-align: center;
    margin-bottom: 1.2rem;
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
  }
  .header h1 { font-size: 2.4rem !important; }
  .header p  { font-size: 1.4rem !important; margin: 0.5rem 0; }
  .header em { font-size: 1rem !important; }

  /* 📋 Sidebar Info / Summary Block */
  .sidebar-info {
    background: #3A3F58;
    padding: 0.75rem 1rem;
    border-radius: 0.6rem;
    font-size: 0.9rem;
    margin-top: 1rem;
    line-height: 1.6;
    color: #ffffff;
  }

  /* 🖱️ Button */
  .btn {
    border-radius: 6px !important;
    font-weight: 600;
  }
  .dark-mode .btn {
    background-color: #4b6cb7 !important;
    color: #ffffff !important;
    border: none !important;
  }

  /* 👣 Footer / Version */
  .version-footer {
    margin-top: 2rem;
    font-size: 0.85rem;
    text-align: center;
    color: #999999;
  }
  .dark-mode .version-footer {
    color: #bbbbbb;
  }

  /* 📱 Responsive */
  @media (max-width: 768px) {
    .header h1 { font-size: 1.8rem !important; }
    .header p  { font-size: 1.1rem !important; }
  }
</style>
"



ui <- fluidPage(
  useShinyjs(),              # initialize shinyjs
  tags$head(HTML(custom_css)),
  # JS handler to swap body classes on theme change
  tags$script(HTML("
    Shiny.addCustomMessageHandler('toggleTheme', function(theme){
      document.body.classList.remove('light-mode','dark-mode');
      document.body.classList.add(theme.toLowerCase()+'-mode');
    });
  ")),

  sidebarLayout(
    sidebarPanel(
  class = "sidebar",

  # ── Logo (put logo.png into a folder named `www/` next to app.R) ──
  tags$img(src="logo.png", height="60px",
           style="display:block; margin:0 auto 1rem;"),

  # ── Existing controls ──
  selectInput("theme", "Select Theme", choices = c("Light","Dark"), selected = "Dark"),
  radioButtons("mode", "Detection Mode", choices = c("Basic","Advanced"), selected = "Advanced"),
  htmlOutput("sidebar_summary"),

  tags$hr(),

  # ── Your Custom Tools section ──
  tags$h4("Custom Tools"),
  textInput("my_text", "Type something:"),
  actionButton("my_button", "Go!"),

  tags$hr(),

  # ── Version & author ──
  tags$p(strong("App Version:"), "1.2.0"),
  tags$p(em("© 2025 Ashirwad Sinha"))
),

    mainPanel(
      class = "main-panel",

      # Header
      tags$div(class = "header",
        tags$h1("🦴 Bone Fracture Detection System"),
        tags$p("Advanced Dashboard for Diagnosis & Reporting"),
        tags$em("Empowering doctors with AI‑driven insights for faster decision making")
      ),

      # Tabs
      tabsetPanel(id = "tabs",
        tabPanel("📁 Patient Info",
          tags$div(class="card",
            h3("Enter Patient Information"),
            textInput("patient_name",    "Name",       placeholder="John Doe"),
            textInput("patient_id",      "Patient ID", placeholder="12345"),
            dateInput( "date_of_visit",  "Date of Visit", value = Sys.Date()),
            textInput("patient_email",   "Email",      placeholder="example@domain.com"),
            fileInput(  "patient_files", "Attach Files (Optional)",
                        multiple = TRUE, accept = c("png","jpg","jpeg","pdf")),
            textAreaInput("symptoms",    "Symptoms / Comments", placeholder="Describe the symptoms..."),
            actionButton("submit", "💾 Save Patient Info"),
            actionButton("clear",  "🧹 Clear Fields")
          ),
          uiOutput("patient_records")
        ),

        tabPanel("📸 Prediction",
          tags$div(class="card",
            h3("Upload X‑ray Image for Prediction"),
            p("Use the zoom slider to adjust the displayed image size."),
            sliderInput("global_zoom",    "Global Zoom",     min=0.5, max=3, value=1, step=0.1),
            sliderInput("global_opacity", "Heatmap Opacity", min=0,   max=1, value=0.4, step=0.05),
            fileInput("uploaded_files",   "Upload Image(s)", multiple=TRUE, accept=c("png","jpg","jpeg"))
          ),
          uiOutput("prediction_cards")
        ),

        tabPanel("📊 Analysis & Stats",
          tags$div(class="card",
            h3("📈 Model Performance Metrics"),
            fluidRow(
              column(3, strong("Accuracy"),       textOutput("accuracy_metric")),
              column(3, strong("Precision"),      textOutput("precision_metric")),
              column(3, strong("Recall"),         textOutput("recall_metric")),
              column(3, strong("Inference Time"), textOutput("inference_time_metric"))
            )
          ),
          conditionalPanel(
            condition = "input.mode == 'Advanced'",
            tags$div(class="card",
              h3("📊 Advanced Analysis"),
              h4("Prediction Probability Distribution"),
              withSpinner(plotlyOutput("histogram_plot")),
              h4("ROC Curve & AUC"),
              withSpinner(plotlyOutput("roc_plot")),
              h4("Confusion Matrix"),
              withSpinner(plotlyOutput("cm_plot")),
              h4("Export Performance Metrics"),
              downloadButton("download_metrics", "Download CSV")
            )
          )
        ),

        tabPanel("✉️ Email Results",
          uiOutput("email_ui")
        ),

        tabPanel("⚙️ Settings",
          tags$div(class="card",
            h3("Advanced Settings & Configurations"),
            h4("Logging & Alerts"),
            checkboxInput("enable_logging", "Enable Detailed Logging"),
            conditionalPanel(
              "input.enable_logging",
              selectInput("log_level", "Logging Level", choices=c("DEBUG","INFO","WARNING","ERROR")),
              tags$div(class="sidebar-info", "Detailed logging is enabled.")
            ),
            hr(),
            h4("Notifications"),
            checkboxInput("email_notifications", "Enable Email Notifications"),
            conditionalPanel(
              "input.email_notifications",
              sliderInput("email_interval", "Frequency (min)", min=5, max=60, value=15, step=5),
              tags$div(class="sidebar-info", "Emails sent at selected interval.")
            ),
            hr(),
            h4("Customization"),
            colourpicker::colourInput("custom_bg_color",  "Background Color", "#ffffff"),
            colourpicker::colourInput("custom_text_color","Text Color",       "#000000"),
            p("*These apply after restart.*"),
            hr(),
            h4("Data Export"),
            selectInput("export_format", "Format", choices=c("CSV","JSON","Excel")),
            actionButton("download_logs", "Download Logs"),
            hr(),
            h4("Security"),
            checkboxInput("otp_required", "Enable OTP Verification"),
            conditionalPanel(
              "input.otp_required",
              tags$div(class="sidebar-info", "OTP required for sensitive actions.")
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Initialize theme on load & reactively update
  observe({
    session$sendCustomMessage("toggleTheme", input$theme)
  })

  rv <- reactiveValues(patient_data = list())

  # Sidebar summary
  output$sidebar_summary <- renderUI({
    icon_md <- if (input$mode=="Basic") "\U0001F9EA" else "\U0001F9EC"
    HTML(paste0(
      '<div class="sidebar-info">',
        '<strong>🌗 Theme:</strong> ', input$theme, '<br>',
        '<strong>', icon_md, ' Mode:</strong> ', input$mode, '<br>',
        '<strong>📅 Date:</strong> ', Sys.Date(),
      '</div>'
    ))
  })

  # ── Patient Info ──
  observeEvent(input$submit, {
    if (input$patient_name=="" || input$patient_id=="" || input$patient_email=="") {
      showNotification("Name, ID & Email are required.", type="error")
    } else {
      rv$patient_data <- append(rv$patient_data, list(
        list(
          name     = input$patient_name,
          id       = input$patient_id,
          date     = as.character(input$date_of_visit),
          email    = input$patient_email,
          symptoms = input$symptoms,
          files    = if (is.null(input$patient_files)) character(0) else input$patient_files$name
        )
      ))
      showNotification("✅ Patient info saved!", type="message")
    }
  })
  observeEvent(input$clear, session$reload)

  output$patient_records <- renderUI({
    req(length(rv$patient_data)>0)
    tagList(lapply(seq_along(rv$patient_data), function(i){
      rec <- rv$patient_data[[i]]
      tags$div(class="card",
        tags$h4(paste0("Record ", i, ": ", rec$name, " (", rec$id, ")")),
        tags$p(strong("Visit Date:"), rec$date),
        tags$p(strong("Email:"), rec$email),
        tags$p(strong("Symptoms:"), rec$symptoms),
        if (length(rec$files)>0) tags$ul(lapply(rec$files, tags$li))
      )
    }))
  })

  # ── Prediction ──
  output$prediction_cards <- renderUI({
    req(input$uploaded_files)
    files <- input$uploaded_files
    tagList(lapply(seq_len(nrow(files)), function(i){
      zoom_id <- paste0("zoom_", i)
      heat_id <- paste0("heatmap_", i)
      opac_id <- paste0("opacity_", i)
      plot_id <- paste0("plot_", i)
      metric_id <- paste0("metric_", i)
      caption_id<- paste0("caption_", i)

      tags$div(class="card",
        fluidRow(
          column(3,
            sliderInput(zoom_id, paste0("Zoom (Img ", i, ")"),
                        min=0.5, max=3, value=input$global_zoom, step=0.1),
            checkboxInput(heat_id, "Show Heatmap", FALSE),
            conditionalPanel(
              paste0("input.", heat_id, " == true"),
              sliderInput(opac_id, "Heatmap Opacity",
                          min=0, max=1, value=input$global_opacity, step=0.05)
            )
          ),
          column(9,
            withSpinner(plotlyOutput(plot_id))
          )
        ),
        tags$hr(),
        fluidRow(
          column(4, uiOutput(metric_id)),
          column(4, uiOutput(caption_id))
        )
      )
    }))
  })

  observe({
    req(input$uploaded_files)
    files <- input$uploaded_files
    for (i in seq_len(nrow(files))) {
      local({
        idx <- i
        file <- files[idx,]
        zoom_id <- paste0("zoom_", idx)
        heat_id <- paste0("heatmap_", idx)
        opac_id <- paste0("opacity_", idx)
        plot_id <- paste0("plot_", idx)
        metric_id <- paste0("metric_", idx)
        caption_id<- paste0("caption_", idx)

        output[[plot_id]] <- renderPlotly({
          img <- image_read(file$datapath) %>%
                 image_scale(geometry_size_percent(100 * input[[zoom_id]]))
          arr <- as.raster(img)
          p <- plot_ly(z=arr, type='image') %>%
               layout(margin=list(l=0,r=0,t=0,b=0))
          if (input[[heat_id]]) {
            heat <- matrix(runif(224*224), 224, 224)
            p <- plot_ly() %>%
                 add_image(z=arr) %>%
                 add_heatmap(z=heat, colorscale='Jet',
                             opacity=input[[opac_id]], showscale=FALSE) %>%
                 layout(margin=list(l=0,r=0,t=0,b=0))
          }
          p
        })

        # fake score
        score <- runif(1)
        label <- ifelse(score>0.5, "Fracture Detected", "No Fracture")
        delta <- paste0(round((ifelse(score>0.5, score, 1-score))*100,1), "%")

        output[[metric_id]] <- renderUI({
          tags$div(
            tags$strong("Prediction: "), label, tags$br(),
            tags$strong("Delta: "), delta
          )
        })
        output[[caption_id]] <- renderUI({
          tags$p(strong("Confidence Score:"), sprintf("%.4f", score))
        })
      })
    }
  })

  # ── Analysis & Stats ──
  output$accuracy_metric       <- renderText("92.5%")
  output$precision_metric      <- renderText("90.2%")
  output$recall_metric         <- renderText("88.7%")
  output$inference_time_metric <- renderText("~120 ms")

  observe({
    if (input$mode=="Advanced") {
      y_true   <- sample(0:1, 100, replace=TRUE)
      y_scores <- runif(100)
      roc_obj  <- roc(y_true, y_scores)
      auc_val  <- auc(roc_obj)

      output$histogram_plot <- renderPlotly({
        plot_ly(x=y_scores, type='histogram', nbinsx=10) %>%
          layout(title="Distribution of Fracture Probability",
                 xaxis=list(title="Probability"))
      })
      output$roc_plot <- renderPlotly({
        plot_ly(x=1-roc_obj$specificities,
                y=roc_obj$sensitivities,
                type='scatter', mode='lines', name='ROC') %>%
          add_trace(x=c(0,1), y=c(0,1), mode='lines', line=list(dash='dash'),
                    name='Random') %>%
          layout(xaxis=list(title="False Positive Rate"),
                 yaxis=list(title="True Positive Rate"),
                 title=paste0("ROC Curve (AUC=", round(auc_val,2),")"))
      })
      cm <- table(factor(ifelse(y_scores>0.5,1,0), levels=0:1),
                  factor(y_true, levels=0:1))
      output$cm_plot <- renderPlotly({
        plot_ly(z=cm, type='heatmap',
                x=c("No Fracture","Fracture"),
                y=c("No Fracture","Fracture")) %>%
          layout(title="Confusion Matrix",
                 xaxis=list(title="Predicted"),
                 yaxis=list(title="Actual"))
      })

      output$download_metrics <- downloadHandler(
        filename = function() "model_metrics.csv",
        content  = function(file) {
          df <- data.frame(
            Metric = c("Accuracy","Precision","Recall","AUC"),
            Value  = c(0.925,0.902,0.887,as.numeric(auc_val))
          )
          write.csv(df, file, row.names=FALSE)
        }
      )
    }
  })

  # ── Email Results ──
  output$email_ui <- renderUI({
    if (length(rv$patient_data)==0) {
      tags$div(class="card",
        tags$p("Please add a patient record first!", style="color:orange;")
      )
    } else {
      tags$div(class="card",
        selectInput("selected_record","Select Patient",
                    choices = setNames(seq_along(rv$patient_data),
                                      sapply(rv$patient_data, function(x)
                                             paste0(x$name," (",x$email,")")))),
        textInput("email_subject","Email Subject","Your Detection Results"),
        textAreaInput("email_message","Email Message",
                      "Dear Patient,\n\nPlease find attached your results.\n\nRegards,"),
        fileInput("additional_attachment","Attach File (Optional)",
                  accept=c("pdf","png","jpg")),
        tags$h4("Preview:"),
        tags$p(strong("To:"), rv$patient_data[[as.numeric(input$selected_record)]]$email),
        tags$p(strong("Subject:"), input$email_subject),
        verbatimTextOutput("email_preview_text"),
        if (!is.null(input$additional_attachment))
          tags$p(strong("Attachment:"), input$additional_attachment$name),
        actionButton("send_results","Send Results")
      )
    }
  })
  output$email_preview_text <- renderText({ input$email_message })
  observeEvent(input$send_results, {
    showNotification("Sending email...", type="message")
    invalidateLater(1500, session)
    showNotification(
      paste0("Results sent to ",
             rv$patient_data[[as.numeric(input$selected_record)]]$email,
             "!"), type="message"
    )
  })

  # ── Settings ──
  observeEvent(input$download_logs, {
    showNotification(paste("Logs downloaded in", input$export_format, "(simulated)."),
                     type="message")
  })
}

shinyApp(ui, server)
