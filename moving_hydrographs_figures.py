import datetime
import os

import numpy
from matplotlib import pyplot
import matplotlib.dates as mdates
from matplotlib import mlab

from hydro_lib import plot_series
import hydro_lib

from code_library.common import log

frame_size = (2048, 1536)
output_dpi = 150  # matplotlib didn't seem to like me setting this to 300
header_row_num = 1  # what row is the header on - starts at 1
date_field = "date"  # these should all be lowercase or numpy CHOKES
flow_field = "stage"
output_folder = "output"  # relative to the path of the script
convert_dates = False  # if the dates are nonstandard, set this to True

sites = ['CRG']
site_suffix = "data"   # filenames are of the form (site)_(site_suffix).csv without parens. eg TUO_stage_data.csv if "TUO" is site and "stage_data" is site_suffix

title = {}
title['NFA'] = 'North Fork American'
title['SFY'] = 'South Fork Yuba'
title['TUO'] = "Tuolumne"
title['CLA'] = "Clavey"
title['CRG'] = "Cosumnes"
title['SHA'] = "Shasta"

# colors are web colors...
main_color = '#303030'
future_color = '#8859ff'
past_color = '#4829e4'
present_color = 'black'  # color of the dot
fig_transparency = True
line_width = 1  # recommended that this be 1 when multiple data series are in play, and more for fewer



plot_items = []
#plot_items.append(plot_series("air_temp", "#68c439", "#98f469"))
#plot_items.append(plot_series("water_temp", past_color, "#f49869", shared_axis=plot_items[0]))
#plot_items.append(plot_series("water_temp", past_color, "#f49869"))
plot_items.append(plot_series(flow_field, past_color, future_color))

#plot_items[0].inbound_shared.append(plot_items[1])
plot_items[0].use_moving_average = False
plot_items[0].moving_average_size = 24

# divides the size in pixels by the dpi to get the sizes in inches as a tuple. Uses int() for rounding because it doesn't
# need to be incredibly accurate.
output_size_in = (int(frame_size[0]/output_dpi),int(frame_size[1]/output_dpi))
print "Output Size: %s" % str(output_size_in)
# set up the chart colors, etc, here:
rcparams = {
	'text.color': main_color,
	'xtick.major.size': 0,
	'ytick.major.size': 0,
	'xtick.labelsize' : 5,
	'ytick.labelsize' : 5,
	'axes.labelsize' : 7,
	'axes.titlesize' : 9,
	'axes.labelcolor': main_color,
	'axes.edgecolor' : main_color,
	'xtick.color': main_color,
	'ytick.color': main_color,
	'grid.color' : main_color,
	'savefig.dpi': 150}

pyplot.rcParams.update(rcparams)

out_folder = os.path.join(os.getcwd(), output_folder)
if not os.path.exists(out_folder):
	os.makedirs(out_folder)  # if it doesn't exist, make eve rything needed to make the folder, and the folder
	
for site in sites:
	fname = '%s_%s.csv' % (site, site_suffix)
	
	print fname
	
	file = os.path.join(os.getcwd(), fname)
	
	
	data = mlab.csv2rec(fname, delimiter=',', skiprows=header_row_num-1)
	
	#print "Data: %s" %data
	
	#print "Plot Items: %s" %plot_items

	hydro_lib.setup_data(data, plot_items)

	# should do some error checking, but getting mysterious numpy error. Need to move on.
	#if not data.any(): # numpy recarray - can't check for truth
	#	log.error("File not loaded. Check that it conforms to the naming convention -skipping site")
	#	continue
	
	dates = data[date_field]

	# fake dates are something nick made where we actually ignore the date for the graph (it generated errors) because you can't see them. Instead we
	# just need a sequence of numbers in order that corresponds to the dates. This will do just fine unless we have discontinuous data
	fake_dates = []
	i = 0
	while i < len(dates):
		fake_dates.append(i)
		i = i + 1
	
	# no need to convert dates this time
	
	if convert_dates is True:
		print "Converting dates"
		for inc in range(len(dates)):  # convert all the poorly formatted dates into something this will understand
			dates[inc] = hydro_lib.convert_bad_date(dates[inc])
		print "Dates converted"
	
	for i, date_object in enumerate(data[date_field]):  # for every timestep
		if date_object.hour > 21 or date_object.hour < 5: # don't output nighttime graphs
			log.write("Skipping hour %s" % date_object.hour,True)
			continue

		# create the figure
		fig = pyplot.figure(figsize=output_size_in, dpi=output_dpi)  # these kwargs are for display only; see 'savefig' below

		plot_items[0].axis = fig.add_subplot(1, 1, 1, alpha=0.0)  # set the axis for the first one now, the others will be created later
		for item in plot_items:
			if item.shared_axis:
				item.axis = item.shared_axis.axis # item.shared_axis is a reference to another plot_series instance
			else:
				item.axis = fig.add_subplot(1, 1, 1, alpha=0.0, sharex=plot_items[0].axis)

		# set up the data
		x_past_dates = fake_dates[:i+1]

		# plot the data

		for item in plot_items:  # now we need to plot many items in one!

			item.axis.plot(fake_dates, item.data, '-', linewidth=1, color=item.future_color, alpha=0.6)  # future
			y_past_data = item.data[:i+1]

			item.axis.plot(x_past_dates, y_past_data, '-', linewidth=1, color=item.color)  # past
			item.axis.plot(x_past_dates[-1], y_past_data[-1], 'o', color=present_color)  # present (dot)


			xmin = fake_dates[0]
			xmax = fake_dates[-1]

			item.axis.set_xlim(xmin, xmax)
			if item.shared_axis:
				item.axis.set_ylim(item.shared_axis.ymin, item.shared_axis.ymax*1.1)  # the shared axis instance has the true min/max
			else:
				item.axis.set_ylim(item.ymin, item.ymax*1.1)
		
		# set up the chart
		#datemin = dt.date(r.date.min().year, 1, 1)
		#datemax = dt.date(r.date.max().year+1, 1, 1)

		#ax.set_ylabel('Discharge (cfs)')
		#ax.xaxis.set_major_formatter(mdates.DateFormatter('%d-%b-%Y %h:%m'))
		#ax.set_title(title[site])
		
		# ax.grid()
		
		# save the figure
		figname = '%s_%s.png' % (fname, date_object)
		
		# save the figure; set transparency
		
		if ":" in figname:
			figname = figname.replace(":", "-")
		pyplot.savefig(os.path.join(out_folder, figname), transparent=fig_transparency)
		log.write("Saved %s" % figname, True)
		pyplot.close('all')
		
		for item in plot_items:
			item.axis = None  # clear the axis now

print 'finished'
