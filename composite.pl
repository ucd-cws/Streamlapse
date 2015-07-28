use warnings;

# conventions used here: variables prefixed by l are local, variables prefixed by r are references (as opposed to values)
# 							variables prefixed by both (eg my $lr_var_name) are both local and a reference.

use Cwd;
use File::stat;
use Time::Local;
use File::Copy;

use Data::Dumper; # for debugging

$paired_images = 1; # should we pair images?
my $auto_resize_and_rename = 1; # should we rename them into a sequence and resize them?

my $lb_graphs = 1; # do we have graphs for the left image? 1 = True, 0 = False
my $lb_pair_graphs = 0; # do we have graphs for the pair image? 1 = True, 0 = False

my $l_dir = getcwd; # load the folder that this script is located in
my $graph_folder = $l_dir . "/graphs"; # variable to store the subdirectories
my $pics_folder = $l_dir . "/pics";
my $output_folder = $l_dir . "/composited";

# for pairs - define them no matter what
my $pair_graph_folder = $l_dir . "/pair_graphs"; # variable to store the subdirectories
my $pair_pics_folder = $l_dir . "/pair_pics";
my $pair_output_folder = $l_dir . "/pair_composited";

my $paired_output = $l_dir . "/paired_output"; 
my $paired_small_output = $l_dir . "/paired_output_small"; 

my @graphs = ();
if ($lb_graphs == 1){
	writelog("Indexing graphs\n");
	@graphs = load_graphs($graph_folder,\$lb_graphs);
}

writelog("Indexing pictures\n");
my @pics = load_pics($pics_folder);

if (scalar @pics == 0){
	writelog("No pics - we probably encountered an error!");
	exit();
}

my @paired = ();
my @pair_graphs = ();

if ($paired_images == 1){ # if we're pairing images up, read the pairs
	writelog("getting pairs\n");
	@paired = load_pics($pair_pics_folder);

	if ($lb_pair_graphs == 1){
		@pair_graphs = load_graphs($pair_graph_folder,\$lb_pair_graphs); # loads a directory to read the contents - passing flag reference because the function will set it to 0 if we don't have any graphs
	}
}

$final_inc = 0;

for(my $i = 0;$i<@pics;$i++){ # for every picture in the folder
	###
	### Basically, this loops through all of the images and uses the hydrograph whose time boundaries (see above) include the image, then it composites them into the output folder
	##
	
	# sanity check - is it an image?
	if (!$pics[$i] || !$pics[$i]{'name'} || !($pics[$i]{'name'} =~ /\.jpg$|\.png$/i)) {
		writelog("Not an image\n");
		print Dumper($pics[$i]);
		next; # if it's not an image (namely, it's probably a directory) skip it
	}
	
	# decides if we have a graph for it,
	my $l_composite = check_graph_and_composite($lb_graphs,\@graphs,$pics[$i],$output_folder,$pics_folder,$graph_folder);
	if ($l_composite eq '0'){
		next;
	}
		
	my $l_pair_composite = 0;
	if($paired_images == 1){
		writelog("Getting pair");
		my $pair = find_item($pics[$i]{'l_time'}, \@paired); # can use find items here too to get the paired image
		if ($pair == 0){
			writelog("No pair! possibly an error\n\n");
			next;
		}
		
		my $l_pair_composite = check_graph_and_composite($lb_pair_graphs,\@pair_graphs,$pair,$pair_output_folder,$pair_pics_folder,$pair_graph_folder);
		if ($l_pair_composite eq '0'){ # it threw an error
			next;
		}
		
		if ($l_composite ne '' and $l_pair_composite ne ''){ # I think I can just do if($l_composite and $l_pair_composite)
			#make sure we have both, otherwise we don't want it - we just want the intersection of the two
			writelog("Merging frames\n");
			my $l_out_name = "$paired_output/$final_inc.jpg";
			system("convert",$l_composite,$l_pair_composite,"+append",$l_out_name);
			$final_inc++;
		}elsif($paired_images == 1){
			writelog("Problem outputting frame for paired images - at least one of the images did not composite");
		}
	}
	
	writelog("Next..\n\n");

}

# now, copy the images to the small dir and resize them
rename_to_num_and_resize($paired_output,$paired_small_output);

sub check_graph_and_composite{
	my $l_graph_flag = shift;
	my $lr_graphs = shift;
	my $pic = shift;
	my $output_folder = shift;
	my $pics_folder = shift;
	my $graph_folder = shift;
	#my $ref = shift;
	
	#my $pic_time,$pic_name,$graph_name;
	#if ($ref == 1){ # this is a stupid hack, but I don't have time right now to fix this better
	#	$pic_time = $pic->{'l_time'};
	#	$pic_name = $pic->{'name'};
	#}
	
	my $graph = 0;
	if ($l_graph_flag == 0){
		$graph = 0;
	}else{
		#writelog("Time = " . $pic->{'l_time'});
		$graph = find_item($pic->{'l_time'}, $lr_graphs);
	}

	if ($graph == 0 && $l_graph_flag == 1){
		#print Dumper($pic);
		writelog("No graph! Probably an error\n");
		return 0;
	}
	
	my $l_composite = 0;
	if ($graph == 0){ # if we don't have a graph and it's not an "error"
		if ($l_graph_flag != 0){
			writelog("No graph...\n");
		}
		$l_composite = "$pics_folder/" .$pic->{'name'}; # set the composited image to the input
	}else{
		$l_composite = composite_and_save($pic->{'name'},$graph->{'name'},$output_folder,$pics_folder,$graph_folder);
	}
	return $l_composite;
}

sub composite_and_save{
	my $l_image = shift;
	my $l_graph = shift;
	my $l_output_folder = shift;
	my $l_pics_folder = shift;
	my $l_graph_folder = shift;
	
	my $l_out_name = "$l_output_folder/" . substr($l_image,0,length($l_image)-4) . "_composited.jpg"; # this use of substr strips the extension off so that we can modify the name
		
	my $l_full_pic = "$l_pics_folder/$l_image"; # merge the names of the image and the folder so we have a full path
	my $l_full_graph = "$l_graph_folder/$l_graph"; # same with the graph
	
	my $l_success = system("composite -gravity NorthEast \"$l_full_graph\" \"$l_full_pic\" \"$l_out_name\""); # then make the system call to imagemagick to composite the two images and write them out to the file in $out_name - this puts the graph in the top right. We can change that by changing NorthEast to NorthWest, etc. We can also do more fine-grained control of location
	
	if($l_success == 0){
		return $l_out_name;
	}else{
		return '';
	}
}

sub load_pics{
	my $l_pics_folder = shift;
	
	opendir(PICS, $l_pics_folder);
	my @l_pics = readdir(PICS);
	close(PICS);
	@l_pics = sort @l_pics;
	
	return index_items(\@l_pics,2, $l_pics_folder);
}
	
sub load_graphs{
	my $l_graph_folder = shift;
	my $lr_data_flag = shift;
	
	opendir(GRA,$l_graph_folder); # loads a directory to read the contents
	my @l_graphs = readdir(GRA); # read the contents of the folder into the array @graphs
	close(GRA); # close the directory

	@l_graphs = sort @l_graphs; # order them appropriately, in case the OS didn't
	shift @l_graphs; #remove "."
	shift @l_graphs; #remove ".."

	writelog("Found " . scalar @l_graphs . " items");
	
	if (scalar @l_graphs == 0){ # no graphs!
		writelog("No graphs - final pictures will not include composited graphs for this stream");
		$$lr_data_flag = 0; # dereference the data flag and set it to 0 to indicate that we don't have any of these
		return () # return an anonymous array
	}else{
		return index_items(\@l_graphs,1,$l_graph_folder); # pass graphs by reference and overwrite them then return that value
	}
	
}

sub get_graph_time{
	my $graph = shift; # get the graph name from the parameters
	#print "$graph\n";
	#$graph =~ /.*?(\d{2}).{1}(\d{2}).{1}(\d{4})\s(\d{2})\d{2}\.png$/; # get the date information from the filenames of the graphs
	$graph =~ /.*?(\d{4}).{1}(\d{2}).{1}(\d{2}).{1}(\d{2}).{1}\d{2}.{1}\d{2}\.png$/; # get the date information from the filenames of the graphs
	my $g_year = $1; 
	my $g_month = $2;
	my $g_day = $3;
	my $g_hour = $4;

	$g_month--; # 0 indexed so we need to subtract one from every month to get the human version
	
	if ($g_month < 0 || $g_month > 11 || $g_day < 0 || $g_year < 0){ # basic boundary checks...
		#print "[$g_month,$g_day,$g_year]\n";
		return 0;
	}
	
	my $g_time_low = timelocal(0,0,$g_hour,$g_day,$g_month,$g_year); # Get the unix time representation of 12am on that day
	
	#print "[$g_time_low]\n";
	
	return $g_time_low; # send them back to the calling function

}

sub get_image_time{
	my $image = shift;
	
	#my $mdate = 0; # just in case it's not defined later
	#get the image date
	#$image =~ /.*?_(\d+).jpg$/; # looks for a name with a bunch of digits at the end
	
	my $l_time = stat($image)->mtime;
	if ($l_time){
		return $l_time; # set the modification time to the retrieved digits
	}else{
		return 0;
	}	
}

sub writelog{
	# for now just prints - in the future, we might want something else...
	my $l_logval = shift;
	print $l_logval;
}

sub index_items{
	
	my $lr_item_names = shift;
	my $graphs_or_images = shift; # 1 is graphs, 2 is images
	my $base_folder = shift;
	
	my @items = ();
	
	# individual_graph is a hash of l_time, h_time, name (=minimum time, maximum time, graph name)
	#my %graph_base = {};
	#$graph_base{"l_time"} = 0;
	#$graph_base{"h_time"} = 0;
	#$graph_base{"g_name"} = 0;
	
	writelog("indexing " . scalar @$lr_item_names . " items! Starting with lower limit...\n");
	my $min_time = 99999999999; # set to something very high
	my $max_time = 0; # set to something low
	for(my $i=0;$i<@$lr_item_names;$i++){
	
		if (!($lr_item_names->[$i] =~ /\.jpg$|\.png$/i)) {
			$items[$i] = {};
			$items[$i]{'l_time'}=0;
			$items[$i]{'h_time'}=0;
			next;
		}
		$items[$i] = {};
		my $l_time_low = -1;
		if ($graphs_or_images == 1){
			$l_time_low = get_graph_time($lr_item_names->[$i]);
		}else{
			$l_time_low = get_image_time($base_folder . "/" . $lr_item_names->[$i]);
		}
		if ($l_time_low == 0){
			writelog("skipping " . $lr_item_names->[$i] . " - invalid timestamp in filename\n");
			next; # skip this iteration of the loop - this graph is out of bounds
		}
		
		if ($l_time_low < $min_time){
			$min_time = $l_time_low;
		}
		
		$items[$i]{'l_time'} = $l_time_low;
		$items[$i]{'name'} = $lr_item_names->[$i];
		
		#print $items[$i]{'name'} . " " . $items[$i]{'l_time'} . "\n";
	}
	
	# now we build in the high times so that the range covered by each item extends up to, but not including the next item
	writelog("finding upper limit of times\n");
	
	if (scalar @items == 0){
		writelog("finished indexing - zero length array\n\n");
		return @items;
	}
	
	@items = sort bytime @items;
	
	for (my $i = 0; $i < scalar @items; $i++){
		if ($i == (@items - 1)){ # if we're on the last one, special case
			$items[$i]{'h_time'} = $items[$i]{'l_time'} + 3600*24; # add 24 hours
		}else{
			$items[$i]{'h_time'} = $items[$i+1]{'l_time'} - 1; # high time of previous = low time of next minus 1
		}
		
		if ($items[$i]{'h_time'} > $max_time){
			$max_time = $items[$i]{'h_time'};			
		}
	}
	
	writelog("low = $min_time\nhigh = $max_time\n");	
	writelog("finished indexing\n\n");
	return @items;
}

sub find_item{
	my $l_time = shift;
	my $lr_items = shift;
	
	if (!$l_time){
		writelog("No time specified - this is likely an error\n");
		return 0;
	}
	
	writelog("finding graph or image...");
	for (my $i = 0;$i<@$lr_items;$i++){	# for every element in the graphs index
		if ($lr_items->[$i]{'l_time'} && $lr_items->[$i]{'h_time'} && ( $l_time > $lr_items->[$i]{'l_time'} || $l_time == $lr_items->[$i]{'l_time'} ) && $l_time < $lr_items->[$i]{'h_time'}){ # if the time is in bounds
			writelog("found!\n");
			return $lr_items->[$i];  # note - this returns the actual item, not a reference!
		}
	}
	
	writelog("couldn't find match for $l_time...");
	return 0; # if we get here - return a form of nothing
}

sub bytime($$){
	if (!$_[1] || !$_[0]){
		return 0;
		#print "uninitialized";
	}
	if ($_[1]{'l_time'} < $_[0]{'l_time'}){
		return 1;
	}else{
		return -1;
	}
}

sub rename_to_num_and_resize{
	my $large_dir = shift;
	my $small_dir = shift;

	opendir(GRA,$large_dir);
	my @t_files = readdir(GRA);
	close(GRA);

	@t_files = sort @t_files; # order them appropriately, in case the OS didn't
	shift @t_files; #remove "."
	shift @t_files; #remove ".."

	writelog("Copying and Resizing\n");
	for(my $i=0;$i<@t_files;$i++){
		if($t_files[$i] =~ /\.jpg$|\.png$/i){
			my $cur_file = "$large_dir/$t_files[$i]";
			my $large_file = "$large_dir/$i.jpg";
			my $small_file = "$small_dir/$i.jpg";
			#writelog("Renaming $t_files[$i], $i.jpg\n");
			#rename $cur_file,$large_file;
			#writelog("renamed\n");
			copy($large_file,$small_file) or writelog("Couldn't copy large file for image $i to small file location");			
			writelog("copied");
			system("mogrify -resize 1280x \"$small_file\"");
			writelog("resized\n\n");
		}
	}
}
