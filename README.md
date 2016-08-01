

The monitoring infrastructure consists of several components, wrapped in docker containers:
 * `metrics-server` - collects and stores metrics
 * `tessera` - dashboard server ([project page](https://github.com/urbanairship/tessera)), connecting to graphite server inside `metrics-server`
 * `riemann-dash` - dashboard server ([project page](http://riemann.io/dashboard.html)), connecting to riemann inside `metrics-server`

You can but don't have to start all dashboards, you can pick the one you prefer.

## Metrics server

To start the container, run:

```
sudo docker run -d \
	-p 5556:5556 \
	-p 25826:25826/udp \
	-p 8080:80 \
	-it scylladb/scylla-monitoring:metrics-server
```

The following ports are exposed:

 port | service
 ---- | ----
 5556/tcp | riemann
 25826/udp | collectd
 8080/tcp | graphite web GUI

You can enable Scylla to write metrics to it using command line arguments like this:

```
scylla --collectd=1 --collectd-address=127.0.0.1:25826

```

The data flow between components is as follows:

```
   -> collectd -> riemann -> graphite
```

riemann is configured to aggregate Seastar and Scylla metrics. The naming convention for aggregated metrics is:
 * for sharded metrics: `{plugin}-{instance}/{type}-{name}` -> `{plugin}/{type}-{name}`
 * for aggregating metrics from all hosts: `{plugin}/{type}-{name}` -> `{plugin}/{type}-total_{name}`

Not all metrics are being aggregated yet. For the full list see [metrics-server/riemann.config](metrics-server/riemann.config).

Examples of aggregated metrics:
 * `reactor/gauge-load` - average load for all shards
 * `transport/total_requests-requests_served` - requests_served summed up from all shards

Metrics are stored by graphite inside carbon and retained for 1 hour with 1 second precision.

When metric is exported to graphite its name is transformed:
 * `/` and ` ` is replaced with `.`
 * host name is prepended and separated with `.`

So `reactor/gauge-load` on localhost becomes `localhost.reactor.gauge-load` in graphite.

## Collecting system metrics

It is often useful to also monitor utilization of disk, network card, etc. To do so you can start a `collectd` daemon on the machine on which you start Scylla. Here's an example configuration (typically located in `/etc/collectd/collectd.conf`):

```
LoadPlugin network
LoadPlugin interface
LoadPlugin netlink
LoadPlugin exec
LoadPlugin disk
LoadPlugin vmem
LoadPlugin memory
LoadPlugin cpu

Interval 1

Hostname n1

<Plugin "network">
    Listen "127.0.0.1" "25826"
    Server "$metrics-server-ip" "25826"
    Forward true
</Plugin>
```

The configuration above will write to collectd inside `metrics-server`. In place of `$metrics-server-ip` enter the IP on which metrics-server is listening.

Note: the `netlink` plugin comes from an optional package, you need to install it first. On Fedora that's `yum install collectd-netlink`.

All metrics will be available to your dashboard servers.

Example riemann metrics:

 * `disk-sda/disk_octets/read`
 * `disk-sda/disk_octets/write`
 * `netlink-int0/if_octets/rx`
 * `netlink-int0/if_octets/tx`

Note: Currently the built-in dashboards are configured to show `sda` disk and `int0` NIC, you will have to edit dashboard definitions to show different devices.

# Tessera dashboard

To start it, run:

```
sudo docker run -d \
    -p 8081:80 \
    -e GRAPHITE_URL=http://127.0.0.1:8080 \
    -it scylladb/scylla-monitoring:tessera
```

The command above, when setting GRAPHITE_URL, assumes that the graphite web server
from `metrics-server` is available on local port `80`. Note that the host name
must be reachable from your browser, not just the machine on which you run
tessera.

After staring the container, you can navigate to [http://localhost:8081/](http://localhost:8081/) in your browser.

The image is equipped with a pre-configured dashboard for monitoring Scylla: [http://localhost:8081/dashboards/12/scylla](http://localhost:8081/dashboards/12/scylla).

To save dashboard definition to a file after making changes to it, use the RESTful API. For example, to save dashboard with id `13` to `tessera/dashboards/scylla-dashboard.json` run:

```
curl --get -d 'definition=true' http://127.0.0.1:8081/api/dashboard/13 > tessera/dashboards/scylla-dashboard.json
```

For more info on using tessera check [here](http://urbanairship.github.io/tessera/docs/).

## Riemann dashboard

To start it, run:

```
sudo docker run -d -p 4567:4567 -it scylladb/scylla-monitoring:riemann-dash
```

Then navigate to [http://localhost:4567/](http://localhost:4567/) in your browser. You will find several pre-configured dashboards there.

Note that the GUI by default tries to connect to riemann (from `metrics-server`) on `127.0.0.1:5556`. This address must be reachable from your browser.

For more information on riemann-dashboard check [here](http://riemann.io/dashboard.html).

## Which dashboard to choose

Each dashboard has some strong and weak points. Here are some hints on which one fits your purpose best.

Tessera connects to graphite to get data, so it's able to show historical data. Riemann dashboard works on current event stream, so it will show only data it received since the dashboard was switched on.

Tessera updates graphs every minute by default. The period can be lowered to 30 seconds, but not less. Riemann dashboard updates graphs every second, so it's more convenient for ad-hoc monitoring in real-time.

Tessera dashboards are interactive, you can hover over the graph and get precise metric values for given time point. You can't do that in riemann-dash.

Tessera graphs are adjusting units on the scale according to the range shown (eg. 1G instead of 1000000000), riemann-dash doesn't do that.

## Starting all images at once

To start all containers locally, just run [./start-all-local.sh](./start-all-local.sh).
To start all containers on EC2, use  [./start-all-ec2.sh](./start-all-ec2.sh).

## Building images

To build docker images run:

```
make
```
