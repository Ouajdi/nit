import native_app_glue

redef class App
	redef fun save_state do
		print "save_state - in"
		super
		print "save_state - out"
	end

	redef fun init_window do
		print "init_window - in"
		super
		print "init_window - out"
	end

	redef fun term_window do
		print "term_window - in"
		super
		print "term_window - out"
	end

	redef fun gained_focus do
		print "gained_focus - in"
		super
		print "gained_focus - out"
	end

	redef fun lost_focus do
		print "lost_focus - in"
		super
		print "lost_focus - out"
	end

	redef fun pause do
		print "pause - in"
		super
		print "pause - out"
	end

	redef fun stop do
		print "stop - in"
		super
		print "stop - out"
	end

	redef fun destroy do
		print "destroy - in"
		super
		print "destroy - out"
	end

	redef fun start do
		print "start - in"
		super
		print "start - out"
	end

	redef fun resume do
		print "resume - in"
		super
		print "resume - out"
	end

	redef fun low_memory do
		print "low_memory - in"
		super
		print "low_memory - out"
	end

	redef fun config_changed do
		print "config_changed - in"
		super
		print "config_changed - out"
	end

	redef fun input_changed do
		print "input_changed - in"
		super
		print "input_changed - out"
	end

	redef fun window_resized do
		print "window_resized - in"
		super
		print "window_resized out"
	end

	redef fun window_redraw_needed do
		print "window_redraw_needed - in"
		super
		print "window_redraw_needed - out"
	end

	redef fun content_rect_changed do
		print "content_rect_changed - in"
		super
		print "content_rect_changed - out"
	end
end
