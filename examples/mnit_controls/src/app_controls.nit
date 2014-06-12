module app_controls is
	app_name("app.nit controls demo")
	version(0, 1, git_revision)
	java_package("org.nitlanguage.controls")
end

import mnit::controls
import mnit

redef class App
	var font: TileSetFont
	var c_height = 64
	var c_width = 320

	var menu_screen: Screen
	var option_screen: Screen

	var current_screen: Screen

	redef fun window_created
	do
		super

		var font_img = load_image("font.png")
		font = new TileSetFont(font_img, 32, 32,
		"                " +
		"                " +
		" !\"#$%&'()*+,-./" +
		"0123456789:;<=>?" +
		"@ABCDEFGHIJKLMNO" +
		"PQRSTUVWXYZ[\\]^_" +
		"`abcdefghijklmno" +
		"pqrstuvwxyz\{|\}~ "+
		"£ ," # ...
		)
		font.hspace = -4

		menu_screen = new MenuScreen
		option_screen = new OptionScreen

		current_screen = menu_screen
	end

	redef fun frame_core(display)
	do
		current_screen.draw(display)
	end

	redef fun input(event)
	do
		return current_screen.input(current_screen, event)
	end
end

class MenuScreen
	super Screen
	super HitReceiver

	var font: TileSetFont
	var username = new TextInputControl(self, 0, 0, app.c_width, app.c_height*2, "Login", app.font)
	var password = new PasswordInputControl(self, 0, 0, app.c_width, app.c_height*2, "Password", app.font)
	var options = new TextRectangleButton(self, 0, 0, app.c_width, app.c_height, "Options", app.font)
	var quit = new TextRectangleButton(self, 0, 0, app.c_width, app.c_height, "Exit", app.font)

	redef init
	do
		super

		var menu = new RectangleMenu
		add menu
		menu.add username
		menu.add password
		menu.add new SeparatorControl(0, 0, app.c_width, 8)
		menu.add options
		menu.add quit
	end

	redef fun hit(sender, event)
	do
		if sender == options then app.current_screen = app.option_screen
		if sender == quit then exit 0
	end
end

class OptionScreen
	super Screen
	super HitReceiver

	var back = new TextRectangleButton(self, 0, 0, app.c_width, app.c_height, "Back", app.font)

	redef init
	do
		super

		var menu = new RectangleMenu
		add menu
		menu.add back
	end

	redef fun hit(sender, event)
	do
		if sender == back then app.current_screen = app.menu_screen
	end
end
