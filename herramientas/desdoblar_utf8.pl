use strict; use warnings; use Encode qw(decode encode);
my $CK = Encode::FB_CROAK | Encode::LEAVE_SRC;
my $p = 'ui/principal.gd';
open(my $f, '<:raw', $p) or die $!;
my $s = do { local $/; <$f> };
close $f;
die "vacio" unless length($s) > 100000;
my @out; my $n = 0;
for my $line (split(/(?<=\n)/, $s)) {
    my $d = eval { decode('UTF-8', $line, $CK) };
    if (!defined $d) { push @out, $line; next; }
    my $l1 = eval { encode('ISO-8859-1', $d, $CK) };
    if (!defined $l1) { push @out, $line; next; }
    my $re = eval { decode('UTF-8', $l1, $CK) };
    if (!defined $re) { push @out, $line; next; }
    $n++ if $l1 ne $line;
    push @out, $l1;
}
my $r = join('', @out);
die "salida sospechosa" unless length($r) > 100000;
open(my $o, '>:raw', '/tmp/principal.sano.gd') or die $!;
print $o $r; close $o;
print "lineas desdobladas: $n / bytes: ", length($r), "\n";
