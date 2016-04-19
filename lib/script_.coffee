# author: armin.akhavan@gmail.com
do ->
  map = new (google.maps.Map)(d3.select('#map').node(),
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


  sound_lookup = d3.map()
  geometry_lookup = d3.map()
  # Start off by initializing a new context.
  context = new ((window.AudioContext or window.webkitAudioContext))
  if !context.createGain
    context.createGain = context.createGainNode
  if !context.createDelay
    context.createDelay = context.createDelayNode
  if !context.createScriptProcessor
    context.createScriptProcessor = context.createJavaScriptNode
  # shim layer with setTimeout fallback
  window.requestAnimFrame = do ->
    window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame or (callback) ->
      window.setTimeout callback, 1000 / 60
      return

  playSound = (buffer, time) ->
    source = context.createBufferSource()
    source.buffer = buffer
    source.connect context.destination
    source[if source.start then 'start' else 'noteOn'] time
    return

  loadSounds = (obj, soundMap, callback) ->
    # Array-ify
    names = []
    paths = []
    for name of soundMap
      path = soundMap[name]
      names.push name
      paths.push path
    bufferLoader = new BufferLoader(context, paths, (bufferList) ->
      `var name`
      i = 0
      while i < bufferList.length
        buffer = bufferList[i]
        name = names[i]
        obj[name] = buffer
        i++
      if callback
        callback()
      return
  )
    bufferLoader.load()
    return

  BufferLoader = (context, urlList, callback) ->
    @context = context
    @urlList = urlList
    @onload = callback
    @bufferList = new Array
    @loadCount = 0
    return



  BufferLoader::loadBuffer = (url, index) ->
    # Load buffer asynchronously
    request = new XMLHttpRequest
    request.open 'GET', url, true
    request.responseType = 'arraybuffer'
    loader = this

    request.onload = ->
      # Asynchronously decode the audio file data in request.response
      loader.context.decodeAudioData request.response, ((buffer) ->
        if !buffer
          alert 'error decoding file data: ' + url
          return
        loader.bufferList[index] = buffer
        if ++loader.loadCount == loader.urlList.length
          loader.onload loader.bufferList
        return
      ), (error) ->
        console.error 'decodeAudioData error', error
        return
      return

    request.onerror = ->
      alert 'BufferLoader: XHR error'
      return

    request.send()
    return

  BufferLoader::load = ->
    i = 0
    while i < @urlList.length
      @loadBuffer @urlList[i], i
      ++i
    return
  VisualizerSample = (file)->

    onLoaded = ->
      button = document.querySelector('button')
      button.removeAttribute 'disabled'
      button.innerHTML = 'Play/pause'
      return

    @analyser = context.createAnalyser()
    @analyser.connect context.destination
    @analyser.minDecibels = -140
    @analyser.maxDecibels = 0
    loadSounds this, { buffer: "#{file}" }, onLoaded
    @freqs = new Uint8Array(@analyser.frequencyBinCount)
    @times = new Uint8Array(@analyser.frequencyBinCount)
    @isPlaying = false
    @startTime = 0
    @startOffset = 0
    return

  VisualizerSample::togglePlayback = ->
    if @isPlaying
      # Stop playback
      @source[if @source.stop then 'stop' else 'noteOff'] 0
      @startOffset += context.currentTime - (@startTime)
      console.log 'paused at', @startOffset
      # Save the position of the play head.
    else
      @startTime = context.currentTime
      console.log 'started at', @startOffset
      @source = context.createBufferSource()
      # Connect graph
      @source.connect @analyser
      @source.buffer = @buffer
      @source.loop = true
      # Start playback, but make sure we stay in bound of the buffer.
      @source[if @source.start then 'start' else 'noteOn'] 0, @startOffset % @buffer.duration
      # Start visualizer.
      requestAnimFrame @draw.bind(this)
    @isPlaying = !@isPlaying
    return

  VisualizerSample::draw = ->
    `var i`
    `var value`
    `var percent`
    `var height`
    `var offset`
    `var barWidth`
    @analyser.smoothingTimeConstant = SMOOTHING
    @analyser.fftSize = FFT_SIZE
    # Get the frequency data from the currently playing music
    @analyser.getByteFrequencyData @freqs
    @analyser.getByteTimeDomainData @times
    width = Math.floor(1 / @freqs.length, 10)
    canvas = document.querySelector('canvas')
    drawContext = canvas.getContext('2d')
    canvas.width = WIDTH
    canvas.height = HEIGHT
    # Draw the frequency domain chart.
    i = 0
    while i < @analyser.frequencyBinCount
      value = @freqs[i]
      percent = value / 256
      height = HEIGHT * percent
      offset = HEIGHT - height - 1
      barWidth = WIDTH / @analyser.frequencyBinCount
      hue = i / @analyser.frequencyBinCount * 360
      drawContext.fillStyle = 'hsl(' + hue + ', 100%, 50%)'
      drawContext.fillRect i * barWidth, offset, barWidth, height
      i++
    # Draw the time domain chart.
    i = 0
    while i < @analyser.frequencyBinCount
      value = @times[i]
      percent = value / 256
      height = HEIGHT * percent
      offset = HEIGHT - height - 1
      barWidth = WIDTH / @analyser.frequencyBinCount
      drawContext.fillStyle = 'white'
      drawContext.fillRect i * barWidth, offset, 1, 2
      i++
    if @isPlaying
      requestAnimFrame @draw.bind(this)
    return

  VisualizerSample::getFrequencyValue = (freq) ->
    nyquist = context.sampleRate / 2
    index = Math.round(freq / nyquist * @freqs.length)
    @freqs[index]



  # sample = new VisualizerSample()
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
      # container.style.backgroundColor = 'white'
      container.style.width = '30px'
      container.style.height = '30px'
      container.style.opacity = 1
      container.style.color = 'white'
      L.DomUtil.get(container).innerHTML = "<i class='huge white sidebar icon'></i>"
      container.onclick = ->
        console.log 'buttonClicked'
        $('.ui.sidebar').sidebar 'toggle'
        return

      container
  )

  # console.log 'inside the scriptjs'
  # console.log 'cartodb', cartodb



  # L.mapbox.accessToken = 'pk.eyJ1IjoiYXJtaW5hdm4iLCJhIjoiSTFteE9EOCJ9.iDzgmNaITa0-q-H_jw1lJw'
  
  # map = L.mapbox.map('map', null, zoomControl:false).setView([
    # 42.364981
    # -71.053695
  # ], 16)
  # L.mapbox.styleLayer('mapbox://styles/arminavn/cimgzcley000nb9nluxbgd3q5').addTo(map)
  # layers = 
  #   Streets: L.mapbox.styleLayer('mapbox://styles/arminavn/cimgzcley000nb9nluxbgd3q5').addTo(map)
  #   Satellite: L.mapbox.tileLayer('mapbox.satellite')
  # # layers.Satellite.addTo map
  # L.control.layers(layers).addTo map
    
      

    # Bind our overlay to the map…
    # overlay.setMap map
    # return
  $("#about").on('click', ->
    console.log "cityCircle"
    $('.ui.basic.modal').modal 'show'
  )
  state_of_click = d3.map()
  lookup_map = d3.map()
  $.ajax
    dataType: 'json'
    url: '/lookup'
    success: (lookup_table) =>
      for each_row in lookup_table
        lookup_map.set([each_row.location_number, each_row.category], each_row.time_in_seconds)

  $.ajax
    dataType: 'json'
    url: '/data'
    success: (geojson) ->
      # overlay = new (google.maps.OverlayView)
      # Add the container when the overlay is added to the map.
      # file_list = 
      
      # markers = []
      # console.log geojson
      # sampleslist = geojson.features.map (obj) ->
      #   # obj.properties.file
      #   # for each 
      #   lineSymbol = 
      #     path: google.maps.SymbolPath.CIRCLE
      #     scale: 8
      #     strokeColor: '#ef532f'
      #     fillColor: '#ef532f'
      #     fillOpacity: 0.1
      #     strokeWeight: 0.4

      #   line = new (google.maps.Marker)(
      #     # path: [
      #     #   {
      #     #     lat: 22.291
      #     #     lng: 153.027
      #     #   }
      #     #   {
      #     #     lat: 18.291
      #     #     lng: 153.027
      #     #   }
      #     # ]
      #     # icons: [ {
      #     icon: lineSymbol
      #       # offset: '100%'
      #     # } ]
      #     position: {"lat": obj.geometry.coordinates[1], "lng":obj.geometry.coordinates[0]}
      #     map: map
      #     )
      #   lineClick = line.addListener("click", (event) ->
      #     console.log "clock", event, this.icon
      #     console.log line.get(this)
      #     d3.select(this).style("fill", "blue")

      #     # sound_lookup.get()
      #     )
      #   # state_of_click.set('clicked', true)

        
      #   sound_lookup.set(obj.properties.file,new VisualizerSample(obj.properties.file))
      #   geometry_lookup.set(obj.properties.file, {"lat": obj.geometry.coordinates[1], "lng":obj.geometry.coordinates[0]})
      map.data.loadGeoJson('/data')
      # for point_location in geojson.features
        # oMarker = new (google.maps.Marker)(
        #   position: {"lat": point_location.geometry.coordinates[1], "lng":point_location.geometry.coordinates[0]}
        #   sName: point_location.properties.file
        #   # map: map
        #   icon:
            # path: google.maps.SymbolPath.CIRCLE
            # scale: 8.5
            # strokeColor: '#ef532f'
            # fillColor: '#ef532f'
            # fillOpacity: 0.1
            # strokeWeight: 0.4)
      map.data.setStyle (feature) ->
        icon:
          path: google.maps.SymbolPath.CIRCLE
          scale: 8.5
          strokeColor: '#ef532f'
          fillColor: '#ef532f'
          fillOpacity: 0.7
          strokeWeight: 1.8
      onClick = map.data.addListener("click", (event) ->
        # state_of_click.set('clicked', true)
        onMouseover.remove()
        map.data.revertStyle()
        map.data.overrideStyle event.feature, icon: 
          path: google.maps.SymbolPath.CIRCLE
          scale: 18.5
          strokeColor: '#ef532f'
          fillColor: '#ef532f'
          fillOpacity: 0.5
          strokeWeight: 1.4
        # console.log event.feature.getProperty('file')
        # @sound = new Howl(
        #   urls: [
        #     "#{event.feature.getProperty('file')}"
        #   ])


        if state_of_click.get('clicked') is false
          map.data.revertStyle()
          # @sound.stop() 
          state_of_click.set('clicked', true)

        else 
          state_of_click.set('clicked', false)
          # console.log(sample_instance)
          sample_instance = new VisualizerSample("#{event.feature.getProperty('file')}")
          # sample_instance = sound_lookup.get("#{event.feature.getProperty('file')}")
          sample_instance.togglePlayback()

          sample_instance.draw()
          # document.querySelector('button').addEventListener 'click', ->
          #   sample.togglePlayback()
          #   sample.draw()
          #   return
          @sound = new Howl(
            urls: [
              "#{event.feature.getProperty('file')}"
            ]
            buffer: true).play()
          # console.log @sound
          return

          )

      onMouseover = map.data.addListener("mouseover", (event) =>
        map.data.revertStyle()
        map.data.overrideStyle event.feature, icon: 
          path: google.maps.SymbolPath.CIRCLE
          scale: 18.5
          strokeColor: '#ef532f'
          fillColor: '#ef532f'
          fillOpacity: 0.5
          strokeWeight: 0.4
        # console.log event.feature.getProperty('file')
          
        return

        )
        # markers.push new (google.maps.Marker)(
        #   position: {"lat": point_location.geometry.coordinates[1], "lng":point_location.geometry.coordinates[0]}
        #   sName: point_location.properties.file
        #   map: map
        #   icon:
        #     path: google.maps.SymbolPath.CIRCLE
        #     scale: 8.5
        #     strokeColor: '#ef532f'
        #     fillColor: '#ef532f'
        #     fillOpacity: 0.1
        #     strokeWeight: 0.4)
        # cityCircle = new (google.maps.Circle)(
        #     strokeColor: '#ef532f'
        #     strokeOpacity: 0.3
        #     strokeWeight: 0
        #     fillColor: '#ef532f'
        #     fillOpacity: 0.5
        #     map: map
        #     center: {"lat": point_location.geometry.coordinates[1], "lng":point_location.geometry.coordinates[0]}
        #     radius: 10)
        
      # for mar in markers
      # console.log markers
      # for each in markers
      #   each.addListener('mouseover', (event) =>
      #       console.log "this",event.feaure)
        # each.addListener
        # google.maps.event.addListener each, 'mouseover', (cir) =>
        #     console.log "this",cir, cir.fromElement
        #     console.log markers
            # each.setIcon(
            #   path: google.maps.SymbolPath.CIRCLE
            #   scale: 18.5
            #   strokeColor: '#ef532f'
            #   fillColor: '#ef532f'
            #   fillOpacity: 0.1
            #   strokeWeight: 0.4)

      #   mar.setMap(map)

      # overlay.onAdd = ->
      #   layer = d3.select(@getPanes().overlayLayer).append('div').attr('class', 'stations')
      #   # Draw each marker as a separate SVG element.
      #   # We could use a single SVG, but what size would it have?

      #   overlay.draw = ->
      #     projection = @getProjection()
      #     # console.log projection
      #     padding = 10
          
      #     # Add a circle.

      #     transform = (d) ->
      #       # console.log d
      #       d = new (google.maps.LatLng)("lat": d.value.geometry.coordinates[1], "lng":d.value.geometry.coordinates[0])
      #       d = projection.fromLatLngToDivPixel(d)
      #       d3.select(this).style('left', d.x - padding + 'px').style 'top', d.y - padding + 'px'
          
      #     marker = layer.selectAll('svg').data(d3.entries(geojson.features)).each(transform).enter()
      #     .append('svg').each(transform).attr('class', 'marker').append('circle').attr('r', 4.5).attr('cx', padding).attr 'cy', padding
      #     # marketExit = marker.exit().remove()
      #     marker.style('stroke', 'red')

      #     # marker.on('mouseover', mouseover)
      #     # mouseover = (e) =>
      #     #   console.log "e", e
      #     # Add a label.
      #     # marker.append('text').attr('x', padding + 7).attr('y', padding).attr('dy', '.31em').text (d) ->
      #       # d.key
      #     return

      #   return

      # Bind our overlay to the map…
      
      # overlay.addListener 'mouseover', (e) =>
      #     console.log w, overlay
      # overlay.setMap map
          # overlay.setIcon
          #   path: google.maps.SymbolPath.CIRCLE
          #   scale: 10
          #   fillColor: '#ef532f'
          #   fillOpacity: 0.8
          #   strokeWeight: 1
          # console.log "this", cir, i
          # cir.set('radius', 15)
      return
      # overlay = new (google.maps.OverlayView)
      # # Add the container when the overlay is added to the map.

      # overlay.onAdd = ->
      #   layer = d3.select(@getPanes().overlayLayer).append('div').attr('class', 'stations')
      #   # Draw each marker as a separate SVG element.
      #   # We could use a single SVG, but what size would it have?
      #   console.log layer
      #   console.log overlay
      #   overlay.draw = ->
      #     projection = @getProjection()
      #     padding = 10
      #     marker = layer.selectAll('svg').data(d3.entries(geojson.features)).each(transform).enter().append('svg').each(transform).attr('class', 'marker')
      #     # Add a circle.

      #     transform = (d) ->
      #       d = new (google.maps.LatLng)("lat": d.geometry.coordinates[1], "lng":d.geometry.coordinates[0])
      #       d = projection.fromLatLngToDivPixel(d)
      #       d3.select(this).style('left', d.x - padding + 'px').style 'top', d.y - padding + 'px'

      #     marker.append('circle').attr('r', 4.5).attr('cx', padding).attr 'cy', padding
      #     # Add a label.
      #     marker.append('text').attr('x', padding + 7).attr('y', padding).attr('dy', '.31em').text (d) ->
      #       d.key
      #     return

        


      #   overlay.setMap map 
      #   return
      # for point_location in geojson.features
        
      # # Add the circle for this city to the map.
        # oMarker = new (google.maps.Marker)(
        #   position: {"lat": point_location.geometry.coordinates[1], "lng":point_location.geometry.coordinates[0]}
        #   sName: point_location.properties.file
        #   map: map
        #   icon:
        #     path: google.maps.SymbolPath.CIRCLE
        #     scale: 8.5
        #     strokeColor: '#ef532f'
        #     fillColor: '#ef532f'
        #     fillOpacity: 0.4
        #     strokeWeight: 0.4)
        # cityCircle = new (google.maps.Circle)(
        #   strokeColor: '#ef532f'
        #   strokeOpacity: 0.3
        #   strokeWeight: 0
        #   fillColor: '#ef532f'
        #   fillOpacity: 0.5
        #   map: map
        #   center: {"lat": point_location.geometry.coordinates[1], "lng":point_location.geometry.coordinates[0]}
        #   radius: 10)
        # cityCircle.setMap(map)
        # google.maps.event.addListener oMarker, 'mouseover', (cir) =>
        #   console.log cir
        #   oMarker.setIcon
        #     path: google.maps.SymbolPath.CIRCLE
        #     scale: 10
        #     fillColor: '#ef532f'
        #     fillOpacity: 0.8
        #     strokeWeight: 1
        #   console.log "this", cir, i
        #   cir.set('radius', 15)
        # cityCircle.addListener('mouseover', mousedOvered)
      mousedOvered = (event)=>
        console.log "mousef", event
      # geoJson = L.geoJson(geojson, pointToLayer: (feature, latlng) =>
      #   L.circleMarker latlng,fillColor: "#ef532f",fillOpacity:0.3 ,color: "white", opacity: 0.5,weight: 0, radius: 5
      # ).on("mouseover", (e, layer) =>
      #   e.layer.setStyle(
      #     radius: 10
      #     )
      # ).on("mouseout", (e, layer) =>
      #   e.layer.setStyle(
      #     radius: 5
      #     )
      # ).on("click", (e, layer) =>
      #   if e.target.hasEventListeners('mouseout') is false
      #     @sound.stop()
      #     e.target.addEventListener("mouseout", (e) =>
      #       e.layer.setStyle(
      #         radius: 5
      #         )
      #       )
      #     e.target.fire("mouseout")
      #   e.target.off('mouseout')
      #   # console.log "click",e,e.layer.feature.properties.file, e.target, e.target._layers, layer
      #   @sound = new Howl(urls: [
      #     "#{e.layer.feature.properties.file}"
      #   ]).play()
      #   $('#play').on 'click', ->
      #     sound.stop().play()
      #     return
      # )#.addTo(map)
      # On success add fetched data to the map.
      # console.log geojson
      # L.mapbox.featureLayer(geojson).addTo map
      return
  # map.addControl new customControl
  

  centerControlDiv = document.createElement('div')
  
  centerControl = new CenterControl(centerControlDiv, map)
  
  centerControlDiv.index = 1
  

  map.controls[google.maps.ControlPosition.TOP_LEFT].push centerControlDiv
  $('#sateliteBaseLayer').click (event) =>
    # console.log "cliock"
    map.setMapTypeId google.maps.MapTypeId.SATELLITE
  $('#streetsBaseLayer').click (event) =>
    # console.log "cliock"
    map.setMapTypeId google.maps.MapTypeId.ROADMAP
    # event.preventDefault()

  # torqueLayer.addTo map
  # torqueLayer.play()
  # sql = cartodb.SQL(
  #   user: 'arminavn'
  #   format: 'geojson')
  return

# module.exports = SensoryInformants


# ---
# generated by js2coffee 2.1.0