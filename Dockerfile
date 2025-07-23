#Yes, the requirement that all files or artifacts you want to include in your Docker image 
#must be inside the Docker build context applies equally to all project types and languages. 
#This rule is an architectural part of how Docker builds work and isn't specific to Java, .NET,
#Node.js, Python, Go, or any other stack.


# adservice Microservice 
# Use a secure and minimal Java 21 runtime image

FROM eclipse-temurin:21.0.5_11-jre-alpine@sha256:4300bfe1e11f3dfc3e3512f39939f9093cf18d0e581d1ab1ccd0512f32fe33f0

LABEL service="adservice" \
      maintainer="prasannakumarsinganamalla@gmail.com" \
      description="AdService microservice container"

WORKDIR /home/adservice
USER nonroot

# Copy the JAR from the local build output to the image
COPY build/libs/hipstershop-0.1.0-SNAPSHOT.jar .

EXPOSE 9555

ENTRYPOINT ["java", "-jar", "hipstershop-0.1.0-SNAPSHOT.jar"]


#------------------------------------------------------------------------------------------------------------
# Cartservice

# Use ASP.NET runtime base image (for web apps)
FROM mcr.microsoft.com/dotnet/aspnet:9.0

WORKDIR /app
EXPOSE 7070
ENV ASPNETCORE_HTTP_PORTS=7070

# Copy the output from build stage (assuming this includes the published binary)
COPY cartservice_build .

# Run the app using the binary name
ENTRYPOINT ["/app/cartservice"]




    
#------------------------------------------------------------------------------------------------------------
# Docker file checkoutservice 
# Dockerfile

FROM golang:1.23.4-alpine 

# Set the working directory inside the container.
WORKDIR /app

COPY checkoutservice_build /app/checkoutservice

ENV GOTRACEBACK=single

# Expose the port your application listens on.
EXPOSE 5050

# Define the command to run when the container starts.
ENTRYPOINT ["/app/checkoutservice"]

#-----------------------------------------------------------------------------------------------------------
# frontend service

# Dockerfile

# --- Build Stage ---
# Use a Go SDK image to compile the application.
# golang:1.23.4-alpine is lightweight and suitable for compilation.
FROM golang:1.23.4-alpine


WORKDIR /app

COPY frontend_build  /app/server

COPY ./templates ./templates
COPY ./static ./static

# Set a Go runtime environment variable for stack traces on panic.
ENV GOTRACEBACK=single

# Expose the port your application listens on.
EXPOSE 8080

# Define the command to run when the container starts.
ENTRYPOINT ["/app/server"]

#-----------------------------------------------------------------------------------------------------------
# shippingservice


# Dockerfile

# --- Build Stage ---
# Use a Go SDK image to compile the application.
# golang:1.23.4-alpine is lightweight and suitable for compilation.
FROM golang:1.23.4-alpine

# Set the working directory inside the container.
WORKDIR /app

# Copy the compiled executable from the builder stage into the final image.
# The executable is named 'shippingservice' and will be placed at /app/shippingservice in the final image.
COPY shippingservice_build  /app/shippingservice

# Set an environment variable for the application's port.
ENV APP_PORT=50051

# Set a Go runtime environment variable for stack traces on panic.
ENV GOTRACEBACK=single

# Expose the port your application listens on.
EXPOSE 50051

# Define the command to run when the container starts.
ENTRYPOINT ["/app/shippingservice"]

#-----------------------------------------------------------------------------------------------------------
# productcatalogservice

# Dockerfile

# --- Build Stage ---
# Use a Go SDK image to compile the application.
# golang:1.23.4-alpine is lightweight and suitable for compilation.
FROM golang:1.23.4-alpine

WORKDIR /app

COPY productcatalogservice_build  /app/server

COPY products.json ./products.json

# Set a Go runtime environment variable for stack traces on panic.
ENV GOTRACEBACK=single

# Expose the port your application listens on.
EXPOSE 3550

# Define the command to run when the container starts.
ENTRYPOINT ["/app/server"]

#-----------------------------------------------------------------------------------------------------------
# currencyservice
FROM node:20.18.1-alpine

WORKDIR /app

# Copy pre-installed node_modules from artifact
COPY src/currencyservice/node_modules ./node_modules

# Copy the rest of your app code
COPY . .

EXPOSE 7000

ENTRYPOINT ["node", "server.js"]

#-----------------------------------------------------------------------------------------------------------
# paymentservice

FROM node:20.18.1-alpine

WORKDIR /app

# Copy pre-installed node_modules from artifact
COPY src/paymentservice/node_modules ./node_modules

# Copy the rest of your app code
COPY . .

EXPOSE 50051

ENTRYPOINT ["node", "index.js"]
#-----------------------------------------------------------------------------------------------------------
# emailservice
FROM python:3.11-alpine

LABEL service="emailservice"

WORKDIR /app

COPY src/emailservice/.venv /app/.venv
COPY . .

ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

EXPOSE 8080
ENTRYPOINT ["python", "email_server.py"]

#-----------------------------------------------------------------------------------------------------------
# recommendationservice

FROM python:3.11-alpine

LABEL service="recommendationservice"

WORKDIR /app

COPY src/recommendationservice/.venv /app/.venv
COPY . .

ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

EXPOSE 8080
ENTRYPOINT ["python", "recommendation_server.py"]


# shoppingassistantservice - Lightweight Python container using prebuilt .venv

FROM python:3.12.8-slim@sha256:123be5684f39d8476e64f47a5fddf38f5e9d839baff5c023c815ae5bdfae0df7

LABEL service="shoppingassistantservice"

WORKDIR /app

# Copy virtual environment built in CI
COPY src/shoppingassistantservice/.venv /app/.venv

# Copy application code
COPY . .

# Activate the virtualenv by updating PATH
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Set port and expose
ENV PORT=8080
EXPOSE 8080

# Start the application
ENTRYPOINT ["python", "shoppingassistantservice.py"]



#-----------------------------------------------------------------------------------------------------------
      # Loadgenrator service

FROM python:3.12.8-alpine@sha256:54bec49592c8455de8d5983d984efff76b6417a6af9b5dcc8d0237bf6ad3bd20 AS base

FROM base AS builder

RUN apk update \
    && apk add --no-cache wget g++ linux-headers \
    && rm -rf /var/cache/apk/*

COPY requirements.txt .

RUN pip install --prefix="/install" -r requirements.txt

FROM base

RUN apk update \
    && apk add --no-cache libstdc++ \
    && rm -rf /var/cache/apk/*

WORKDIR /loadgen

COPY --from=builder /install /usr/local

# Add application code.
COPY locustfile.py .

# enable gevent support in debugger
ENV GEVENT_SUPPORT=True

ENTRYPOINT locust --host="http://${FRONTEND_ADDR}" --headless -u "${USERS:-10}" -r "${RATE:-1}" 2>&1