#!./perl

use strict;
use warnings;
use Config; # to determine nvsize
use Test::More tests => 21;
use List::Util qw( uniqstr uniq );

use Tie::Array;

is_deeply( [ uniqstr ],
           [],
           'uniqstr of empty list' );

is_deeply( [ uniqstr qw( abc ) ],
           [qw( abc )],
           'uniqstr of singleton list' );

is_deeply( [ uniqstr qw( x x x ) ],
           [qw( x )],
           'uniqstr of repeated-element list' );

is_deeply( [ uniqstr qw( a b a c ) ],
           [qw( a b c )],
           'uniqstr removes subsequent duplicates' );

is_deeply( [ uniqstr qw( 1 1.0 1E0 ) ],
           [qw( 1 1.0 1E0 )],
           'uniqstr compares strings' );

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    is_deeply( [ uniqstr "", undef ],
               [ "" ],
               'uniqstr considers undef and empty-string equivalent' );

    ok( length $warnings, 'uniqstr on undef yields a warning' );

    is_deeply( [ uniqstr undef ],
               [ "" ],
               'uniqstr on undef coerces to empty-string' );
}

SKIP: {
    skip 'Perl 5.007003 with utf8::encode is required', 3 if $] lt "5.007003";
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    my $cafe = "cafe\x{301}";

    is_deeply( [ uniqstr $cafe ],
               [ $cafe ],
               'uniqstr is happy with Unicode strings' );

    SKIP: {
      skip "utf8::encode not available", 1
        unless defined &utf8::encode;
      utf8::encode( my $cafebytes = $cafe );

      is_deeply( [ uniqstr $cafe, $cafebytes ],
                [ $cafe, $cafebytes ],
                'uniqstr does not squash bytewise-equal but differently-encoded strings' );
    }

    is( $warnings, "", 'No warnings are printed when handling Unicode strings' );
}

is_deeply( [ uniq () ],
           [],
           'uniq of empty list' );

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    is_deeply( [ uniq "", undef ],
               [ "", undef ],
               'uniq distintinguishes empty-string from undef' );

    is_deeply( [ uniq undef, undef ],
               [ undef ],
               'uniq considers duplicate undefs as identical' );

    ok( !length $warnings, 'uniq on undef does not warn' );
}

is( scalar( uniqstr qw( a b c d a b e ) ), 5, 'uniqstr() in scalar context' );

{
    package Stringify;

    use overload '""' => sub { return $_[0]->{str} };

    sub new { bless { str => $_[1] }, $_[0] }

    package main;

    my @strs = map { Stringify->new( $_ ) } qw( foo foo bar );

    is_deeply( [ map "$_", uniqstr @strs ],
               [ map "$_", $strs[0], $strs[2] ],
               'uniqstr respects stringify overload' );
}

{
    package DestroyNotifier;

    use overload '""' => sub { "SAME" };

    sub new { bless { var => $_[1] }, $_[0] }

    sub DESTROY { ${ $_[0]->{var} }++ }

    package main;

    my @destroyed = (0) x 3;
    my @notifiers = map { DestroyNotifier->new( \$destroyed[$_] ) } 0 .. 2;

    my @uniqstr = uniqstr @notifiers;
    undef @notifiers;

    is_deeply( \@destroyed, [ 0, 1, 1 ],
               'values filtered by uniqstr() are destroyed' );

    undef @uniqstr;
    is_deeply( \@destroyed, [ 1, 1, 1 ],
               'all values destroyed' );
}

{
    "a a b" =~ m/(.) (.) (.)/;
    is_deeply( [ uniqstr $1, $2, $3 ],
               [qw( a b )],
               'uniqstr handles magic' );
}

{
    my @array;
    tie @array, 'Tie::StdArray';
    @array = (
        ( map { ( 1 .. 10 ) } 0 .. 1 ),
        ( map { ( 'a' .. 'z' ) } 0 .. 1 )
    );

    my @u = uniq @array;
    is_deeply(
        \@u,
        [ 1 .. 10, 'a' .. 'z' ],
        'uniq uniquifies mixed numbers and strings correctly in a tied array'
    );
}
