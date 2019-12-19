package cip2;

use strict;
use warnings;
use 5.008001;
use Config;
use base qw( Exporter );

our @EXPORT = qw( run dzil make cpanm Makefile_PL Build_PL Build test dzil_build install_deps );

# ABSTRACT: Next Gen CI Perl
# VERSION

sub import
{
  strict->import;
  warnings->import;
  goto &Exporter::import;
}

sub run
{
  my(@cmd) = @_;
  print "+@cmd\n";
  system @cmd;
  exit 2 if $?;
}

sub dzil
{
  my(@cmd) = @_;
  unshift @cmd, 'dzil-wrapper';
  run @cmd;
}

sub Makefile_PL
{
  my(@cmd) = @_;
  unshift @cmd, $^X, 'Makefile.PL';
  run @cmd;
}

sub Build_PL
{
  my(@cmd) = @_;
  unshift @cmd, $^X, 'Build.PL';
  run @cmd;
}

sub make
{
  my(@cmd) = @_;
  my $make = $Config{make} || $ENV{MAKE} || 'make';
  unshift @cmd, $make;
  run @cmd;
}

sub Build
{
  my(@cmd) = @_;
  if($^O eq 'MSWin32')
  {
    unshift @cmd, 'Build';
  }
  else
  {
    unshift @cmd, './Build';
  }
  run @cmd;
}

sub cpanm
{
  my(@cmd) = @_;
  unshift @cmd, 'cpanm';
  run @cmd;
}

sub test
{
  if(-f 'Makefile')
  {
    make('test', 'TEST_VERBOSE=1');
  }
  elsif(-f 'Build')
  {
    Build('test', 'verbose=1');
  }
  else
  {
    die "no Makefile or Build";
  }
}

sub dzil_build
{
  die 'no dist.ini' unless -f 'dist.ini';

  my @missing;

  if(-f 'alienfile')
  {
    @missing = split /\n/, `dzil-wrapper af missing -p configure`;
    dzil 'cpanm', '-n', @missing if @missing;

    @missing = split /\n/, `dzil-wrapper af missing`;
    dzil 'cpanm', '-n', @missing if @missing;
  }

  @missing = split /\n/, `dzil authordeps --missing`;
  dzil 'cpanm', '-n', @missing if @missing;

  dzil 'dzil', 'build';

  my $name;
  my $version;

  open my $fh, '<', 'dist.ini' or die "unable to open dist.ini $!";
  while(<$fh>)
  {
    if(/^name\s+=\s+(.*?)\s+$/)
    {
      $name = $1;
    }
    if(/^version\s+=\s+(.*?)\s+$/)
    {
      $version = $1;
    }
  }
  close $fh;

  die "no name" unless defined $name;
  die "no version" unless defined $version;

  my $dir = "$name-$version";
  if(-d $dir)
  {
    chdir $dir;
  }
  else
  {
    die "dir $dir not found";
  }
}

sub install_deps
{
  cpanm('--installdeps', '.');
}

1;
