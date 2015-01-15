import cocoa_touch

redef class App
	redef fun did_finish_launching_with_options
	do
		return hack(app_delegate)
	end

	fun hack(application: AppDelegate): Bool in "ObjC" `{

		NSLog(@"Hello World!");

		application.window = [[UIWindow alloc] initWithFrame:
		[[UIScreen mainScreen] bounds]];
		application.window.backgroundColor = [UIColor whiteColor];

		UILabel *label = [[UILabel alloc] init];
		label.text = @"Hello Nit!";
		label.center = CGPointMake(100, 100);
		[label sizeToFit];

		[application.window addSubview: label];
		[application.window makeKeyAndVisible];

		return YES;
	`}
end
