use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use MySQL::BinLog;
use Pod::Usage;
use Devel::Peek;
use Getopt::Long;
use TheSchwartz;


package MyWorker {
    use parent qw( TheSchwartz::Worker );

    sub work {
        my $class = shift;
        my TheSchwartz::Job $job = shift;

        print "Workin' hard or hardly workin'? Hyuk!!\n";

        $job->completed();
    }
}

my @dsn = ('dbi:mysql:hostname=127.0.0.1;port=21580;database=sch', 'msandbox', 'msandbox');
my $url = sprintf 'mysql://msandbox:msandbox@127.0.0.1:21580';


my $sch = TheSchwartz->new(
    databases => [
        +{
            dsn  => $dsn[0],
            user => $dsn[1],
            pass => $dsn[2],
        }
    ],
) or die;
$sch->can_do('MyWorker');
say("Process remained jobs: $url");
$sch->work_until_done();

# connect binlog
my $binlog = MySQL::BinLog->new(MySQL::BinLog::create_transport($url));
$binlog->connect();

$sch->work_until_done(); # and once more.

while (my $event = $binlog->wait_for_next_event()) {
    my $type = $event->get_event_type();
    if ($type eq QUERY_EVENT) {
        printf("QUERY: %s\n", $event->query);
        if ($event->query =~ /INSERT\s*INTO\s*job/i) {
            say("WORK!!!!!");
            $sch->work_until_done();
        }
    } elsif ($type eq USER_VAR_EVENT) {
        printf("name: %s\n", $event->name);
        printf("value: %s\n", $event->value);
    } else {
        printf("EVENT: %s\n", $event->get_event_type);
    }
# warn $binlog->get_position();
}

__END__

=head1 SYNOPSIS

    % basic-1.pl mysql://msandbox:msandbox@127.0.0.1:21580

