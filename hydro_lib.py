__author__ = 'Nick'

import logging

import numpy
import usgs

log = logging.getLogger("code_library")

convert_month = {"Jan": "01", "Feb": "02", "Mar": "03", "Apr": "04", "May": "05", "Jun": "06", "Jul": "07", "Aug": "08",
				"Sep": "09", "Oct": "10", "Nov": "11", "Dec": "12"}
# format is ddmmmyyyy hhmm where mmm is the three letter month abbrev

class plot_series:
	def __init__(self, field=None, color="#000000", future_color="#999999", shared_axis=None, smooth=False,
				smooth_size=24, timeshift=False, timeshift_size=None):
		"""
			handles fancy management of these kinds of plots. Maps colors, locks an axis to another plot_series
			so that the y values are appropriately scaled in both, constructs moving average values in order to smooth
			noisy data, and timeshifts data.
		:param field:
		:param color:
		:param future_color:
		:param shared_axis:
		:param smooth:
		:param smooth_size:
		:param timeshift:
		:param timeshift_size: How far, in seconds should the data be timeshifted? negative values timeshift into the
				past, positive values into the future. You can't timeshift to before 1970 (and where'd you get that
				data?)
		:return:
		"""
		self.field = field
		self.color = color
		self.future_color = future_color
		self.data = None  # will be set later - it's a data-frame like object from matplotlib loading
		self.axis = None  # will also be set later
		self.shared_axis = shared_axis  # should be set to the plot_series item that the Y axis is shared with
		self.inbound_shared = []  # keep track of which items use this one's axis so we can can set their min and max correctly
		self.ymin = None
		self.ymax = None
		self.use_moving_average = smooth
		self.moving_average_size = smooth_size
		self.timeshift = timeshift  # option specifying whether or not we should time
		self.timeshift_size = timeshift_size # distance and direction to timeshift

	def setup(self):
		if self.use_moving_average:
			self.transform_data_to_moving_average()
		if self.timeshift:
			# TODO: This looks like the wrong spot to do this - the data series has no time (it should instead)
			self.perform_timeshift()

	def perform_timeshift(self):
		# may need to do this elsewhere or in a different object (or add time to these series)
		for index, value in enumerate(self.data):
			self.data[index] = value + self.timeshift_size  # plus because direction specified by parameters
			if self.data[index] < 0:
				self.data[index] = 1

	def get_moving_avg_value(self, index, size=None):


		if not size:
			size = self.moving_average_size

		distance = size/2

		# general case
		first = index - distance
		last = index + distance

		# special case on left edge
		if first < 0:
			first = 0
			last = size

		if last > self.data.size: #.size because it's a numpy array
			last = self.data.size
			first = self.data.size - size


		interesting_slice = self.data[first:last]
		return interesting_slice.mean()

	def transform_data_to_moving_average(self):

		log.info("Transforming data to moving average")
		self.original_data = self.data
		for index, value, in enumerate(self.data):
			self.data[index] = self.get_moving_avg_value(index,self.moving_average_size)


def convert_bad_date(date):

	import re

	s = re.search("(\d{2})([a-zA-Z]{3})(\d{4})\s+(\d{2})(\d{2})", date)
	try:
		#print "[%s]" % s.group(5)
		good_date = "%s-%s-%s %s%s" % (convert_month[s.group(2)], s.group(1), s.group(3), s.group(4), s.group(5))
	except:
		log.error("Bad date - filling with 0 date so it doesn't crash in next step")
		good_date = "01/01/1901 00:00"

	return good_date


def setup_data(data, plot_items):
	for item in plot_items:
		item.data = data[item.field]  # initialize the data

		item.setup()

		item.ymin = numpy.min(item.data)
		item.ymax = numpy.max(item.data)
		print "(%s,%s)" % (item.ymin, item.ymax)

	for item in plot_items:
		# now that they're all set, run through it again
		if len(item.inbound_shared) > 0:
			# it has inbound shared axes
			log.info("Setting ymax for item with shared Y axis")
			for other_item in item.inbound_shared:  # run through all of them, but only set it for this item
				item.ymax = max(item.ymax, other_item.ymax)
				item.ymin = min(item.ymin, other_item.ymin)
				print "transformed to (%s,%s)" % (item.ymin, item.ymax)
