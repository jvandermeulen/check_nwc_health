package Classes::SGOS::Component::SensorSubsystem;
our @ISA = qw(Classes::SGOS::Component::EnvironmentalSubsystem);
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
  foreach ($self->get_snmp_table_objects(
      'SENSOR-MIB', 'deviceSensorValueTable')) {
    push(@{$self->{sensors}}, 
        Classes::SGOS::Component::SensorSubsystem::Sensor->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  $self->add_info('checking sensors');
  $self->blacklist('ses', '');
  if (scalar (@{$self->{sensors}}) == 0) {
  } else {
    foreach (@{$self->{sensors}}) {
      $_->check();
    }
  }
}

sub dump {
  my $self = shift;
  foreach (@{$self->{sensors}}) {
    $_->dump();
  }
}


package Classes::SGOS::Component::SensorSubsystem::Sensor;
our @ISA = qw(Classes::SGOS::Component::SensorSubsystem);
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
  foreach (qw(deviceSensorIndex deviceSensorTrapEnabled
      deviceSensorUnits deviceSensorScale deviceSensorValue
      deviceSensorCode deviceSensorStatus deviceSensorTimeStamp
      deviceSensorName)) {
    $self->{$_} = $params{$_};
  }
  $self->{deviceSensorIndex} = join(".", @{$params{indices}});
  if ($self->{deviceSensorScale}) {
    $self->{deviceSensorValue} *= 10 ** $self->{deviceSensorScale};
  }
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('se', $self->{deviceSensorIndex});
  $self->add_info(sprintf 'sensor %s (%s %s) is %s',
      $self->{deviceSensorName},
      $self->{deviceSensorValue},
      $self->{deviceSensorUnits},
      $self->{deviceSensorCode});
  if ($self->{deviceSensorCode} eq "not-installed") {
  } elsif ($self->{deviceSensorCode} eq "unknown") {
  } elsif ($self->{deviceSensorCode} ne "ok") {
    if ($self->{deviceSensorCode} =~ /warning/) {
      $self->add_message(WARNING, $self->{info});
    } else {
      $self->add_message(CRITICAL, $self->{info});
    }
    $self->add_perfdata(
        label => sprintf('sensor_%s', 
            $self->{deviceSensorName}),
        value => $self->{deviceSensorValue},
    );
  } else {
    $self->add_perfdata(
        label => sprintf('sensor_%s', 
            $self->{deviceSensorName}),
        value => $self->{deviceSensorValue},
    );
  }
}

sub dump {
  my $self = shift;
  printf "[SENSOR_%s]\n", $self->{deviceSensorIndex};
  foreach (qw(deviceSensorIndex deviceSensorTrapEnabled
      deviceSensorUnits deviceSensorScale deviceSensorValue
      deviceSensorCode deviceSensorStatus deviceSensorTimeStamp
      deviceSensorName)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}


