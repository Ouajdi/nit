package org.nitlanguage.benitlux_android;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class NitService1 extends Service {
	@Override
	public IBinder onBind(Intent arg) {
		return null;
	}

	@Override
	public void onStart(Intent intent, int id) {
		super.onStart(intent, id);
		android.util.Log.w("==========", "service start");
		int pid = android.os.Process.myPid();
		android.util.Log.w("==========", String.valueOf(pid));
		stopSelf();
	}

	@Override
	public void onDestroy() {
		super.onDestroy();
		android.util.Log.w("==========", "service stop");
	}
}
