

The monitoring infrastructure consists of several components, wrapped in docker containers:
 * `metrics-server` - collects and stores metrics
 * `tessera` - dashboard server ([project page](https://github.com/urbanairship/tessera)), connecting to graphite server inside `metrics-server`
 * `riemann-dash` - dashboard server, connecting to riemann inside `metrics-server`

## Metrics server

The `metrics-server` image contains collectd, riemann and graphite. The data flow looks like this:

```
   -> collectd -> riemann -> graphite
```

riemann is configured to aggregate Seastar and Scylla metrics. The naming convention for aggregated metrics is:
 * for sharded metrics: `{plugin}-{instance}/{type}-{name}` -> `{plugin}/{type}-{name}`
 * for aggregating metrics from all hosts: `{plugin}/{type}-{name}` -> `{plugin}/{type}-total_{name}`

Not all metrics are being aggregated yet. For the full list see [metrics-server/riemann.config].

Examples of aggregated metrics:
 * `reactor/gauge-load` - average load for all shards
 * `transport/total_requests-requests_served` - requests_served summed up from all shards
 
The metrics are stored by graphite inside carbon and retained for 1 hour with 1 second precision. 

To start `metrics-server` container, run:

```
sudo docker run -d \
	-p 5556:5556 \
	-p 25826:25826/udp \
	-p 80:80 \
	-it scylladb/metrics-server
```

The following ports are exposed:

 port | service
 ---- | ----
 5556/tcp | riemann
 25826/udp | collectd
 80/tcp | graphite web GUI

You can enable Scylla to write metrics to it using command line arguments like this:

```
scylla --collectd=1 --collectd-address=127.0.0.1:25826

```

# Tessera dashboard

To start it, run:

```
sudo docker run -d \
    -p 8081:80 \
    -e GRAPHITE_URL=http://127.0.0.1:80 \
    -it scylladb/tessera
```

The command above, when setting GRAPHITE_URL, assumes that the graphite web
from `metrics-server` is available on local port `80`. Note that the host name
must be reachable from your browser, not just the machine on which you run
tessera.

After staring the container, you can navigate to [http://localhost:8081/] in your browser.

The image is equipped with a pre-configured dashboard for monitoring Scylla: [http://localhost:8081/dashboards/12/scylla].

For more info on using tessera check [here](http://urbanairship.github.io/tessera/docs/).

## Riemann dashboard

To start it, run:

```
sudo docker run -d -p 4567:4567 -it scylladb/riemann-dash
```

Then navigate to [http://localhost:4567/] in your browser. You will find several pre-configured dashboards there.

Note that the GUI by defaulut tries to connect to riemann (from `metrics-server`) on 127.0.0.1:5556. This address must be reachable from your browser.

For more information on riemann-dashboard check [here](http://riemann.io/dashboard.html).

## Which dashboard to choose

Each dashboard has some strong and weak points. Here are some hints on which one fits your purpose best.

Tessera connects to graphite to get data, so it's able to show historical data. Riemann dashboard works on current event stream, so it will show only data it received since the dashboard was switched on.

Tessera updates graphs every minute by default. The period can be lowered to 30 seconds, but not less. Riemann dashboard updates graphs every second, so it's better for ad-hoc real-time monitoring.

Tessera dashboards are interactive, you can hover over the graph and get precise metric values for given time point. You can't do that in riemann-dash.

Tessera graphs are adjusting units on the scale according to the range shown (eg. 1G instead of 1000000000), riemann-dash doesn't do that.

## Starting all images at once

To start all containers locally, just run [./start-all.sh].

## Building images

To build docker images run:

```
make all
```
