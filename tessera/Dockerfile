FROM aalpern/tessera-simple

COPY dashboards dashboards

RUN . env/bin/activate && invoke run & \
	sleep 1 && \
	. env/bin/activate && inv json.import 'dashboards/*.json'
