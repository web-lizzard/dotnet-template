FROM mcr.microsoft.com/dotnet/sdk:8.0 AS core

WORKDIR /app

COPY app.sln ./

COPY src/Adapters/Adapters.csproj ./src/Adapters/Adapters.csproj
COPY src/Application/Application.csproj ./src/Application/Application.csproj
COPY src/Domain/Domain.csproj ./src/Domain/Domain.csproj
COPY src/Entrypoint/Entrypoint.csproj ./src/Entrypoint/Entrypoint.csproj

COPY tests/Unit/Unit.csproj ./tests/Unit/Unit.csproj

RUN dotnet restore 

FROM core as dev

RUN dotnet tool install --global dotnet-ef
ENV PATH="$PATH:/root/.dotnet/tools"

ENTRYPOINT ["dotnet", "watch", "--project", "src/Entrypoint/Entrypoint.csproj", "run", "--urls", "http://0.0.0.0:80"]

FROM core as build-prod

COPY . ./

RUN dotnet build Entrypoint.sln -c Release --no-restore

RUN dotnet publish ./src/Entrypoint.Api/Entrypoint.csproj -c Release -o /app/out --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime

WORKDIR /app

COPY --from=build-prod /app/out ./

CMD [ "dotnet", "Entrypoint.Api.dll", "--urls", "http://0.0.0.0:80"]