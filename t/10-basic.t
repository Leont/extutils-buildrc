#! perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;
use Test::Differences;

use ExtUtils::BuildRC qw/parse_file read_config/;

my $example1 = parse_file('t/files/example1');
eq_or_diff($example1, { install => ['--install_base', '/home/user/perl5'] }, 'parse_file seems to be sane');

{
	local $ENV{MODULEBUILDRC} = 't/files/example1';
	my $second_try = read_config();
	eq_or_diff($second_try, { install => ['--install_base', '/home/user/perl5'] }, 'Reading it from $ENV{MODULEBUILDRC} works too');
}

my $example2 = parse_file('t/files/example2');
eq_or_diff($example2, { install => ['--install_base', '/home/user/perl5', '--prefix', '/home/user'], '*' => [ '--verbose' ] }, 'Embedded newlines are handled too');
