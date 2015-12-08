# Streamlapse V1
--------------
This document is still a work in progress. Thanks to Alyssa for the notes.

See the [video training on using this software on YouTube](https://www.youtube.com/watch?v=yiS0ZR3wqU4)
[![video training on using this software on YouTube](http://img.youtube.com/vi/yiS0ZR3wqU4/0.jpg)](http://www.youtube.com/watch?v=yiS0ZR3wqU4)

 1. Start with gage/logger data and photos from each river
 2. Copy code from *moving_hydrograph* folder=code for each video. Get new copy of this every time and then edit. Nick has blank copies and can give to you, or you can retrieve from this github repository for this **need to add moving_hydrograph folder**

## Work with Images

 3. First, deal with image folder: 

Go to image folder and thumbnail view. Find script, **`sort_by_sun_angle.py`**, copy and paste it into image folder (open command prompt first within the picture folder—by holding down shift, this opens the folder and then you can run the script within the folder). Run script. If this works, you’ll get two folders—one for day and one for night. Need to provide two parameters—latitude and longitude. Ex: `--lat=37.7 --long=120.7` (need to look this up for your location each time you do this)

Or, you can just sort by size and delete night images. Not as good as the script, but is suitable if it doesn’t work  This method has issues with photos on the fringe (low light/dusk time)—this method is more tedious but it works.

Once script runs, review folders to look for dark and/or fringe  pictures and cull as necessary

 4. Then, decide which river will be your master video (aka video on the left of screen, everything else is based off of this one and its frame rate)
 5. Move pictures from master video into “pics” folder, secondary river into “pair_pics” folder. You can do these streamlapses with just one river, just don’t do anything to the pair folders and set the correct parameters in **`composite.pl`**

## Making the Graphs from Data

 6. Now, need to generate graphs
 - Need to generate a graph for each time/photo in this streamlapse
 - Cut down your stream data to only the time you need for your video, 
do .csv edits in Notepad++ (not Excel, usually tries to format dates and 
messes things up)
- Move two data files into appropriate folders (`graphs` and `pair_graphs`)
- Need two python files (from moving hydro folder) into `graphs` folders
- Decide what frame size to use
 - To help decide: open an image in an image editor, determine 
your pixel width and height. Height is number you see, then 
multiply that by 4/3 to get the width. This makes it look nicer 
and consistent.
 - Change `frame_size` (what you just determined) in **`moving_hydrographs_figures.py`**
- What you need to configure goes down to ~line 51 (probably 
shouldn’t mess with any of the other stuff unless you know 
what you’re doing)
 - `Output_dpi` sets pixel density of images on output
 - `Output_folder` where it’s going to put the graphs
 - Setting colors: Set colors for data in past, present, future
 - Colors are in web format
 - Keep # sign in front of color names in the code
- Rename csv data (ex. TUO_data.csv—this has to match one of the 
prefixes in the code, needs to end in _data)
- Check date and flow fields
- Run **`moving_hydrographs_figures.py`**
- Don’t leave folder open while it’s running, might slow process down
- Check the output to make sure the points are moving along the graphs 
logically
- If data is noisy and hard to look at, set moving average to True 
- If you want to set moving average to true for flow as well, you’d 
have to add another line (is false by default):  `Plot_item[1].use_moving_average = True`
- You can’t really see the axis labels so don’t worry about the labels, we can fix this, but not super important. These graphs are potentially something we could plot in R and make look much nicer.
- Repeat this for `pair_graphs`

## Merging Data with Images

7. Next script—indexes graphs and pair rivers images, assigns photo a time 
range, and matches it to the graph. Takes graph and puts it on an image, does 
this for pair river too, after this, should have all frames of video (but not a 
video yet)
- Open Perl script
- If you want only one image, set:  `paired_images = 0`, if not = 1
- Open command window, type: **`perl composite.pl`**

## Make videos
 
8. Run VirtualDub—turns image frames into a video
- Open first image from folder with composite images (small version), program will load remaining files.
- Click on Video, then Frame Rate, then set frame rate (usually 10fps because we have hourly 
images, or for 15min camera = 30fps)
- Save as .avi in output folder (or wherever you like).
- Once have AVI, bring into Windows Movie Maker (or similar) and add in annotation (such as "UC Davis Center for Watershed Sciences - http://watershed.ucdavis.edu" - then, export as mpg or wmv to get compressed
