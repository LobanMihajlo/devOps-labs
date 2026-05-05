FROM node:20-alpine

WORKDIR /usr/src/app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

RUN mkdir -p /etc/mywebapp
COPY config/config.json /etc/mywebapp/config.json

COPY src ./src

ENV NODE_ENV=production

EXPOSE 5000

CMD ["node", "src/app.js"]