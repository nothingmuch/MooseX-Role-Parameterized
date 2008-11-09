#!/usr/bin/env perl
package MooseX::Role::Parameterized::Meta::Role;
use Moose;
extends 'Moose::Meta::Role';

use MooseX::Role::Parameterized::Parameters;

has parameter_metaclass => (
    is      => 'ro',
    isa     => 'Moose::Meta::Class',
    lazy    => 1,
    default => sub {
        Moose::Meta::Class->create_anon_class(
            superclasses => ['MooseX::Role::Parameterized::Parameters'],
        );
    },
);

sub add_parameter {
    my $self = shift;
    $self->parameter_metaclass->add_attribute(@_);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;
