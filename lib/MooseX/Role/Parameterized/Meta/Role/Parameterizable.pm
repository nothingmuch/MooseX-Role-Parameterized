package MooseX::Role::Parameterized::Meta::Role::Parameterizable;
use Moose;
extends 'Moose::Meta::Role';

our $VERSION = '0.10';

use MooseX::Role::Parameterized::Meta::Role::Parameterized;
use MooseX::Role::Parameterized::Meta::Parameter;
use MooseX::Role::Parameterized::Parameters;

use constant parameterized_role_metaclass => 'MooseX::Role::Parameterized::Meta::Role::Parameterized';
use constant parameter_metaclass => 'MooseX::Role::Parameterized::Meta::Parameter';
use constant parameters_class => 'MooseX::Role::Parameterized::Parameters';

has parameters_metaclass => (
    is      => 'rw',
    isa     => 'Moose::Meta::Class',
    lazy    => 1,
    default => sub {
        my $self = shift;

        $self->parameters_class->meta->create_anon_class(
            superclasses        => [$self->parameters_class],
            attribute_metaclass => $self->parameter_metaclass,
        );
    },
);

has role_generator => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_role_generator',
);

sub add_parameter {
    my $self = shift;
    my $name = shift;

    confess "You must provide a name for the parameter"
        if !defined($name);

    # need to figure out a plan for these guys..
    confess "The parameter name ($name) is currently forbidden"
        if $name eq 'alias'
        || $name eq 'excludes';

    $self->parameters_metaclass->add_attribute($name => @_);
}

sub construct_parameters {
    my $self = shift;
    my %args = @_;

    # need to figure out a plan for these guys..
    for my $name ('alias', 'excludes') {
        confess "The parameter name ($name) is currently forbidden"
            if exists $args{$name};
    }

    $self->parameters_metaclass->new_object(\%args);
}

sub generate_role {
    my $self     = shift;
    my %args     = @_;

    my $parameters = blessed($args{parameters})
                   ? $args{parameters}
                   : $self->construct_parameters(%{ $args{parameters} });

    confess "A role generator is required to generate roles"
        unless $self->has_role_generator;

    my $role = $self->parameterized_role_metaclass->create_anon_role(parameters => $parameters);

    local $MooseX::Role::Parameterized::CURRENT_METACLASS = $role;

    $self->apply_parameterizable_role($role);

    $self->role_generator->($parameters,
        operating_on => $role,
        consumer     => $args{consumer},
    );

    return $role;
}

sub _role_for_combination {
    my $self = shift;
    my $parameters = shift;

    return $self->generate_role(
        parameters => $parameters,
    );
}

sub apply {
    my $self     = shift;
    my $consumer = shift;
    my %args     = @_;

    my $role = $self->generate_role(
        consumer   => $consumer,
        parameters => \%args,
    );

    $role->apply($consumer, %args);
}

sub apply_parameterizable_role {
    my $self = shift;

    $self->SUPER::apply(@_);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=head1 NAME

MooseX::Role::Parameterized::Meta::Role::Parameterizable - metaclass for parameterizable roles

=head1 DESCRIPTION

This is the metaclass for parameterizable roles, roles that have their
parameters currently unbound. These are the roles that you use L<Moose/with>,
but instead of composing the parameterizable role, we construct a new
parameterized role
(L<MooseX::Role::Parameterized::Meta::Role::Parameterized>).

=cut

