# ==========================================
# Stage 1: Build
# ==========================================
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Download dependencies first
# This improves Docker layer caching
COPY go.mod ./

RUN go mod download

# Copy application source code
COPY . .

# Build the Go application
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o go-app .


# ==========================================
# Stage 2: Runtime
# ==========================================
FROM alpine:3.22

WORKDIR /app

# Required for HTTPS communication
RUN apk add --no-cache ca-certificates

# Copy compiled Go binary
COPY --from=builder /app/go-app .

# Copy static files required by the application
COPY --from=builder /app/static ./static

# Application port
EXPOSE 8080

# Start application
CMD ["./go-app"]