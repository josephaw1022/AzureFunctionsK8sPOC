# Azure Functions with Kubernetes and KEDA: A Quickstart Guide

This repository provides a quickstart guide on how to deploy an Azure Function locally within a Kubernetes cluster using Docker and KEDA. The aim is to demonstrate a simple proof of concept, showing how an Azure Function can be scaled based on the results of our keda scalers. This one being the results of a sql server query.

## 🎥 **Video Walkthrough**
For a comprehensive visual walkthrough and a working demo of this repo, check out my [Local Demo On Youtube](https://youtu.be/4NpJ7j_u1N0).

## 🚀 **Key Takeaways**:

- **Open-Source Power**: Azure Functions are open-sourced, highlighting Microsoft's commitment to community-driven development and transparency.

- **Containerized Flexibility**: This repository leverages Docker to run Azure Functions, illustrating the portability and ease of deployment of serverless applications in containerized environments.

- **Universal Scaling with KEDA**: KEDA scalers are not restricted to Azure. Whether your infrastructure is on-premises, AWS, GCP, or any environment with a Kubernetes cluster, KEDA will seamlessly integrate.

- **CNCF Seal of Approval**: KEDA has moved to the Graduated maturity level by the Cloud Native Computing Foundation (CNCF) on August 22, 2023, underlining its reliability, robustness, and the industry's confidence in its capabilities.

- **Local Simulations**: Demonstrating the feasibility of simulating a KEDA-based scaling workflow right on your local machine, removing the need for complex cloud-based setups for development testing.

- **Metric Versatility with KEDA**: While this demo emphasizes SQL Server query results, KEDA's scalers can be configured for various metrics: CPU usage of pods, Prometheus query results, memory consumption, queue lengths, cron jobs, and more.

- **End-to-End Control**: Realize the unmatched power and control KEDA and Azure Functions offer over the scaling and performance of your serverless applications.

By integrating these points, readers can quickly grasp the vast potential and flexibility provided by Azure Functions and KEDA, regardless of the infrastructure they're working with.

## Overview

- **Azure Function with Docker**: The Azure Function in this repository is containerized using Docker, making it easy to run without needing additional installations.
  
- **Skaffold**: With just the `skaffold run` command, you can build, run, and deploy the app to a local Kubernetes cluster.
  
- **KEDA with SQL Server Trigger**: The scaling in this demonstration is based on a SQL Server trigger. The number of pods for our deployment will change based on the values we manually adjust in a specific database.

## Setup Instructions

1. **External Docker Network**:
    - If you haven't already, create an external network using:
      ```
      docker network create local
      ```
    - Having our registry in a common network allows us to have other compose files access our registry. This leads to extra flexibility and more capabilities like Docker in Docker based cicd workflows, however, that topic is way beyond the scope of this repo.

2. **Local Docker Registry**:
    - Start the local Docker registry:
      ```
      docker compose -f k8s/registry/docker-compose.yaml up -d
      ```

3. **Docker Image**:
    - Build and push the Docker image:
      ```
      docker compose build --push
      ```

4. **SQL Server with Helm**:
    - We've provided a Helm chart for SQL Server exposed via a headless service.
    - Set up the namespace and install the chart:
      ```
      cd k8s/sql-server
      kubectl create namespace az-local-functions-db
      helm install sql-server-release sql-server-chart -n az-local-functions-db
      cd ../..
      ```
    - To upgrade the chart later:
      ```
      helm upgrade sql-server-release sql-server-chart -n az-local-functions-db
      ```

5. **Database Setup**:
    - Forward the headless port using Rancher Desktop.
    - Manually access the SQL Server using tools like SSMS or Azure Data Studio.
    - Create a database named "az-sql-server-db" and execute the following SQL script to create the required table:
      ```sql
      SET ANSI_NULLS ON
      GO
      SET QUOTED_IDENTIFIER ON
      GO
      
      IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'keda-scaler-poc' AND schema_id = SCHEMA_ID('dbo'))
      BEGIN
          CREATE TABLE [dbo].[keda-scaler-poc](
              [name] [nvarchar](255) NULL,
              [scale] [int] NULL
          ) ON [PRIMARY]
      END
      GO

      ```

6. **Deploying the App with Skaffold**:
    - Use Skaffold to manage image building and Helm deployments:
      ```
      skaffold run
      ```
    
    - Go to [Azure Functio App Homepage](http://localhost:30002) or our [function's endpoint](http://localhost:30002/api/httptrigger1)

    - The Dockerfile for the Azure Function app can contain one or more functions. Here's a snapshot of the Dockerfile:
      ```Dockerfile
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
      ```
    - Use `skaffold deploy --images localhost:5000/myfunctionapp:latest` to perform the Helm release.
    - For continuous development, `skaffold dev` will trigger `skaffold run` every time there's a change to the Azure Function.

---

Happy coding and deploying!
