FROM golang:1.27.1

WORKDIR /app

# Copy go.mod and go.sum first for dependency resolution
COPY go.mod go.sum ./
RUN go mod tidy

# Copy the rest of the source code
COPY . .

# Build the backend
RUN go build -o backend main.go

CMD ["./backend"]