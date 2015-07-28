use warnings;

use File::stat;
use Cwd;

my $l_dir = getcwd;
my $pic_dir = $l_dir . "/pics_2";

print "Image name prefix: ";
my $prefix = <STDIN>;
chomp($prefix);
print "\n";

opendir(GRA,$pic_dir);
my @files = readdir(GRA);
close(GRA);

@files = sort @files; # order them appropriately, in case the OS didn't
shift @files; #remove "."
shift @files; #remove ".."

my @new_pic = [];
my @all_pics = [];

print "Getting images stats\n";
for (my $i = 0; $i < @files; $i++){

	if($files[$i] =~ /\.jpg$|\.png$/i){
		$all_pics[$i] = [];
		$all_pics[$i][0] = $files[$i];
		$all_pics[$i][1] = stat("$pic_dir/$files[$i]")->mtime;
		print "$pic_dir/$files[$i] - $all_pics[$i][1]\n";
	}
}

print "Renaming\n";
for(my $i=0;$i<@all_pics;$i++){
	print "$all_pics[$i][0], ${prefix}_". $all_pics[$i][1].".jpg\n";
	if($all_pics[$i][0] =~ /\.jpg$|\.png$/i){
		my $cur_file = "$pic_dir/$all_pics[$i][0]";
		rename $cur_file,"${pic_dir}/${prefix}_". $all_pics[$i][1] .".jpg";
		#system("mogrify $l_dir\\$i.jpg -resize 600x");
	}
}



