FROM node:18-alpine

WORKDIR /app
RUN apk update && apk add git
RUN git clone https://github.com/docker/getting-started-app.git

WORKDIR /app/getting-started-app
RUN yarn install --production

CMD ["node", "src/index.js"]
EXPOSE 3000