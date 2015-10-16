all: tessera riemann-dash metrics-server
.PHONY: all

metrics-server:
	sudo docker build -t scylladb/metrics-server metrics-server
.PHONY: metrics-server

tessera:
	sudo docker build -t scylladb/tessera tessera
.PHONY: tessera

riemann-dash:
	sudo docker build -t scylladb/riemann-dash riemann-dash
.PHONY: riemann-dash
