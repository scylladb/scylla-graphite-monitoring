FROM aalpern/tessera-simple

COPY dashboards dashboards

RUN invoke run & \
	sleep 1 && \
	inv json.import 'dashboards/*.json'
