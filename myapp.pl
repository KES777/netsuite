#!/usr/bin/env perl
use Mojolicious::Lite;

use lib 'lib';
use Tree;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $c = shift;
  $c->render(template => 'index');
};

app->start;
