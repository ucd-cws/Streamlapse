This script is a work in progress. It doesn't do many of the things we consider to be essential to a good program
(ie, it doesn't catch errors, it doesn't validate data, and it doesn't appropriately chain all of the actions)

HOW IT CURRENTLY WORKS:
1) Make a copy of the initial images - we're going to do some potentially destructive editing
2) drop the graphs into the graphs folder (you can have more graphs than are needed - it'll only grab the appropriate graph)
3) run rename.pl - it'll ask you for a prefix, I recommend using a river code - it will rename all of the images with their timestamp
4) run composite.pl - it will pop out the video frames
5) Make a copy of the output (it'll save you time)
5) Run rename_to_num_and_resize.pl - it will resize the images to 600px wide (to reduce video size) and rename them
	so that they are directly sequential (0.jpg, 1.jpg, etc)
6) Download virtualdub and click open files - select the first images. It will automatically load the whole sequence.
	You can set compression options here, but don't need to. Go to file->export avi. It's FAST
7) Use your favorite compression program to shrink it (windows moviemaker will do, as will Avidemux (free)
	just open it and reexport - I find that this method is far faster than using windows moviemaker the whole way)