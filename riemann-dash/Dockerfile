From debian

RUN apt-get update \
	&& apt-get install -y ruby1.9.1 \
	&& gem install riemann-dash -v 0.2.12

COPY config.json /var/lib/gems/2.1.0/gems/riemann-dash-0.2.12/config/config.json
COPY config.rb /etc/riemann-dash-config.rb

EXPOSE 4567

CMD riemann-dash /etc/riemann-dash-config.rb
