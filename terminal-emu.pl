use Term::VT102;
use Net::WebSocket::Server;

# Create a new VT102 object
my $vt = new Term::VT102;

# Send terminal code to clear the screen
#$vt->process("\e[2J");

# Send terminal code to set text color to red
$vt->process("\e[31m");

# Send text to the screen
$vt->process("Hello, World!");
my @ttyrecFrame = ();
# Read the whole screen line by line
for my $row (0 .. $vt->rows - 1) {
    my $line = $vt->row_plaintext($row);
    if(!defined($line)){$
        line = (' ') x 80;
    }
    print "Line $row: $line\n";
    my $rowattr = $vt->row_attr($row);
    # $attr=substr($rowattr,4,2);
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

my $server = Net::WebSocket::Server->new(
    listen => 8080,
    on_connect => sub {
        my ($serv, $conn) = @_;
        $conn->on(
            handshake => sub {
                my ($conn, $handshake) = @_;
                $conn->disconnect() unless $handshake->req->origin eq $origin;
            },
            utf8 => sub {
                my ($conn, $msg) = @_;
                $_->send_utf8($msg) for $conn->server->connections;
            },
            binary => sub {
                my ($conn, $msg) = @_;
                $_->send_binary($msg) for $conn->server->connections;
            },);

    },
    tick_period => 0.05,
    on_tick => sub {
        my ($serv) = @_;
        my $serialized = join('', map { to_string($_) } @ttyrecFrame);
        $_->send_utf8($serialized) for $serv->connections;
    },
)->start;