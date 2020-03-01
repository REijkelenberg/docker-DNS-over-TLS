FROM nginx:mainline-alpine

# ENV variables
#	Note: /etc/letsencrypt/live is the default location for LetsEncrypt certificates
ENV DNS_UPSTREAM_ADDRESS	"127.0.0.1"
ENV DNS_UPSTREAM_PORT	"53"
ENV FIRST_RUN_AUTO_INIT	"true"
ENV TLS_CERTIFICATE		""
ENV TLS_CERTIFICATE_KEY	""

# Run everything as root (in-sofar by default this is not the case)
USER root

# Update the system and install required packages
RUN apk update \
	&& apk upgrade
	
# Add config files to the container
ADD nginx/streams.conf /etc/nginx/streams/dns-over-tls
ADD nginx/nginx-conf-addition.conf /build-files/nginx-conf-addition.conf

# Set up config files
RUN cat /build-files/nginx-conf-addition.conf >> /etc/nginx/nginx.conf \
	&& rm -rf /build-files \
	&& touch /first_run.txt

# Expose the default DoT port
EXPOSE 853

# Install the script responsible for 'starting' the container
ADD start.sh /
RUN chmod +x /start.sh
CMD ["/start.sh"]
