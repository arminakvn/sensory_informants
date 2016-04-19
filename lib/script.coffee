# author: armin.akhavan@gmail.com
do ->
  
  rscale =  d3.scale.linear().domain([8, 30]).range([0, 10])
  oscale =  d3.scale.linear().domain([8, 25]).range([ 0.8,0.2])
  @map = new (google.maps.Map)(d3.select('#map').node(),
    center: new (google.maps.LatLng)(42.364981,-71.053695)
    zoom: 16
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
    console.log "endSound"
    # stopSound(event.feature.getProperty('file'))
  listener = (event) =>
    
          


    loadSound(event.feature.getProperty('file'))

  @dispatch = d3.dispatch("start", "end")
  @dispatch.on("start", listener)
  @dispatch.on("end", endSound)
  state_of_click = d3.map()
  state_of_map = d3.map()
  lookup_map = d3.map()
  category_station_current = d3.map()
  color_map = d3.map()
  category_station_current.set('category', 'A')
  sound_category_times = d3.map()
  color_map.set('C', "#A03F97")
  color_map.set('T', "#1B9E83")
  color_map.set('H', "#9BBF3A")
  color_map.set('B', "#E9B221")
  color_map.set('W', "#90D5E1")
  color_map.set('M', "#EE3125")
  color_map.set('A', "#ef532f")
  $.ajax
    dataType: 'json'
    url: '/lookup'
    success: (lookup_table) =>
      for each_row in lookup_table
        lookup_map.set([each_row.location_number, each_row.category], each_row.time_in_seconds)
  drawMap = =>
    `d3.json("/data", function(error, data) {
        if (error) throw error;

        _this.overlay = new google.maps.OverlayView();
        console.log("_this", _this)
        // Add the container when the overlay is added to the map.
        overlay.onAdd = function() {
          _this.layer = d3.select(this.getPanes().overlayLayer).append("div")
              .attr("class", "stations");

          // Draw each marker as a separate SVG element.
          // We could use a single SVG, but what size would it have?
          _this.overlay.draw = function() {
            projection = this.getProjection(),
                padding = 10;

            _this.marker = _this.layer.selectAll("svg")
                .data(d3.entries(data.features))
                .each(transform) // update existing markers
              .enter().append("svg")
                .each(transform)
                .attr("class", "marker");

            // Add a circle.
            _this.marker.append("circle")
                .attr("r", 0)
                .attr("cx", padding)
                .attr("cy", padding).attr("id", function(d){
                    return d.value.properties.file;
                })
                .style("fill", "red").style("stroke", "none")  ;

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
            console.log(aver)
            d3.select(this.getPanes().overlayLayer).selectAll("svg").each(function(each_el){
              
              if (each_el.value.properties.file == _this.url){
                return d3.select(this).select('circle').attr('r', 0).attr('r', rscale(aver)).style('fill-opacity', oscale(aver)).style('stroke', _this.color).style('fill', _this.color)
              }
              
            })

    

          };
        };

  // Bind our overlay to the map…
  _this.overlay.setMap(_this.map);
});`
  map.data.loadGeoJson('/data')
  map.data.setStyle (feature) ->
    icon:
      path: google.maps.SymbolPath.CIRCLE
      scale: 20
      strokeColor: '#ef532f'
      fillColor: '#ef532f'
      fillOpacity: 0.1
      strokeWeight: 0
  onClick = @map.data.addListener("click", (event) =>

    cat = category_station_current.get('category')
    id = event.feature.getProperty('location_number')
    console.log cat, event.feature.getProperty('location_number')
    $.ajax
      dataType: 'json'
      url: "/lookupby/#{cat}_#{id}"
      success: (_table) =>
        console.log "_table",_table[0]
        try
          occurance = _table[0]
          occurances = occurance.split('_')
        catch e
          console.log "no occurance"

        
        
        
        # for i in occurance.length
        #   sound_category_times.set("#{i}", occurance[i])
        if occurance isnt undefined
          @color = color_map.get("#{cat}")
        else
          @color = '#ef532f'

        state_of_click.set('clicked', true)
        console.log(sound_category_times)
        console.log state_of_map.get('currentPlayingFile')
        if state_of_map.get('currentPlayingFile') != event.feature.getProperty('file')
          @dispatch.end(event)
          @dispatch.start(event)
        else 
          playPause()
        
        state_of_map.set('currentPlayingFile', event.feature.getProperty('file'))

        
        onMouseover.remove()
        @map.data.revertStyle()
        @map.data.overrideStyle event.feature, icon: 
          path: google.maps.SymbolPath.CIRCLE
          scale: 18
          strokeColor: '#ef532f'
          fillColor: '#ef532f'
          fillOpacity: 0.1
          strokeWeight: 0.9
  )
  onMouseover = @map.data.addListener("mouseover", (event) =>
    @map.data.revertStyle()
    @map.data.overrideStyle event.feature, icon: 
      path: google.maps.SymbolPath.CIRCLE
      scale: 18.5
      strokeColor: '#ef532f'
      fillColor: '#ef532f'
      fillOpacity: 0.5
      strokeWeight: 0.4
  )



  # @vis = d3.select('.vis').append('svg').append('g').attr("transform",translate)
  # @circle = vis.append('circle').attr('r', 20).style('fill', 'red')
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
    @sourceNode.start 0

  stopSound = (url) =>
    console.log "stopSound"
    @sourceNode.stop
    setupAudioNodes()
    loadSound(url)



  onError = (e) =>
    console.log e


  # loadSound('Location02TonyDeMarcoWay.mp3')
  

  @javascriptNode.onaudioprocess = =>
    # get the average, bincount is fftsize / 2
    array = new Uint8Array(@analyser.frequencyBinCount)
    @analyser.getByteFrequencyData array
    average = getAverageVolume(array)
    # clear the current state
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
    console.log "id", id
    category_station_current.set('category', id)

    
  )
  $("#about").on('click', ->
    $('.ui.basic.modal').modal 'show'
  )
  $('#sateliteBaseLayer').click (event) =>
    map.setMapTypeId google.maps.MapTypeId.SATELLITE
  $('#streetsBaseLayer').click (event) =>
    map.setMapTypeId google.maps.MapTypeId.ROADMAP
  return
  

  

