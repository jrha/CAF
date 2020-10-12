# -*- perl -*-
use strict;
use warnings;
use Test::More;
use Test::Quattor;
use CAF::Service qw(@ALL_ACTIONS);
use Test::MockModule;
use Test::Quattor::Object;

=pod

=head1 SYNOPSIS

Test all methods for C<CAF::Service>

=cut

my $srv = CAF::Service->new(['ntpd', 'sshd']);


=pod

=head2 Test systemd

Test all methods for C<CAF::Service> for linux_systemd

=cut

set_service_variant("linux_systemd");

my @actions = qw(start stop restart reload condrestart);

is_deeply(\@ALL_ACTIONS, [@actions, 'stop_sleep_start'], "exported supported actions as expected");
foreach my $m (@ALL_ACTIONS) {
    # ->can cannot test AUTOLOAD magic
    my $method = (grep {$_ eq $m} @actions) ? "${m}_linux_systemd" : $m;
    ok($srv->can($method), "method $method supported");
}

foreach my $m (@actions) {
    my $method = "${m}_linux_systemd";
    $srv->$method();
    ok(get_command("systemctl $m ntpd.service"), "systemctl $m works");
}
command_history_reset;
$srv->stop_sleep_start(1);
ok(command_history_ok(["systemctl stop ntpd.service",
                       "systemctl stop sshd.service",
                       "systemctl start ntpd.service",
                       "systemctl start sshd.service"
                       ]), "stop_sleep_start systemctl works");


=pod

=head2 Test sysv

Test all methods for C<CAF::Service> for linux_sysv

=cut


set_service_variant("linux_sysv");

foreach my $m (qw(start stop restart reload condrestart)) {
    my $method = "${m}_linux_sysv";
    $srv->$method();
    ok(get_command("service ntpd $m"), "sysv $m works");
    ok(get_command("service sshd $m"),
       "sysv $m works on all elements of the services list");
}
command_history_reset;
$srv->stop_sleep_start(1);
ok(command_history_ok(["service ntpd stop",
                       "service sshd stop",
                       "service ntpd start",
                       "service sshd start"
                       ]), "stop_sleep_start sysv works");

=pod

=head2 Test solaris

Test all methods for C<CAF::Service> for solaris

=cut

set_service_variant("solaris");

$srv->restart_solaris();
ok(get_command("svcadm -v restart ntpd sshd"), "svcadm restart works");
$srv->start_solaris();
ok(get_command("svcadm -v enable -t ntpd sshd"), "svcadm enable/start works");
$srv->stop_solaris();
ok(get_command("svcadm -v disable -t ntpd sshd"), "svcadm disable/stop works");
$srv->condrestart_solaris();
ok(get_command("svcadm -v restart -t ntpd sshd"), "svcadm [cond]restart works");

$srv->reload_solaris();
ok(get_command('svcadm -v refresh ntpd sshd'),
   "reload mapped to svcadm's refresh operation");

$srv->{options}->{timeout} = 42;
$srv->restart_solaris();

ok(get_command("svcadm -v restart -s -T $srv->{options}->{timeout} ntpd sshd"),
   "svcadm restart handles timeouts the Solaris way");

command_history_reset;
$srv->stop_sleep_start(1);
ok(command_history_ok(["svcadm -v disable -t ntpd sshd",
                       "svcadm -v enable -t ntpd sshd"
                      ]), "stop_sleep_start svcadm disable/stop works");

my $srvopts = CAF::Service->new(['ntpd', 'sshd'],
                                timeout => 0,
                                persistent => 1,
                                recursive => 1,
                                synchronous => 1);

$srvopts->restart_solaris();
$srvopts->start_solaris();
ok(get_command("svcadm -v enable -r ntpd sshd"), "timeout=0/recursive/persistent svcadm enable/start works");
ok(get_command("svcadm -v restart -s -T $srvopts->{options}->{timeout} ntpd sshd"),
   "timeout=0/recursive/persistent svcadm restart the Solaris way");

done_testing();
