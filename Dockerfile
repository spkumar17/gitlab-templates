
# adservice Microservice 

FROM gcr.io/distroless/java21-debian11

LABEL service="adservice" \
      maintainer="prasannakumarsinganamalla@gmail.com" \
      description="AdService microservice container"

WORKDIR /home/adservice
USER nonroot

COPY build/libs/app.jar .
EXPOSE 9555

ENTRYPOINT ["java", "-jar", "app.jar"]
#------------------------------------------------------------------------------------------------------------
# Cart serivce

# Use ASP.NET runtime base image (for web apps)
FROM mcr.microsoft.com/dotnet/aspnet:9.0


WORKDIR /app
EXPOSE 7070
ENV ASPNETCORE_HTTP_PORTS=7070
# If you don’t set ASPNETCORE_HTTP_PORTS, your app defaults to port 5000, 
# so exposing another port (like 7070) won’t work unless configured via ASPNETCORE_URLS or other means.

# Copy the output from build stage
COPY Cartserivce_build .

# Run the app
ENTRYPOINT ["dotnet", "MyApp.dll"]



    
#------------------------------------------------------------------------------------------------------------
# Docker file checkoutservice 
# Dockerfile

FROM golang:1.23.4-alpine 

# Set the working directory inside the container.
WORKDIR /app

COPY checkoutservice_build  /app/checkoutservice

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
COPY node_modules ./node_modules

# Copy the rest of your app code
COPY . .

EXPOSE 7000

ENTRYPOINT ["node", "server.js"]

#-----------------------------------------------------------------------------------------------------------
# paymentservice

FROM node:20.18.1-alpine

WORKDIR /app

# Copy pre-installed node_modules from artifact
COPY node_modules ./node_modules

# Copy the rest of your app code
COPY . .

EXPOSE 50051

ENTRYPOINT ["node", "index.js"]
#-----------------------------------------------------------------------------------------------------------
# emailservice

# Final image using Alpine and prebuilt .venv
FROM python:3.11-alpine

LABEL service="emailservice"

WORKDIR /app

# Copy project files and the virtual environment
COPY .venv /app/.venv
COPY . .

# Activate the venv by adding it to PATH
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

EXPOSE 8080
ENTRYPOINT ["python", "email_server.py"]


# -----------------------------------------------------------------------------------------------------------
# recommendationservice
# Final image using Alpine and prebuilt .venv
FROM python:3.11-alpine

LABEL service="recommendationservice"
WORKDIR /app

# Copy project files and the virtual environment
COPY .venv /app/.venv
COPY . .

# Activate the venv by adding it to PATH
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# set listen port
ENV PORT "8080"
EXPOSE 8080

ENTRYPOINT ["python", "recommendation_server.py"]


#-----------------------------------------------------------------------------------------------------------
      # Loadgenrator service

FROM --platform=$BUILDPLATFORM python:3.12.8-alpine@sha256:54bec49592c8455de8d5983d984efff76b6417a6af9b5dcc8d0237bf6ad3bd20 AS base

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