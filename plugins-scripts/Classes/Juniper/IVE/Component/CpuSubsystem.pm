package Classes::Juniper::IVE::Component::CpuSubsystem;
our @ISA = qw(Classes::Juniper::IVE);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->init();
  return $self;
}

sub init {
  my $self = shift;
  $self->{iveCpuUtil} = $self->get_snmp_object('JUNIPER-IVE-MIB', 'iveCpuUtil');
}

sub check {
  my $self = shift;
  $self->add_info('checking cpus');
  $self->blacklist('c', undef);
  my $info = sprintf 'cpu usage is %.2f%%', $self->{iveCpuUtil};
  # http://www.juniper.net/techpubs/software/ive/guides/howtos/SA-IC-MAG-SNMP-Monitoring-Guide.pdf
  $self->add_info($info);
  $self->set_thresholds(warning => 50, critical => 90);
  $self->add_message($self->check_thresholds($self->{iveCpuUtil}), $info);
  $self->add_perfdata(
      label => 'cpu_usage',
      value => $self->{iveCpuUtil},
      uom => '%',
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[CPU]\n";
  foreach (qw(iveCpuUtil
  )) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

sub unix_init {
  my $self = shift;
  my %params = @_;
  my $type = 0;
  foreach ($self->get_snmp_table_objects(
     'UCD-SNMP-MIB', 'laTable')) {
    push(@{$self->{loads}},
        Classes::Juniper::IVE::Component::CpuSubsystem::Load->new(%{$_}));
  }
}

sub unix_check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking loads');
  $self->blacklist('c', '');
  foreach (@{$self->{loads}}) {
    $_->check();
  }
}

sub unix_dump {
  my $self = shift;
  foreach (@{$self->{loads}}) {
    $_->dump();
  }
}


package Classes::Juniper::IVE::Component::CpuSubsystem::Load;
our @ISA = qw(Classes::Juniper::IVE::Component::CpuSubsystem);
use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  foreach my $param (qw(laIndex laNames laLoad laConfig laLoadFloat 
      laErrorFlag laErrMessage)) {
    $self->{$param} = $params{$param};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->blacklist('c', undef);
  my $info = sprintf '%s is %.2f', lc $self->{laNames}, $self->{laLoadFloat};
  $self->add_info($info);
  $self->set_thresholds(warning => $self->{laConfig},
      critical => $self->{laConfig});
  $self->add_message($self->check_thresholds($self->{laLoadFloat}), $info);
  $self->add_perfdata(
      label => lc $self->{laNames},
      value => $self->{laLoadFloat},
      warning => $self->{warning},
      critical => $self->{critical},
  );
}

sub dump {
  my $self = shift;
  printf "[LOAD_%s]\n", lc $self->{laNames};
  foreach (qw(laIndex laNames laLoad laConfig laLoadFloat 
      laErrorFlag laErrMessage)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}

