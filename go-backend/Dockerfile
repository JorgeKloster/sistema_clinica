FROM golang:1.27.1

WORKDIR /app

COPY go.mod ./
COPY main.go ./

RUN go mod tidy
RUN go build -o backend main.go

CMD ["./backend"]