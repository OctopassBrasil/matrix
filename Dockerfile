FROM node:18-alpine AS build

# Diretório de trabalho
WORKDIR /var/app

# Copia o projeto
COPY . .

# Instala dependências raiz e de workspaces (se monorepo)
RUN npm install --ignore-scripts

# Bootstrapa monorepo (se Lerna ou equivalente)
RUN npm run bootstrap || true

# Build frontend e backend
RUN npm run build-frontend
RUN npm run build-backend

# ---- Imagem final (produção) ----
FROM node:18-alpine

WORKDIR /var/app

# Copia apenas o necessário da imagem de build
COPY --from=build /var/app/backend/dist ./backend/dist
COPY --from=build /var/app/backend/package*.json ./backend/
COPY --from=build /docker-entrypoint.sh /docker-entrypoint.sh

# Instala apenas dependências de produção do backend
WORKDIR /var/app/backend
RUN npm install --omit=dev

WORKDIR /var/app

# Expõe porta da aplicação
EXPOSE 8080

ENTRYPOINT ["sh", "/docker-entrypoint.sh"]
CMD ["npm", "--prefix", "backend/", "run", "start-backend"]

