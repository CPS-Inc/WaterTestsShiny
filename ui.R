require(shiny);require(shinydashboard)
require(RMySQL);require(sendmailR);require(shinythemes);require(DT)



# Define UI for application that draws a histogram
header <- dashboardHeader(title= "Water Tests!")
sidebar <- dashboardSidebar(
      selectizeInput("custID", "Customer", choices=NULL, options = list(create= TRUE, maxOptions=5, placeholder="Enter Name")),
      numericInput("Salt", "Salt:",0),
      numericInput("DS","Dissolved Solids:",0),
      numericInput("Temp","Temperature:", 80),
      actionButton("Doit", "Submit"),
      br(),
      tableOutput("chems")
    )
    
body <- dashboardBody(
  
       fluidRow(
       absolutePanel(
         top=100, left=300, width=800, height=400, draggable=TRUE,
          box(
            title="Your Test Results",
            solidHeader= TRUE,
            collapsible = TRUE,
            status = "primary",
           tableOutput("results")
           )
         ), 
         absolutePanel(
           top=20, left=500, width=400, height=400, draggable=TRUE,
         box(verbatimTextOutput("CustNum")))) #,
       
   # fluidRow(
  #       column(5,
  #          DT::dataTableOutput('summary')
  #       )
  #     )
)

dashboardPage(header, sidebar, body)