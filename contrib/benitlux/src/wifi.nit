module wifi is
	android_manifest("""<uses-permission android:name="android.hardware.WIFI" />""")
	android_manifest("""<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />""")
end

import android::nit_activity

in "Java" `{
	import android.net.wifi.WifiManager;
`}

redef class App
	fun wifi_manager: NativeWifiManager do return native_activity.wifi_manager
end

redef class NativeActivity
	fun wifi_manager: NativeWifiManager in "Java" `{
		return (WifiManager)recv.getSystemService(android.content.Context.WIFI_SERVICE);
	`}
end

extern class NativeWifiManager in "Java" `{ android.net.wifi.WifiManager `}
	super JavaObject
	redef type SELF: NativeWifiManager

#	fun get_configured_networks: NativeListOfWifiConfiguration[NativeWifiConfiguration] in "Java" `{
#		recv.getConfiguredNetworks(); 
#	`}
#	fun add_network(arg0: NativeWifiConfiguration): Int in "Java" `{
#		recv.addNetwork(arg0); 
#	`}
#	fun update_network(arg0: NativeWifiConfiguration): Int in "Java" `{
#		recv.updateNetwork(arg0); 
#	`}
	fun remove_network(arg0: Int): Bool in "Java" `{
		return recv.removeNetwork((int)arg0); 
	`}
	fun enable_network(arg0: Int, arg1: Bool): Bool in "Java" `{
		return recv.enableNetwork((int)arg0, arg1); 
	`}
	fun disable_network(arg0: Int): Bool in "Java" `{
		return recv.disableNetwork((int)arg0); 
	`}
	fun disconnect: Bool in "Java" `{
		return recv.disconnect(); 
	`}
	fun reconnect: Bool in "Java" `{
		return recv.reconnect(); 
	`}
	fun reassociate: Bool in "Java" `{
		return recv.reassociate(); 
	`}
	fun ping_supplicant: Bool in "Java" `{
		return recv.pingSupplicant(); 
	`}
	fun start_scan: Bool in "Java" `{
		return recv.startScan(); 
	`}
#	fun get_connection_info: NativeWifiInfo in "Java" `{
#		recv.getConnectionInfo(); 
#	`}
	fun get_scan_results: ListOfNativeScanResult in "Java" `{
		return recv.getScanResults(); 
	`}
	fun get_first_scan_results: NativeScanResult in "Java" `{
		return recv.getScanResults().get(0); 
	`}
	fun save_configuration: Bool in "Java" `{
		return recv.saveConfiguration(); 
	`}
#	fun get_dhcp_info: NativeDhcpInfo in "Java" `{
#		recv.getDhcpInfo(); 
#	`}
	fun set_wifi_enabled(arg0: Bool): Bool in "Java" `{
		return recv.setWifiEnabled(arg0); 
	`}
	fun get_wifi_state: Int in "Java" `{
		return recv.getWifiState(); 
	`}
	fun is_wifi_enabled: Bool in "Java" `{
		return recv.isWifiEnabled(); 
	`}
	fun calculate_signal_level(arg0: Int, arg1: Int): Int in "Java" `{
		return recv.calculateSignalLevel((int)arg0, (int)arg1); 
	`}
	fun compare_signal_level(arg0: Int, arg1: Int): Int in "Java" `{
		return recv.compareSignalLevel((int)arg0, (int)arg1); 
	`}
#	fun create_wifi_lock0(arg0: Int, arg1: JavaString): NativeWifiManagerWifiLock in "Java" `{
#		recv.createWifiLock((int)arg0, arg1); 
#	`}
#	fun create_wifi_lock1(arg0: JavaString): NativeWifiManagerWifiLock in "Java" `{
#		recv.createWifiLock(arg0); 
#	`}
#	fun create_multicast_lock(arg0: JavaString): NativeWifiManagerMulticastLock in "Java" `{
#		recv.createMulticastLock(arg0); 
#	`}
end

extern class ListOfNativeScanResult in "Java" `{ java.util.List `}
	fun length: Int in "Java" `{ return recv.size(); `}
	fun [](key: Int): NativeScanResult in "Java" `{
		return ((java.util.List<android.net.wifi.ScanResult>)recv).get((int)key);
	`}
end

extern class NativeScanResult in "Java" `{ android.net.wifi.ScanResult `}
	super JavaObject
	redef type SELF: NativeScanResult

	redef fun to_s do return to_java_string.to_s

	fun describe_contents: Int in "Java" `{
		return recv.describeContents(); 
	`}
#	fun write_to_parcel(arg0: NativeParcel, arg1: Int) in "Java" `{
#		recv.writeToParcel(arg0, (int)arg1); 
#	`}

	fun bssid: JavaString in "Java" `{
		return recv.BSSID;
	`}

	fun ssid: JavaString in "Java" `{
		return recv.SSID;
	`}

	fun capabilities: JavaString in "Java" `{
		return recv.capabilities;
	`}

	fun frequency: Int in "Java" `{
		return recv.frequency;
	`}

	fun level: Int in "Java" `{
		return recv.level;
	`}

	# API level 17
	#fun timestamp: Int in "Java" `{
	#return recv.timestamp;
	#`}
end
