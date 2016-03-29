HD_SERIAL=`wget -O - http://$IMAGING_SERVER:$IMAGING_PORT/api/helpdesk/serial_number?mac=$ETHERNET_MAC 2> /dev/null`
HD_WIRELESS=`wget -O - http://$IMAGING_SERVER:$IMAGING_PORT/api/helpdesk/wireless_mac?mac=$ETHERNET_MAC 2> /dev/null`
HD_ETHERNET=`wget -O - http://$IMAGING_SERVER:$IMAGING_PORT/api/helpdesk/ethernet_mac?mac=$ETHERNET_MAC 2> /dev/null`

if [ ! "$HD_SERIAL" = "$SERIAL" ]; then
	echo "Serial numbers do not match. Please verify information in the helpdesk"
	exit 1
fi

if [ ! "$HD_WIRELESS" = "$WIFI_MAC" ]; then
	echo "Wifi mac addresses do not match. Please verify information in the helpdesk"
	exit 1
fi

if [ ! "$HD_ETHERNET" = "$ETHERNET_MAC" ]; then
	echo "Ethernet mac addresses do not match. Please verify information in the helpdesk"
	exit 1
fi


