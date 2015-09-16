rm(list=ls())
require(shiny)
require(RMySQL);require(ggplot2);require(DT)

source("dbcon.R")

thetable <- dbGetQuery(conn = db, statement= "SELECT customer.FirstName, customer.LastName, customer.email, customer.`Cust#` FROM customer ORDER BY customer.LastName ASC;")
custNames <- thetable[,4]
names(custNames) <- paste(thetable$FirstName, thetable$LastName, thetable$Cust, sep=" ")

shinyServer(function(input, output, session) {

  updateSelectizeInput(session, 'custID', choices=custNames, server=TRUE)
  ##  Make link and execute php on submit
  
  cust <- reactiveValues(num=45)
  v <- reactiveValues(theLink="")
  
  observe({if(input$custID > 0) {
   custnum <- input$custID
    
    waterSQL <- paste0("SELECT `Date`, `LSI`, `Workorder`, `FreeChlor`, `TotalChlor`, `PH`, `Alkalinity`, `CalciumHardness`, `ChlorineStab`, `DissolvedSolids`, `Salt` FROM `water analysis` WHERE `Cust#`=",custnum," ORDER BY `Date` DESC;")
    theWaterres <- dbSendQuery(db, waterSQL)
    theWater <- fetch(theWaterres, n=-1)
    dbClearResult(theWaterres)
   
   
    theChemsSQL <- paste0("SELECT workorders.`ScheduleDate`, sercode.`Desc`, woparts.`Quantity` FROM customer INNER JOIN ((woparts INNER JOIN sercode ON woparts.`ServiceCode` = sercode.`ServiceCode`) INNER JOIN workorders ON woparts.`WO#` = workorders.`WO#`) ON customer.`Cust#` = workorders.`Cust#` WHERE (((workorders.`ScheduleDate`)<CURDATE()) AND ((customer.`Cust#`)=",custnum, ") AND ((sercode.`MateClass`='CHEMICALS'))) ORDER BY workorders.`ScheduleDate` DESC")
    theChemsres <- dbSendQuery(db, theChemsSQL)
    theChems <- fetch(theChemsres, n=-1)
    dbClearResult(theChemsres)
   
   
    output$phpScript <- renderPrint(waterSQL)
 #   output$summary <- DT::renderDataTable(DT::datatable(theWater))
    output$chems <- renderTable(theChems)
    
    ## output$clplot <- renderPlot(ggplot(theWater, aes(as.Date(Date))) + geom_line(aes(y=FreeChlor), col="red") + geom_line(aes(y=TotalChlor), col="blue"))
  }
  })
  
  ## When user clicks submit, go run the php script
  observeEvent(input$Doit, {
    ## you should add input validation here before passing to php script
    ## make sure what your passing are ints
    v$theLink <- paste0("http://192.168.1.201/Private/Julie/spintodb.php?custno=", input$custID, "&EnteredBy=Julie&Salt=", input$Salt, "&DS=", input$DS, "&Temp=", input$Temp)
    shell.exec(v$theLink)
    ## wait for it to finish
    Sys.sleep(3)
    newWaterSQL <- paste0("SELECT `Date`, `LSI`, `Workorder`, `FreeChlor`, `TotalChlor`, `PH`, `Alkalinity`, `CalciumHardness`, `ChlorineStab`, `DissolvedSolids`, `Salt` FROM `water analysis` WHERE `Cust#`=",input$custID," ORDER BY `Date` DESC;")
    newWaterres <- dbSendQuery(db, newWaterSQL)
    newWater <- fetch(newWaterres, n=1)
    
    dbClearResult(newWaterres)
    for (i in 1:ncol(newWater)) {
      newWater[,i] <- as.character(newWater[,i])
    }
    newWater[2,] <- c("","-.5 - .5", "","1 - 3 PPM","1 - 3 PPM","7.2 - 7.6","100 - 150","","","","")
    row.names(newWater)<- c("Results","Ideal")
    outTable <- t(newWater)
    output$CustNum <- renderPrint({
      str(outTable)
      #input$custID
    })
    output$results <- renderTable(outTable)
    
  })
 
  
  session$onSessionEnded(function() {
    all_cons <- dbListConnections(MySQL())
    for(con in all_cons) dbDisconnect(con)
  })
 
})
  
  #format(as.Date(theWater$Date), "%B %d %Y")
#all_cons <- dbListConnections(MySQL())
#for(con in all_cons) dbDisconnect(con)
