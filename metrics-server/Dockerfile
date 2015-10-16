FROM hopsoft/graphite-statsd

### Graphite ###

COPY graphite/conf /opt/graphite/conf/

### Riemann ###

RUN apt-get update && apt-get install -y \
	bzip2 \
	collectd \
	collectd-core \
	default-jre \
	tar \
	wget

RUN wget -N https://aphyr.com/riemann/riemann-0.2.10.tar.bz2 \
	&& tar xfj riemann-0.2.10.tar.bz2 \
	&& rm -rf riemann-0.2.10.tar.bz2

COPY riemann.config riemann-0.2.10/etc/riemann.config
COPY collectd.conf /etc/collectd/collectd.conf

EXPOSE 5556 25826 2003/udp

CMD collectd -C /etc/collectd/collectd.conf & /sbin/my_init & ./riemann-0.2.10/bin/riemann
