all: tessera riemann-dash metrics-server
.PHONY: all

metrics-server:
	sudo docker build -t scylladb/scylla-monitoring:metrics-server metrics-server
.PHONY: metrics-server

tessera:
	sudo docker build -t scylladb/scylla-monitoring:tessera tessera
.PHONY: tessera

riemann-dash:
	sudo docker build -t scylladb/scylla-monitoring:riemann-dash riemann-dash
.PHONY: riemann-dash
