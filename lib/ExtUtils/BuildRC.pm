package ExtUtils::BuildRC;
use 5.006;

use strict;
use warnings FATAL => 'all';

use Exporter 5.57 qw/import/;
our @EXPORT_OK = qw/read_config/;

use Carp qw/croak carp/;
use File::Spec::Functions qw/catfile/;
use Text::ParseWords qw/shellwords/;

my $NOTFOUND = -1;

my @files = (
	($ENV{MODULEBUILDRC} ? $ENV{MODULEBUILDRC}                         : ()),
	($ENV{HOME} ?          catfile($ENV{HOME}, '.modulebuildrc')       : ()),
	($ENV{USERPROFILE} ?   catfile($ENV{USERPROFILE}, '.modulebuldrc') : ()),
);

sub _slurp {
	my $filename = shift;
	open my $fh, '<', $filename or croak "Couldn't open configuration file '$filename': $!";
	my $content = do { local $/ = undef, <$fh> };
	close $fh or croak "Can't close $filename: $!";
	return $content;
}

sub read_config {
	my %ret;

	FILE:
	for my $filename (@files) {
		next FILE if not -e $filename;

		my $content = _slurp($filename);

		$content =~ s/ (?<!\\) \# [^\n]*//gxm; # Remove comments
		$content =~ s/ \n [ \t\f]+ / /gx;      # Join multi-lines
		LINE:
		for my $line (split /\n/, $content) {
			next LINE if $line =~ / \A \s* \z /xms;  # Skip empty lines
			if (my ($action, $args) = $line =~ m/ \A \s* (\* | [\w.-]+ ) \s+ (.*?) \s* \z /xms) {
				push @{ $ret{$action} }, shellwords($args);
			}
			else {
				croak "Can't parse line '$line'";
			}
		}
		last FILE;
	}
	return \%ret;
}

1;

# ABSTRACT: A reader for Build.PL configuration files
