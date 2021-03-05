#!/bin/bash

if [ "$(ls -A /var/www/html)" ]; then
	echo "The directory /var/www/html is non-empty. This is unexpected and dangerous for this container."
	echo "This container expects Wordpress (or the PHP app) at location '/wordpress' which will then be"
	echo "properly provided at /var/www/html either directly or polyscripted."
	echo ""
	echo "To avoid destroying your code, aboring this container."

	exit 1
else
	rm -rf /var/www/html
fi

if [[ "$MODE" == "polyscripted" || -f /polyscripted ]]; then

	echo "===================== POLYSCRIPTING ENABLED =========================="
	if [ -d /wordpress ]; then
	    echo "Copying /wordpress to /var/www/html to be polyscripted in place..."
	    echo "This will prevent changes from being saved back to /wordpress, but will protect"
	    echo "against code injection attacks..."
		cp -Rp /wordpress /var/www/temp
	fi

	echo "Starting polyscripted WordPress"
	cd $POLYSCRIPT_PATH
	sed -i "/#mod_allow/a \define( 'DISALLOW_FILE_MODS', true );" /var/www/html/wp-config.php
    	 ./build-scrambled.sh
	if [ -f scrambled.json ] && s_php tok-php-transformer.php -p /var/www/temp --replace; then
		rm -rf /var/www/html
		mv /var/www/temp /var/www/html
		echo "Polyscripting enabled."
		echo "done"
	else
		echo "Polyscripting failed."
		cp -p /usr/local/bin/s_php /usr/local/bin/php
		exit 1
	fi

	echo "Removing /var/www/html/wp-content/uploads (since it was deep-copied)..."
	echo "Don't worry it will be mounted properly in a moment."
	rm -rf /var/www/html/wp-content/uploads

else
    echo "Polyscripted mode is off. To enable it, either:"
    echo "  1. Set the environment variable: MODE=polyscripted"
    echo "  2. OR create a file at path: /polyscripted"

    if [ -d $POLYSCRIPT_PATH/vanilla-save ]; then
	    $POLYSCRIPT_PATH/reset.sh
    fi

    # Symlink the mount so it's editable
    ln -s /wordpress /var/www/html
fi

if [ -d /var/www/html/wp-content/uploads ]; then
	echo "Directory for uploads /var/www/html/wp-content/uploads exists. Doing nothing."
else
	echo "Directory for uploads /var/www/html/wp-content/uploads does not exist. Looking to mount it..."
	if [ -d /uploads ]; then
		echo "Uploads mounted at /uploads so symlinking that to /var/www/html/wp-content/uploads"
		ln -s /uploads /var/www/html/wp-content/uploads
	else
		if [ ! -d /wordpress/wp-content/uploads ]; then
			echo "Creating a directory for uploads at: /wordpress/wp-content/uploads"
			mkdir /wordpress/wp-content/uploads
		fi

		if [ -d /var/www/html/wp-content/uploads ]; then
			echo "/var/www/html/wp-content/uploads exists now."
			echo "/wordpress is probably already symlinked to /var/www/html (encapsulating /wordpress/wp-content/uploads with it)"
		else
			echo "Symlinking /wordpress/wp-content/uploads to /var/www/html/wp-content/uploads for persistent uploads"
			ln -s /wordpress/wp-content/uploads /var/www/html/wp-content/uploads
		fi

	fi
fi