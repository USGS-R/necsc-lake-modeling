library(shiny)
library(leaflet)
library(lakeattributes)
library(mda.lakes)
library(listviewer)
sites <- lakeattributes::location
use.i <- sites$site_id %in% zmax$site_id
sites <- sites[use.i, ]
longitude <- sites$lon
latitude <- sites$lat
radius <- 4
ids <-sites$site_id
pkg.env <- new.env()
shinyApp(
  
  ui = fluidPage(
    fluidRow(
      leafletMap(
        "map", "100%", 400,
        initialTileLayer = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
        initialTileLayerAttribution = HTML('Maps by <a href="http://www.mapbox.com/">Mapbox</a>'),
        options=list(
          center = c(45.45, -89.85),
          zoom = 6,
          maxBounds = list(list(17, -180), list(59, 180))))),
    
    fluidRow(verbatimTextOutput("nml")),
    uiOutput("run.box"),
    fluidRow(
         column(width = 7,
                plotOutput("plot", height=300))),
    uiOutput("download")
  ),

  server = function(input, output, session){
    map = createLeafletMap(session, 'map')
    session$onFlushed(once=T, function(){
      
      map$addCircleMarker(lat = latitude, lng = longitude, radius = radius, 
                          layerId=ids)
    })        
    
    observe({
      click <- input$map_click
      if(is.null(click)){
        return()
      }
      output$download <- renderUI(NULL)
      output$plot <- renderUI(NULL)
      output$run.model <- renderUI(NULL)
      output$run.box <- renderUI(NULL)
      output$Click_text<-renderText(NULL)
    })
    observe({
      click <- input$map_marker_click
      if(is.null(click))
        return()
      text<-sprintf("ID: %s</br>Lattitude: %1.1f </br>Longtitude: %1.1f </br>Max depth: %sm </br>Surface area: %1.3fkm^2", click$id, click$lat, click$lng, get_zmax(click$id),get_area(click$id)*1e-6)
      map$clearPopups()
      map$showPopup(click$lat, click$lng, text)
      output$run.box = renderUI(
        if (is.null(click)){
          return()
        } else {
          actionButton("run.model", "Run model", icon = icon("line-chart", lib = "font-awesome"))
        }
      )
      
      output$nml <- renderText(run.text())
      run.text <- eventReactive(input$run.model,{
        output$download <- renderUI(NULL)
        output$plot <- renderUI(NULL)
        output$run.model <- renderUI(NULL)
        withProgress(message = 'Running the model', value = 0, {
          incProgress(0, detail = paste("Doing part"))
          cl.out = click$id
          if (!is.null(pkg.env$id) && pkg.env$id != cl.out){
            incProgress(1, detail = paste("Done"))
            pkg.env$id <- NULL
          } else {
            pkg.env$id <- cl.out
            incProgress(0.03, detail = paste("Building model"))
            Sys.sleep(1)
            incProgress(0.1, detail = paste("Downloading drivers"))
            driver.path = get_driver_path(click$id, driver_name="CM2.0")
            incProgress(0.5, detail = paste("Populate metadata"))
            nml = populate_base_lake_nml(click$id, kd=0.3, driver = driver.path)
            incProgress(0.6, detail = paste("Write model files"))
            nml = glmtools::set_nml(nml, arg_list=list('start'='2040-04-01 00:00:00', 'stop'='2045-12-01 00:00:00'))
            glmtools::write_nml(nml, file=file.path(tempdir(),'glm2.nml'))
            incProgress(0.7, detail = paste("Run model"))
            GLMr::run_glm(tempdir())
            incProgress(0.9, detail = paste("Plotting"))
            output$plot <- renderPlot(glmtools::plot_temp(file=file.path(tempdir(), 'output.nc')))
            incProgress(1, detail = paste("Done"))
            output$download = renderUI({
              actionButton("download.results", "Download", icon = icon("download", lib = "font-awesome"))
            })
          }
          return(NULL) # or NULL
        })
      })
      
          
      
    })
    # output$download = renderUI({
    #   actionButton("download.results", "Download!", icon = icon("line-chart", lib = "font-awesome"))
    # })
    
    observeEvent(input$download.results, {
      session$sendCustomMessage(type = 'testmessage',
                                message = 'Thank you for clicking')
    })   
  }
)