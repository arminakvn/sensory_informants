# author: armin.akhavan@gmail.com
do ->
  
  rscale =  d3.scale.linear().domain([0, 30]).range([0, 15])
  rscaleex =  d3.scale.sqrt().domain([0, 30]).range([0, 7])
  oscale =  d3.scale.linear().domain([0, 25]).range([ 0.8,0.2])
  @map = new (google.maps.Map)(d3.select('#map').node(),
    center: new (google.maps.LatLng)(42.364981,-71.053695)
    zoom: 17
    mapTypeId: google.maps.MapTypeId.SATELLITE
    mapTypeControl: false
    minZoom: 1
    scaleControl: true
    streetViewControl: true
    rotateControl: true 
    rotateControlOptions:
      position: google.maps.ControlPosition.TOP_RIGHT
    overviewMapControl: true
    heading: 90)
  WIDTH = 640
  HEIGHT = 360
  SMOOTHING = 0.8
  FFT_SIZE = 2048
  endSound = (event) =>
    updateMap event
  listener = (event) =>
    loadSound(event.feature.getProperty('file'))

  @dispatch = d3.dispatch("start", "end")
  @dispatch.on("start", listener)
  @dispatch.on("end", endSound)
  state_of_click = d3.map()
  state_of_map = d3.map()
  # lookup_map = d3.map()
  station_map = d3.map()
  current_station_map = d3.map()
  sound_station_current = d3.map()
  category_station_current = d3.map()
  reverse_time = d3.map()
  color_map = d3.map()
  category_station_current.set('category', 'M')
  category_station_current.set('A', 'false')
  category_station_current.set('H', 'true')
  category_station_current.set('C', 'true')
  category_station_current.set('T', 'true')
  category_station_current.set('B', 'true')
  category_station_current.set('W', 'true')
  category_station_current.set('M', 'true')
  sound_category_times = d3.map()
  color_map.set('C', "#A03F97")
  color_map.set('T', "#1B9E83")
  color_map.set('H', "#9BBF3A")
  color_map.set('B', "#E9B221")
  color_map.set('W', "#90D5E1")
  color_map.set('M', "#EE3125")
  color_map.set('A', "#ef532f")


  simple_data_map = d3.map()
  simple_data_map.set(1, 'T')
  simple_data_map.set(2, 'C')
  lkps = []
  for st in [0..22]
    mp = d3.map()
    lkps[st] = mp
  $.ajax
    dataType: 'json'
    url: '/lookup'
    success: (lookup_table) =>
      for each_row in lookup_table
        lookup_map = lkps[each_row.location_number]
        lookup_map.set(each_row.time_in_seconds, each_row.category)
  
  current_station_map.set("current_station", 1)
  $.ajax
    dataType: 'json'
    url: "/brokenDown/#{current_station_map.get("current_station")}"
    success: (kup_table) =>
      station_map = d3.map()
      for each_row in kup_table
        station_map.set(each_row.seconds, each_row.category)
  drawMap = =>
    `d3.json("/data", function(error, data) {
        if (error) throw error;

        _this.overlay = new google.maps.OverlayView();




        overlay.onAdd = function() {
          _this.layer = d3.select(this.getPanes().overlayLayer).append("div")
              .attr("class", "stations");




          _this.overlay.draw = function() {
            projection = this.getProjection(),
                padding = 20;

            _this.marker = _this.layer.selectAll("svg")
                .data(d3.entries(data.features))
                .each(transform) // update existing markers
              .enter().append("svg")
                .each(transform)
                .attr("class", "marker");

            // Add category t circles.

            _this.marker.append("circle")
                .attr("r", 0)
                .attr("class","cat_t")
                .attr("cx", padding)
                .attr("cy", padding).attr("id", function(d){
                    return d.value.properties.file + "red";
                })
                .style("fill", "red").style("stroke", "none").style("fill-opacity", 0.3)  ;

              _this.marker.append("circle")
                .attr("r", 0)
                .attr("class","H")
                .attr("cx", padding)
                .attr("cy", padding).attr("id", function(d){
                    return d.value.properties.file;
                })
                .style("fill", color_map.get("H")).style("stroke", "none").style("fill-opacity", 0.3)  ;

            // Add a label.
            _this.marker.on("mouseover", function(d){
              })
            function transform(d) {
              d = new google.maps.LatLng(d.value.geometry.coordinates[1], d.value.geometry.coordinates[0]);
              d = projection.fromLatLngToDivPixel(d);
              return d3.select(this)
                  .style("left", (d.x - padding) + "px")
                  .style("top", (d.y - padding) + "px");
            }
          };

          _this.overlay.update = function (aver) {
            

            d3.select(this.getPanes().overlayLayer).selectAll("svg").each(function(each_el){
              
              

              
              elapsedtime =   Number(new Date()) - reverse_time.get('start_time');
//              console.log(d3.select(this).select('circle').attr("class"));


              cat = station_map.get(Math.floor(elapsedtime/1000));

              if (each_el.value.properties.file == _this.url){

                  d3.select(this).select('circle').attr('r', 0).attr('r', 3 * rscaleex(aver)).style('fill-opacity', 0.7).style('stroke', "none").style('fill', color_map.get(cat)).style('fill-opacity', 0.2)
                
                  if (category_station_current.get(cat) == "true") {
                    var ext = d3.select(this).append('circle').attr('cx', padding + (Math.random()*5)).attr('cy',padding + (Math.random()*5)).attr('r', 0).attr('r', rscale(aver)).style('fill-opacity', 0.8).style('stroke', color_map.get(cat)).style('fill', color_map.get(cat)).style('fill-opacity', 0.15);
                
                    ext.transition().remove([])


                  }

                  
                  
                  return 
              } else if(category_station_current.get('A') == 'true') {
                for (k = 0, len = lkps.length; k < len; k=k+60) {
                  lookup = lkps[k]
                  console.log(lookup)
                  cat2 = Math.floor(elapsedtime/1000)
                  console.log(cat2)
                  var ext = d3.select(this).append('circle').attr('cx', padding + (Math.random())).attr('cy',padding + (Math.random())).attr('r', 0).attr('r', rscale(Math.random()*15)).style('opacity', 0.1).style('stroke', '#ef532f').style('fill', '#ef532f').style('fill-opacity', 0.05);
                  ext.transition().remove([])
                }
                
                
                    
              }
              
            })




    

          };
        };
         

         _this.overlay.reset = function () {
            d3.select(this.getPanes().overlayLayer).selectAll("svg").each(function(each_el){
              
                return d3.select(this).select('circle').attr('r', 0).attr('r', rscale(0)).style('fill-opacity', oscale(0)).style('stroke', _this.color).style('fill', _this.color)
              
            })

    

          };
  // Bind our overlay to the map…
  // console.log(_this.overlay)
  _this.overlay.setMap(_this.map);
});`
  map.data.loadGeoJson('/data')
  map.data.setStyle (feature) ->
    icon:
      path: google.maps.SymbolPath.CIRCLE
      scale: 20
      strokeColor: '#ef532f'
      fillColor: '#ef532f'
      fillOpacity: 0.4
      strokeWeight: 0
  onClick = @map.data.addListener("mousedown", (event) =>

    cat = category_station_current.get('category')
    id = event.feature.getProperty('location_number')
    console.log(id, cat)
    # console.log cat, event.feature.getProperty('location_number')
    try
      if current_station_map.get(id) == 'true'
        playPause()
        current_station_map.set(id, 'false')
    catch e
      current_station_map.set(id, 'true')
    current_station_map.set("current_station", id)
    $.ajax
      dataType: 'json'
      url: "/brokenDown/#{id}"
      success: (kup_table) =>
        station_map = d3.map()
        for each_row in kup_table
          station_map.set(each_row.seconds, each_row.category)
    # $.ajax
    #   dataType: 'json'
    #   url: "/lookupby/#{cat}_#{id}"
      # success: (_table) =>
      #   try
      #     occurance = _table[0]
      #     occurances = occurance["time_in_seconds"].split(',')
      #     for splits in occurances
      #       each_p = splits.split('-')
      #       if +each_p[0] < ctime < +each_p[1]
      #         @color = color_map.get("#{cat}")
      #       else
      #         @color = '#ef532f'
      #   catch e
      #     @color = '#ef532f'
        state_of_click.set('clicked', true)
        if state_of_map.get('currentPlayingFile') != event.feature.getProperty('file')
          @sourceNode.disconnect(0)
          @sourceNode = @context.createBufferSource()
          @sourceNode.connect @analyser
          @analyser.connect @javascriptNode
          # and connect to destination, if you want audio
          @sourceNode.connect(@context.destination)
          @dispatch.end(event)
          @dispatch.start(event)
          # console.log @context.destination.currentTime
        else 
          playPause()
        
        state_of_map.set('currentPlayingFile', event.feature.getProperty('file'))

        
        onMouseover.remove()
        @map.data.revertStyle()
        @map.data.overrideStyle event.feature, icon: 
          path: google.maps.SymbolPath.CIRCLE
          scale: 36
          strokeColor: '#ef532f'
          fillColor: '#ef532f'
          fillOpacity: 0.0
          strokeWeight: 0.2
          opacity: 0.05
  )
  onMouseover = @map.data.addListener("mouseover", (event) =>
    @map.data.revertStyle()
    @map.data.overrideStyle event.feature, icon: 
      path: google.maps.SymbolPath.CIRCLE
      scale: 18.5
      strokeColor: '#ef532f'
      fillColor: '#ef532f'
      fillOpacity: 0.6
      strokeWeight: 0.4
  )


  @context = new ((window.AudioContext or window.webkitAudioContext))
  if !@context.createGain
    @context.createGain = @context.createGainNode
  if !context.createDelay
    @context.createDelay = @context.createDelayNode
  if !context.createScriptProcessor
    @context.createScriptProcessor = @context.createJavaScriptNode
  # shim layer with setTimeout fallback
  window.requestAnimFrame = do ->
    window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback) ->
      window.setTimeout callback, 1000 / 60
      return



  setupAudioNodes = =>
    #  setup a javascript node
    @javascriptNode = @context.createScriptProcessor(2048, 1, 1)
    # connect to destination, else it isn't called
    @javascriptNode.connect(@context.destination)
    # setup a analyzer
    @analyser = @context.createAnalyser()
    @analyser.smoothingTimeConstant = 0.3
    @analyser.fftSize = 1024
    # create a buffer source node
    @sourceNode = @context.createBufferSource()
    # connect the source to the analyser
    @sourceNode.connect @analyser
    # we use the javascript node to draw at a specific interval.
    @analyser.connect @javascriptNode
    # and connect to destination, if you want audio
    @sourceNode.connect(@context.destination)



  setupAudioNodes()
  

  loadSound = (url) =>
    @url = url
    request = new XMLHttpRequest
    request.open 'GET', url, true
    request.responseType = 'arraybuffer'
    # When loaded decode the data

    request.onload = =>
      # decode the data
      @context.decodeAudioData request.response, ((buffer) ->
        # when the audio is decoded play the sound
        playSound buffer 
        return
      ), onError
      return

    request.send()
    return


  playSound = (buffer) =>
    @sourceNode.buffer = buffer
    time = new Date()
    reverse_time.set('start_time', Number(time))
    @sourceNode.start 0

  stopSound = (url) =>
    @sourceNode.stop
    setupAudioNodes()
    loadSound(url)

  onError = (e) =>
    # console.log e

  

  @javascriptNode.onaudioprocess = =>
    # get the average, bincount is fftsize / 2
    array = new Uint8Array(@analyser.frequencyBinCount)
    @analyser.getByteFrequencyData array
    average = getAverageVolume(array)
    # clear the current state
    # console.log station_map
    # cat = station_map.get(Math.floor(@context.currentTime))
    # console.log cat
    @overlay.reset()
    @overlay.update(average)
    return


  getAverageVolume = (array) ->
    values = 0
    average = undefined
    length = array.length
    # get all the frequency amplitudes
    i = 0
    while i < length
      values += array[i]
      i++
    average = values / length
    average




  playPause = =>
    if @context.state == 'running'
      @context.suspend().then ->
        @context.textContent = 'Resume context'
        return
    else if @context.state == 'suspended'
      @context.resume().then ->
        @context.textContent = 'Suspend context'
        return

  drawMap()

  updateMap = (average) =>
    @map.data.revertStyle()
    @map.data.overrideStyle event.feature, icon: 
      path: google.maps.SymbolPath.CIRCLE
      scale: average
      strokeColor: '#ef532f'
      fillColor: '#ef532f'
      fillOpacity: 0.5
      strokeWeight: 1.4


  CenterControl = (controlDiv, map) ->
    # Set CSS for the control border.
    controlUI = document.createElement('div')
    controlUI.style.backgroundColor = '#fff'
    controlUI.style.border = '2px solid #fff'
    controlUI.style.borderRadius = '1px'
    controlUI.style.boxShadow = '0 2px 6px rgba(0,0,0,.3)'
    controlUI.style.cursor = 'pointer'
    controlUI.style.marginBottom = '22px'
    controlUI.style.textAlign = 'left'
    controlUI.title = 'menu'
    controlDiv.appendChild controlUI
    # Set CSS for the control interior.
    controlText = document.createElement('div')
    controlText.style.color = 'rgb(25,25,25)'
    controlText.style.fontFamily = 'Roboto,Arial,sans-serif'
    controlText.style.fontSize = '16px'
    controlText.style.lineHeight = '38px'
    controlText.style.paddingLeft = '5px'
    controlText.style.paddingRight = '5px'
    controlText.innerHTML = '|||'
    controlUI.appendChild controlText
    # Setup the click event listeners: simply set the map to Chicago.
    controlUI.addEventListener 'click', ->
      $('.ui.sidebar').sidebar 'toggle'

      return
    return

  map_style = {}
  map_style.google_maps_customization_style = [
    { stylers: [
      { invert_lightness: true }
      { weight: 1 }
      { saturation: -100 }
      { lightness: -40 }
    ] }
    {
      elementType: 'labels'
      stylers: [ { visibility: 'simplified' } ]
    }
  ]
  rotate90 = ->
    heading = map.getHeading() or 0
    map.setHeading heading + 90
    return

  autoRotate = ->
    # Determine if we're showing aerial imagery.
    if map.getTilt() != 0
      window.setInterval rotate90, 3000
    return
  map.setMapTypeId google.maps.MapTypeId.ROADMAP
  map.setOptions styles: map_style.google_maps_customization_style
  # define the torque layer style using cartocss
  map.setTilt(45)
  $('.ui.sidebar').sidebar 'toggle'
  customControl = L.Control.extend(
    options: position: 'topleft'
    onAdd: (map) ->
      container = L.DomUtil.create('div', 'leaflet-control leaflet-control-custom')
      container.style.width = '30px'
      container.style.height = '30px'
      container.style.opacity = 1
      container.style.color = 'white'
      L.DomUtil.get(container).innerHTML = "<i class='huge white sidebar icon'></i>"
      container.onclick = ->
        $('.ui.sidebar').sidebar 'toggle'
        return

      container
  )
  centerControlDiv = document.createElement('div')
  centerControl = new CenterControl(centerControlDiv, map)
  centerControlDiv.index = 1

  map.controls[google.maps.ControlPosition.TOP_LEFT].push centerControlDiv
  $('.ui.sidebar').on('change', (e) ->
    id = $(e.target).attr("name")[0].toUpperCase()
    category_station_current.set('category', id)
    if category_station_current.get(id) == 'false'
      category_station_current.set(id, 'true')
    else
      category_station_current.set(id, 'false')
    # console.log id, category_station_current
    
  )
  $("#about").on('click', ->
    $('.ui.basic.modal').modal 'show'
  )
  $('#sateliteBaseLayer').click (event) =>
    map.setMapTypeId google.maps.MapTypeId.SATELLITE
  $('#streetsBaseLayer').click (event) =>
    map.setMapTypeId google.maps.MapTypeId.ROADMAP
  return
  

  

