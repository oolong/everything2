#!/usr/bin/perl -w

use strict;
use lib qw(lib);

use ecoretool::base;
package ecoretool::import;
use base qw(ecoretool::base);

use XML::Simple;
use File::Find qw(find);
use Everything;
use Algorithm::Diff qw(diff);

use vars qw($files);

sub new
{
	my ($class) = @_;
	my $this;
	$this->{xs} = XML::Simple->new("NoSort" => 1, "KeepRoot" => 1, "NoAttr" => 1, "SuppressEmpty" => "");
	return bless $this,$class;
}

sub _inputs
{
	return {
	"user" => 
	{
		"alias" => ["u"],
		"type" => "s",
		"default" => "root",
		"help" => "The user to connect to the database with",
	},
	"password" =>
	{
		"alias" => ["p"],
		"type" => "s",
		"default" => "",
		"help" => "The password to the database for the user",
	},
	"database" => 
	{
		"alias" => ["d"],
		"type" => "s",
		"default" => "everything",
		"help" => "The database to connect to",
	},

	"nodepack" =>
	{
		"alias" => ["n"],
		"type" => "s",
		"default" => "./nodepack",
		"help" => "The directory to load the nodepack from",
	},
	};
}

sub main
{
	my ($this) = @_;

	my $options = $this->_handle_inputs();

	initEverything $options->{database};

	find(sub{ if(-e $_&& $File::Find::name =~ /\.xml$/){push @$files,$File::Find::name; }}, $options->{nodepack});

	foreach my $nodexml(@$files)
	{
		my $node = $this->{xs}->XMLin($nodexml);
		#print STDERR "Inspecting node: $nodexml\n";

		unless(exists($node->{node}))
		{
			print STDERR "Malformed node XML (no node construct): $nodexml\n";
			next;
		}

		$node = $node->{node};

		unless(exists($node->{node_id}))
		{
			print STDERR "Malformed node XML (no node_id): $nodexml\n";
			next;
		}

		my $dbnode = getNode($node->{node_id});

		if(not defined($dbnode))
		{
			#print STDERR "Node needs inserting: $$node{title}\n";
		}else{
			if($node->{type_nodetype} != $dbnode->{type_nodetype})
			{
				#print STDERR "Node id collision in $$node{title}, skipping\n";
				next;
			}

			my $thistype = getType($node->{type_nodetype});
			#next unless $thistype->{title} eq "maintenance";

			my $obj = $this->get_worker_object($thistype->{title});

			my $source_code_copy = $obj->node_xml_prep($dbnode, $DB->{dbh}, $options);

			foreach my $nfield (keys %$node)
			{
				next if $nfield eq "_create_table_statement";
				next unless defined($source_code_copy->{$nfield});

				if($node->{$nfield} ne $source_code_copy->{$nfield})
				{
					print STDERR "Node: $$node{title}, field: $nfield needs updating\n";
					print STDERR $this->field_diff($source_code_copy->{$nfield}, $node->{$nfield});
				}
			}
		}
	}

}

sub field_diff
{
	my ($this, $orig, $new) = @_;
	my $output = diff([split("\n", $orig)], [split("\n", $new)]);
	if(not defined($output))
	{
		return "";
	}

	my $outstr;
	foreach my $chunk (@$output) {
		foreach my $line (@$chunk) {
			my ($sign, $lineno, $text) = @$line;
			$outstr .= sprintf("%4d$sign %s\n", $lineno+1, $text);
		}
	}

	return $outstr;
}

sub shortdesc
{
	return "Import a nodepack into the database";
}

1;
