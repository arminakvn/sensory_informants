`var path`
'use strict'






# server will start by going through the sound files and generates the data containing the
# values for each seconds and then will server the tables through an api
express = require('express')
request = require 'request'
path = require('path')
http = require('http')
path = require('path')
async = require('async')
serveStatic = require('serve-static')
cartodb = require('cartodb')
app = express()
app.disable 'etag'
app.set 'trust proxy', true
app.use serveStatic('./', 'index': [
  'index.html'
  'index.htm'
])
app.use serveStatic('./bower_components/jquery/dist')
app.use serveStatic('./node_modules/web-audio-api/lib')
app.use serveStatic('./lib')
app.use serveStatic('./bower_components/mapbox.js')
app.use serveStatic('./bower_components/semantic/dist')
app.use serveStatic('./bower_components/cartodb.js')
app.use serveStatic('./bower_components/cartodb.js/themes/css')
app.use serveStatic('./bower_components/d3')
app.use serveStatic('./bower_components/d3-queue')

app.use serveStatic('./sounds')

user= "arminavn"
api_key= "9150413ca8fb81229459d0a5c2947620e42d0940"
sql= "SELECT * FROM table_4"
lookup_sql= "SELECT * FROM soundsbrokendown_3min_3"
labels_sql = "SELECT * FROM category_lookup"

app.get '/labels', (req, res) =>
  labels_res = []
  request {
    method: 'GET'
    url: "https://#{user}.cartodb.com/api/v2/sql?q=#{labels_sql}&api_key=#{api_key}"
    json: true
  }, (error, label_response, labes_body) =>
    
    for ea in labes_body.rows
      labels_res.push
        "abbr": ea.description
        "name": ea.name
    res.send labels_res

app.get '/lookup', (req, res) =>
    lookup_features = []
    request {
          method: 'GET'
          url: "https://#{user}.cartodb.com/api/v2/sql?q=#{lookup_sql}&api_key=#{api_key}"
          json: true
        }, (error, lookup_response, lookup_body) =>
          if !error and lookup_response.statusCode == 200
            # console.log body
            # console.log body.rows.length
            for each in lookup_body.rows
              lookup_features.push 
                "location_number": +each.number
                "time_in_seconds": each.time_in_seconds
                "category": each.category
              
            res.send lookup_features
            # @emit 'radarResponds', body.results

app.get '/brokenDown/:station', (req, res) =>
    param = req.params.station
    lookup_sql = "SELECT * FROM soundsbrokendown_3min_3 WHERE SoundFile=#{param}"
    lookup_features = []
    request {
          method: 'GET'
          url: "https://#{user}.cartodb.com/api/v2/sql?q=#{lookup_sql}&api_key=#{api_key}"
          json: true
        }, (error, lookup_response, lookup_body) =>
          if !error and lookup_response.statusCode == 200
            # console.log body
            # console.log body.rows.length
            for each in lookup_body.rows
              lookup_features.push 
                "location_number": +each.soundfile
                "seconds": each.seconds
                "category": each.category
              
            res.send lookup_features

app.get '/lookupby/:category_station', (req, res) =>
    param = req.params.category_station.split('_')
    lookup_sql = "SELECT * FROM northend_soundcategories_time WHERE category IN ('#{param[0]}') AND number=#{param[1]}"
    # console.log "https://#{user}.cartodb.com/api/v2/sql?q=#{lookup_sql}&api_key=#{api_key}"
    lookup_features = []
    request {
          method: 'GET'
          url: "https://#{user}.cartodb.com/api/v2/sql?q=#{lookup_sql}&api_key=#{api_key}"
          json: true
        }, (error, lookup_response, lookup_body) =>
          console.log lookup_body.rows
          if !error and lookup_response.statusCode == 200
            # console.log body
            # console.log body.rows.length
            for each in lookup_body.rows
              lookup_features.push 
                "location_number": +each.number
                "time_in_seconds": each.time_in_seconds
                "category": each.category
              
            res.send lookup_features
            # @emit 'radarResponds', body.results

app.get '/categoryby/:station', (req, res) =>
    lookup_features = []
    request {
          method: 'GET'
          url: "https://#{user}.cartodb.com/api/v2/sql?q=#{lookup_sql}&api_key=#{api_key}"
          json: true
        }, (error, lookup_response, lookup_body) =>
          console.log lookup_body.rows
          if !error and lookup_response.statusCode == 200
            # console.log body
            # console.log body.rows.length
            for each in lookup_body.rows
              lookup_features.push 
                "location_number": +each.number
                "time_in_seconds": each.time_in_seconds
                "category": each.category
              
            res.send lookup_features
            # @emit 'radarResponds', body.results
  



app.get '/data', (req, res) =>
    geores = {
      "type": "FeatureCollection"
      "features": []
    }
    request {
          method: 'GET'
          url: "https://#{user}.cartodb.com/api/v2/sql?q=#{sql}&api_key=#{api_key}"
          json: true
        }, (error, response, body) =>
          if !error and response.statusCode == 200
            # console.log body
            # console.log body.rows.length
            for each in body.rows
              geores.features.push 
                "type": "Feature"
                "geometry": 
                  "type": "Point"
                  "coordinates": [each.longitude, each.latitude]
                
                "properties": 
                  "sound": each.sound
                  "file": each.file
                  "location_number": each.location_number
                
  

            res.send geores
            # @emit 'radarResponds', body.results
  


app.get '/', (req, res) ->
  # res.status(200).send("Hello, world!");
  res.render 'index', (err, html) ->
    res.send html
    return
  # res.sendfile('./bower_components/shower-bright/index.html');
  return
# [END hello_world]
# [START server]

### Start the server ###

server = app.listen(process.env.PORT or '8080', '0.0.0.0', ->
  console.log 'App listening at http://%s:%s', server.address().address, server.address().port
  console.log 'Press Ctrl+C to quit.'
  console.log 'checking if adjustments work'
  return
)
