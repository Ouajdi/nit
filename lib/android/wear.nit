

module wear is
	android_manifest """
	    <uses-feature android:name="android.hardware.type.watch" />

		<application
			android:allowBackup="true"
			android:icon="@drawable/ic_launcher"
			android:label="@string/app_name"
			android:theme="@android:style/Theme.DeviceDefault.Light">

	<activity
		android:name="nit.app.NitActivity"
		android:label="@string/app_name">

		<intent-filter>
			<action android:name="android.intent.action.MAIN"/>
			<category android:name="android.intent.category.LAUNCHER"/>
		</intent-filter>
	</activity>

		</application>
	"""
end
