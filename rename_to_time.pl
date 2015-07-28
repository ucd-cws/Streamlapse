use warnings;

# conventions used here: variables prefixed by l are local, variables prefixed by r are references (as opposed to values)
# 							variables prefixed by both (eg my $lr_var_name) are both local and a reference.

use Cwd;
use File::stat;
use Time::Local;
use File::Copy;

use Data::Dumper; # for debugging
my $folder = Cwd;

@allitems = load_pics($folder);

sub load_pics{
	my $l_pics_folder = shift;
	
	opendir(PICS, $l_pics_folder);
	my @l_pics = readdir(PICS);
	close(PICS);
	@l_pics = sort @l_pics;
	
	return @l_pics;
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
