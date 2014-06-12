import app_controls
import mnit::controls::pretty

redef class App
	redef fun window_created
	do
		super

		load_images_for_controls
	end
end
