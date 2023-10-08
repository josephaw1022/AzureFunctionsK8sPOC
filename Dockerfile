# Use the .NET 7 SDK as the base image
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build-env
WORKDIR /app

# Copy and restore the project
COPY *.csproj ./
RUN dotnet restore

# Copy the rest of the app and build
COPY . ./
RUN dotnet publish -c Release -o out

# Use the Azure Functions .NET base image
FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated7.0-slim AS runtime
ENV AzureWebJobsScriptRoot=/home/site/wwwroot
WORKDIR /home/site/wwwroot
COPY --from=build-env /app/out .