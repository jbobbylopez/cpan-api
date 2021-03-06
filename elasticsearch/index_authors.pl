#!/usr/bin/perl

=head1 SYNOPSIS

Loads author info into db.  Requires the presence of a local CPAN/minicpan.

    perl author.pl /path/to/(mini)cpan

=cut

use Modern::Perl;

use Data::Dump qw( dump );
use Every;
use Find::Lib '../lib';
use Gravatar::URL;
use IO::File;
use IO::Uncompress::AnyInflate qw(anyinflate $AnyInflateError);
use MetaCPAN;


my $es = MetaCPAN->new->es;


my $cpan = shift @ARGV || "$ENV{'HOME'}/minicpan";
if ( !-d $cpan ) {
    die "Usage: perl author.pl /path/to/(mini)cpan";
}

my $file = "$cpan/authors/01mailrc.txt.gz";

my $z = new IO::Uncompress::AnyInflate $file
    or die "anyinflate failed: $AnyInflateError\n";

my @authors = ();

while ( my $line = $z->getline() ) {

    if ( $line =~ m{alias\s([\w\-]*)\s{1,}"(.*)<(.*)>"}gxms ) {

        my $pauseid = $1;
        my $name = $2;
        my $email = $3;
        say $pauseid;

        $es->index(
            index => 'cpan',
            type  => 'author',
            id    => $pauseid,
            data  => {
                author => $pauseid,
                name => $name,
                email => $email,
                gravatar_url => gravatar_url(email => $email),
            }
        );

    }
}

