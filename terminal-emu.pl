use Term::VT102;
use Net::WebSocket::Server;
our $string = "We are the world";
print "$string\n";
myfunction();
print "$string\n";

sub myfunction {
    print "$string\n";
   our $string = "We are the function";
   print "$string\n";
}
# Create a new VT102 object
my $vt = new Term::VT102;
# Send terminal code to set text color to red
$vt->process("\e[31m");

# Send text to the screen
$vt->process("Hello, World!");

sub serialize_terminal {
    my $vt = shift;

    my @ttyrecFrame = ();
    # Read the whole screen line by line
    for my $row (0 .. $vt->rows - 1) {
        my $line = $vt->row_plaintext($row);
        if(!defined($line)){$
            line = (' ') x 80;
        }
        my $rowattr = $vt->row_attr($row);
        my @ints = unpack("S*", $rowattr);
        if(!@ints){
            splice(@ints, 0, 80, (7) x 80);
        }
        @chars = split(//, $line);
        my @objects = map { { chr => $chars[$_], attr => $ints[$_] } } 0..$#chars;
        push @ttyrecFrame, @objects;
    }   

    sub to_string{
        my $object = shift;
        my $paddedAttr = sprintf("%03s", $object->{attr});
        return $object->{chr} . $paddedAttr;
    }

    my $serializedString = join('', map { to_string($_) } @ttyrecFrame);
    return $serializedString;
}


my $server = Net::WebSocket::Server->new(
    listen => 8080,
    tick_period => 0.05,
    on_tick => sub {
        my ($serv) = @_;
        my $serialized = serialize_terminal($vt);
        $_->send_utf8($serialized) for $serv->connections;
    },
);

$SIG{TERM} = sub {
    # Shut down the server when receiving SIGTERM
    $server->shutdown;
};

print "asdf";

$server->start();