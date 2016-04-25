# This is based off of google's nodejs runtime examples
# armin.akhavan@gmail.com
# [START docker]
FROM gcr.io/google_appengine/nodejs
# ADD package.json npm-shrinkwrap.json* /app/
# RUN npm --unsafe-perm install
ADD . /app
WORKDIR /app
ADD package.json /usr/app/package.json
ADD bower.json /usr/app/bower.json
ADD lib/script.js /usr/app/lib/script.js
ADD lib/howler.js /usr/app/lib/howler.js
ADD lib/grid.css /usr/app/lib/grid.css
ADD lib/fonts /usr/app/lib/fonts
ADD lib /usr/app/lib
ADD lib /usr/app/bower_components
Add lib /usr/app/node_modules
ADD sounds /usr/app/sounds
ADD server.js /usr/app/server.js
ADD index.html /usr/app/index.html
ADD app.yaml /usr/app/app.yaml
EXPOSE 8080
# [END docker]