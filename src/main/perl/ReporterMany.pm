#${PMpre} CAF::ReporterMany${PMpost}

use CAF::Reporter ${no-snapshot-version} qw($DEBUGLV);

use parent qw(CAF::Reporter);

=pod

=head1 NAME

CAF::ReporterMany - Class for console & log message reporting in CAF applications,
which allows more than one object instance each with its own reporting setup.

=head1 DESCRIPTION

C<CAF::ReporterMany> provides class methods for message reporting
just like C<CAF::Reporter> does, with the main distinction that
multiple instances do not share the reporter setup
(e.g. they can each have their own debuglevel).

=cut

# Return the hashref that holds the reporter setup
# Subclasses of ReporterMany store the reporter config in the instance
# Also does the initialisation on first usage
sub _rep_setup
{
    my $self = shift;

    # initialise with current "global" CAF::Reporter settings
    #   if DEBUGLV is not set
    if (! exists($self->{$DEBUGLV})) {
        foreach my $opt (keys $CAF::Reporter::_REP_SETUP) {
            $self->{$opt} = ${$CAF::Reporter::_REP_SETUP}{$opt};
        }
    }

    return $self;
}

1;
