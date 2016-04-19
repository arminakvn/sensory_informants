# This is based off of google's nodejs runtime examples
# armin.akhavan@gmail.com
# [START docker]
FROM gcr.io/google_appengine/nodejs
ADD package.json npm-shrinkwrap.json* /app/
RUN npm --unsafe-perm install
ADD . /app
WORKDIR /app
ADD package.json /usr/app/package.json
ADD bower.json /usr/app/bower.json
ADD lib /usr/app/lib
ADD sounds /usr/app/sounds
ADD server.js /usr/app/server.js
ADD index.html /usr/app/index.html
ADD app.yaml /usr/app/app.yaml
EXPOSE 8080
# [END docker]