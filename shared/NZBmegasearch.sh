#! /bin/sh

QPKG_NAME=NZBmegasearch
QPKG_DIR=$(/sbin/getcfg $QPKG_NAME Install_Path -f /etc/config/qpkg.conf)
#PID_FILE="$QPKG_DIR/config/couchpotato.pid"
DAEMON=/usr/bin/python2.7
DAEMON_OPTS="mega2.py daemon"
export PATH=/Apps/bin:/usr/local/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export PYTHONPATH=$QPKG_DIR/Repository/lib/python

CheckQpkgEnabled() { #Is the QPKG enabled? if not exit the script 
	if [ $(/sbin/getcfg ${QPKG_NAME} Enable -u -d FALSE -f /etc/config/qpkg.conf) = UNKNOWN ]; then
  	  	/sbin/setcfg ${QPKG_NAME} Enable TRUE -f /etc/config/qpkg.conf
	elif [ $(/sbin/getcfg ${QPKG_NAME} Enable -u -d FALSE -f /etc/config/qpkg.conf) != TRUE ]; then
	  	/bin/echo "${QPKG_NAME} is disabled."
	  	exit 1
	fi
	if [ `/sbin/getcfg "git" Enable -u -d FALSE -f /etc/config/qpkg.conf` = UNKNOWN ]; then
		/sbin/setcfg "git" Enable TRUE -f /etc/config/qpkg.conf
	elif [ `/sbin/getcfg "git" Enable -u -d FALSE -f /etc/config/qpkg.conf` != TRUE ]; then
		echo "git is disabled."
		exit 1
	fi
	if [ `/sbin/getcfg "Python" Enable -u -d FALSE -f /etc/config/qpkg.conf` = UNKNOWN ]; then
		/sbin/setcfg "Python" Enable TRUE -f /etc/config/qpkg.conf
	elif [ `/sbin/getcfg "Python" Enable -u -d FALSE -f /etc/config/qpkg.conf` != TRUE ]; then
		echo "Python is disabled."
		exit 1
	fi
	[ -x /Apps/bin/git ] || /etc/init.d/git.sh restart && sleep 2
	[ -x $DAEMON ] || /etc/init.d/python.sh restart && sleep 2
}

ConfigPython(){ #checks if the daemon exists and will link /usr/bin/python to it
	#python dependency checking
	if [ ! -x $DAEMON ]; then
		/sbin/write_log "Failed to start $QPKG_NAME, $DAEMON was not found. Please re-install the Pythton qpkg." 1 
		exit 1
	fi
       if /bin/uname -m | grep "armv7l"; then
		PY_DIR=$(/sbin/getcfg Python Install_Path -f /etc/config/qpkg.conf)
		[ -f ${PY_DIR}/lib/python2.7/lib-dynload/_ctypes.so ] || cp $QPKG_DIR/x31-lib/_ctypes.so ${PY_DIR}/lib/python2.7/lib-dynload/_ctypes.so
		[ -f ${PY_DIR}/lib/python2.7/lib-dynload/_sqlite3.so ] || cp $QPKG_DIR/x31-lib/_sqlite3.so ${PY_DIR}/lib/python2.7/lib-dynload/_sqlite3.so
		[ -f ${PY_DIR}/lib/python2.7/lib-dynload/_ssl.so ] || cp $QPKG_DIR/x31-lib/_ssl.so ${PY_DIR}/lib/python2.7/lib-dynload/_ssl.so
		[ -f ${PY_DIR}/lib/python2.7/lib-dynload/zlib.so ] || cp $$QPKG_DIR/x31-lib/zlib.so ${PY_DIR}/lib/python2.7/lib-dynload/zlib.so
	fi
}

StartQpkg(){
	/bin/echo "Starting $QPKG_NAME"
	cd $QPKG_DIR/$QPKG_NAME
	PATH=${PATH} ${DAEMON} ${DAEMON_OPTS}
}

ShutdownQPKG() { #kills a proces based on a PID in a given PID file
echo "TBD"
}

case "$1" in
  start)
	CheckQpkgEnabled #Check if the QPKG is enabled, else exit 
	/bin/echo "$QPKG_NAME prestartup checks..."
	ConfigPython	 #Check for Python, exit if not found
	StartQpkg		 #Finally Start the qpkg
	
	;;
  stop)
  	ShutdownQPKG
	;;
  restart)
	echo "Restarting $QPKG_NAME"
	$0 stop 
	$0 start
	;;
  *)
	N=/etc/init.d/$QPKG_NAME.sh
	echo "Usage: $N {start|stop|restart}" >&2
	exit 1
	;;
esac
