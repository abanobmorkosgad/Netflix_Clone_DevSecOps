FROM node:16.17.0-alpine as builder
WORKDIR /app
COPY . .
RUN yarn install
ARG TMDB_V3_API_KEY   
#git_this_from_tmdb and pass_it_as_arg_while_Building
#sudo docker build --build-arg TMDB_V3_API_KEY=a20a396a2b4394f2565c4d934c628bc8 -t netflix .
ENV VITE_APP_TMDB_V3_API_KEY=${TMDB_V3_API_KEY}
ENV VITE_APP_API_ENDPOINT_URL="https://api.themoviedb.org/3"
RUN yarn build

FROM nginx:stable-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
ENTRYPOINT ["nginx", "-g", "daemon off;"]