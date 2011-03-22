package ExtUtils::BuildRC;
use 5.006;

use strict;
use warnings FATAL => 'all';

use Exporter 5.57 qw/import/;
our @EXPORT_OK = qw/read_config parse_file/;

use Carp qw/croak carp/;
use File::Spec::Functions qw/catfile/;
use Text::ParseWords qw/shellwords/;

sub _slurp {
	my $filename = shift;
	open my $fh, '<', $filename or croak "Couldn't open configuration file '$filename': $!";
	my $content = do { local $/ = undef, <$fh> };
	close $fh or croak "Can't close $filename: $!";
	return $content;
}

sub parse_file {
	my $filename = shift;

	my %ret;
	my $content = _slurp($filename);

	$content =~ s/ (?<!\\) \# [^\n]*//gxm; # Remove comments
	LINE:
	for my $line (split / \n (?! [ \t\f]) /x, $content) {
		next LINE if $line =~ / \A \s* \z /xms;  # Skip empty lines
		if (my ($action, $args) = $line =~ m/ \A \s* (\* | [\w.-]+ ) \s+ (.*?) \s* \z /xms) {
			push @{ $ret{$action} }, shellwords($args);
		}
		else {
			croak "Can't parse line '$line'";
		}
	}
	return \%ret;
}

sub read_config {
	my @files = (
		($ENV{MODULEBUILDRC} ? $ENV{MODULEBUILDRC}                          : ()),
		($ENV{HOME}          ? catfile($ENV{HOME},        '.modulebuildrc') : ()),
		($ENV{USERPROFILE}   ? catfile($ENV{USERPROFILE}, '.modulebuildrc') : ()),
	);

	FILE:
	for my $filename (@files) {
		next FILE if not -e $filename;
		return parse_file($filename);
	}
	return {};
}

1;

# ABSTRACT: A reader for Build.PL configuration files

=head1 SYNOPSYS

 use ExtUtils::BuildRC 'read_config';
 
 my $config = read_config();
 my @build_options = (@{ $config->{build} }, @{ $config->{'*'} });

=head1 DESCRIPTION

This module parses Build.PL configuration files.

=func parse_file($filename)

Read a Build.PL compatible configuration file. It returns a hash with the actions as keys and arrayrefs of arguments as values.

=func read_config()

Read the first Build.PL configuration file that's available in any of the locations defined by the Build.PL Spec. The data is returned in the same format as C<parse_file> does.
