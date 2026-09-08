-- General Configuring
hl.config({
	general = {
		layout = "scrolling",
	},
})

hl.config({
	dwindle = {
		preserve_split = true, -- You probably want this
	},
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
hl.config({
	scrolling = {
		fullscreen_on_one_column = true,
		focus_fit_method = 1,
		column_width = 0.75,
		follow_focus = true,
		follow_min_visible = 0.25,
	},
})
