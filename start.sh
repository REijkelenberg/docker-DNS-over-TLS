#!/bin/sh
# License and info: https://github.com/REijkelenberg/docker-DNS-over-TLS
# This script initialises the DoT Docker container if required, and starts nginx running in the foreground  

echo "Container is starting..."
echo "Image version: $IMAGE_VERSION\nBuild date: $BUILD_DATE"

# Initialise nginx on first run
if [ -f /first_run.txt ] && [ "$FIRST_RUN_AUTO_INIT" == "true" ]
then
    echo "Starting initialisation of container for first run..."
    
    # Check if TLS certificate (key) path has been set
    if [ -z "$TLS_CERTIFICATE" ] || [ -z "$TLS_CERTIFICATE_KEY" ]
    then
        echo "TLS_CERTIFICATE and/or TLS_CERTIFICATE_KEY variables have not been set. Please provide a path to your TLS certificate and its corresponding key."
        echo "A valid TLS certficate is required for running this container. You can obtain one for free from e.g. LetsEncrypt."
        exit 1
    fi
    
    # Start the configuration of nginx
    echo "Updating nginx configuration..."
    
    # Point nginx to the correct upstream DNS server
    echo "Setting upstream DNS: $DNS_UPSTREAM_ADDRESS:$DNS_UPSTREAM_PORT"
    # Hard-coded modification of the second line of the config file. Perhaps it would be better to do this differently in a future version of this image.
	sed -i "2s/.*/    server    $DNS_UPSTREAM_ADDRESS:$DNS_UPSTREAM_PORT;/" /etc/nginx/streams/dns-over-tls
	if [ $? -ne 0 ]
	then
 		echo "Unable to update nginx configuration. Abort..."
  		exit 1
	fi
	
	# Use the correct SSL certificates
	#  Note: using | as delimiter because the default delimiter / is present in file paths
	echo "Configuring TLS..."
	sed -i "s|    ssl_certificate /path/to/fullchain.pem;|    ssl_certificate $TLS_CERTIFICATE;|g" /etc/nginx/streams/dns-over-tls
	sed -i "s|    ssl_certificate_key /path/to/privkey.pem;|    ssl_certificate_key $TLS_CERTIFICATE_KEY;|g" /etc/nginx/streams/dns-over-tls
	
	# Remove /first_run.txt
	rm /first_run.txt
	
	echo "\nInitialisation complete!"
    echo "Note: If you whish to manually make changes to the nginx config file or TLS certificates, it is now safe to do so."
fi

if [ "$FIRST_RUN_AUTO_INIT" == "false" ]
then
    echo "Skipped auto initialisation on first run."
    echo "If you whish to auto initialise the container, re-create it and set the variable FIRST_RUN_AUTO_INIT to true (string)."
    
    # Remove /first_run.txt
    rm /first_run.txt
fi

# Launch nginx
echo "Starting nginx..."
nginx -g 'daemon off;'
