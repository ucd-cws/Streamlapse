use warnings;

use File::stat;
use Cwd;

my $l_dir = getcwd;
my $pic_dir = $l_dir . "/composited_small_renamed";

opendir(GRA,$pic_dir);
my @files = readdir(GRA);
close(GRA);

@files = sort @files; # order them appropriately, in case the OS didn't
shift @files; #remove "."
shift @files; #remove ".."

print "Renaming\n";
for(my $i=0;$i<@files;$i++){
	print "$files[$i], $i.jpg\n";
	if($files[$i] =~ /\.jpg$|\.png$/i){
		my $cur_file = "$pic_dir/$files[$i]";
		rename $cur_file,"$pic_dir/$i.jpg";
		print "renamed\n";
		system("mogrify -resize 600x \"${pic_dir}/${i}.jpg\"");
		print "resized\n\n";
	}
}



