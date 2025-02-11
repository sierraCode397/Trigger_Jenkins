FROM node:7.8.0

WORKDIR /opt

# Use COPY instead of ADD
COPY . /opt

RUN npm install

# Use JSON format for ENTRYPOINT and CMD
ENTRYPOINT ["npm", "run", "start"]

