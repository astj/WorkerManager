package WorkerManager::Gearman;
use strict;
use warnings;
use UNIVERSAL::require;
use Gearman::Worker;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(
    job_servers
    prefix
    worker_classes
    workers
));

sub new {
    my ($class, $worker_classes, $options) = @_;
    $options ||= {};

    my $prefix = delete $options->{prefix} || '';
    my $job_servers;
    if ($job_servers = delete $options->{job_servers}) {
        $job_servers = [$job_servers] unless ref $job_servers ne 'ARRAY';
    }
    else {
        $job_servers = [qw(127.0.0.1)];
    }

    my $self = bless {
        job_servers    => $job_servers,
        prefix         => $prefix,
        worker_classes => $worker_classes || [],
        terminate      => undef,
        workers        => [],
    }, $class;
    $self->init;
    $self;
}

sub init {
    my $self = shift;
    for my $worker_class (@{$self->worker_classes}) {
        $worker_class->use or warn $@;
        push @{$self->workers}, $worker_class->new(
            job_servers => $self->job_servers,
            prefix      => $self->prefix,
        );
    }
}

sub work {
    my $self  = shift;
    my $max   = shift || 100;
    my $delay = shift || 5;
    my $count = 0;
    while ($count < $max && !$self->{terminate}) {
        if (getppid == 1) {
            die "my dad may be killed.";
            exit(1);
        }
        for my $worker (@{$self->workers}) {
            $worker->work;
        }
        $count++;
        sleep $delay;
    }
}

sub terminate {
    my $self = shift;
    $self->{terminate} = 1;
}

1;
