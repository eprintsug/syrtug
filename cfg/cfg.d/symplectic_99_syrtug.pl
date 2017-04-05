###############################################################################
#                                                                             #
#                  LOCAL SYMPLECTIC CONFIGURATION                             #
#                                                                             #
#=============================================================================#
#  See: https://github.com/eprintsug/syrtug                                   #
#  Or ask on the SyRT-UG mailing list                                         #
###############################################################################

use strict;

my $pubs = $c->{pubs};

# auto config file generation
$pubs->{'syrtug.xwalks.epconfig_filename'} = 'syrtug_config_eprints.xml';

### testing crosswalks ###
# Where is the xwalks-toolkit?
# You can add a new xwalks toolkit alongside an existing one (in a separate directory) if you want to e.g.
# ~/archives/ARCHIVEID/cfg/crosswalks-1.4.0/ [Live]
# ~/archives/ARCHIVEID/cfg/crosswalks-1.4.6/ [New version to be tested against]
#
# This MUST include the trailing slash!
$pubs->{'syrtug.test.xwalks.dir'} = $c->{'config_path'} . '/crosswalks-toolkit-1.4.0/';

# Which xsl should be processed?
# NB Original xwalks used a separate file for each item type. I try to keep everything in one xsl file if possible
# although this does require a certain zen-like approach to the XSLTs :o)
$pubs->{'syrtug.test.xwalks.default'} = 'SYRTUG-DEV.xsl';

# A file with a list of Symplectic RT-API URLs to retrieve and process.
# In this file, you can comment lines out by starting the line with a '#'.
# 	--- example (the first two would not get processed, as they are commented-out) ---
#	#http://elements.wherever:9091/publications-atom/publication/123
#	#http://elements.wherever:9091/publications-atom/publication/456
#	http://elements.wherever:9091/publications-atom/publication/789
#
# Make sure your server can connect to the Elements server, and you're using the right port number!
$pubs->{'syrtug.test.xwalks.infile'} = 'SYRTUG_TEST_RECORDS';

# A directory to put the transformed XML into.
# A copy of the source (symplectic XML) and the result (eprints xml) will be stored
$pubs->{'syrtug.test.xwalks.outdir'} = 'SYRTUG_TEST_RESULTS';



###############################################################################
#                                                                             #
#                  Summariser                                                 #
#                                                                             #
###############################################################################

# Where should the CSV be saved to?
# If this is a publicly accessible directory, you could add a reference from e.g. Excel
# to the file. You should also consider security for this location - who should
# be able to access this file?
$pubs->{'syrtug.summary-output-directory'} = $c->{htdocs_path}.'/'.$c->{defaultlanguage}.'/symplectic';
# filename for csv
$pubs->{'syrtug.summary-output-filename'} = 'summary.csv';
# email address to send successful csv generation alert to
$pubs->{'syrtug.summary-email'} = $c->{adminemail};
#$pubs->{'syrtug.summary-email'} = 'someone@somewhere.xyz';

# Summary field definitions
# Fields can be retrieved from the Atom feed or the EPrints.
# Field can also be compared.
# To do this, you need to define the same key in all three hashes: syrtug.summary-fields-atom, syrtug.summary-fields-eprint, syrtug.summary-fields-process
# The 'process' method will be passed the values from the other two hashes. You can do with you want in there - you'll be extracting the data, so 
# should know what format it's in, and how to do something sensible to compare the valued obtained from the Atom feed and the EPrint!

# Get values from the Atom feed (from the Symplectic RT-API)
# any XPath should work. You can get multiple values from these!
$pubs->{'syrtug.summary-fields-atom'} = {
	'publication_status' => '//pubs:field[@name="publication-status"]/pubs:text',
	'orcids' => '//pubs:identifier[@scheme="orcid"]',
	'sources' => '/atom:feed/atom:entry/pubs:data-source/pubs:source-name',
	'updated' => '/atom:feed/atom:updated',
	# careful - in XML these have hyphens. In perl, I'm using underscores!
	'merge_from' => '//pubs:merge-history/pubs:merge-from/@id',
	'merge_from_date' => '//pubs:merge-history/pubs:merge-from/@when',
	'merge_to' => '//pubs:merge-history/pubs:merge-to/@id',
	'merge_to_date' => '//pubs:merge-history/pubs:merge-to/@when',
};

# Get values from the EPrint object.
# These can be:
# * simple fieldnames e.g. 'type'
# * methods called on the EPrint e.g. eprint_url
# * a custom function e.g. to make a CSV column for a specific datesdatesdates type such as acceptance_date
$pubs->{'syrtug.summary-fields-eprint'} = {
	'type' => 'type',
	'title' => 'title',
	'status' => 'eprint_status',
	'publication_status' => 'ispublished',
	'date_made_live_in_WRRO' => 'datestamp',
	'eprintid' => sub {
		return shift->get_id;
	},
	'eprint_url' => sub {
		return shift->uri;
	},
	'acceptance_date' => sub {
		my( $eprint ) = @_;

	        for( @{ $eprint->value( "dates" ) } )
	        {
	                next unless defined $_->{date_type};
	                next unless $_->{date_type} eq "accepted";
	                return $_->{date};
	        }
	        return undef;
	},
	'published_date' => sub {
		my( $eprint ) = @_;

	        for( @{ $eprint->value( "dates" ) } )
	        {
	                next unless defined $_->{date_type};
	                next unless $_->{date_type} eq "published";
	                return $_->{date};
	        }
	        return undef;
	},
	'published_online_date' => sub {
		my( $eprint ) = @_;

	        for( @{ $eprint->value( "dates" ) } )
	        {
	                next unless defined $_->{date_type};
	                next unless $_->{date_type} eq "published-online";
	                return $_->{date};
	        }
	        return undef;
	},
	'orcids' => sub {
		my( $eprint ) = @_;

		my @orcids;
		my @ids = $eprint->value( "creators_orcid" );
		foreach ( @ids )
		{
			# sanity check - not needed if your ORCID data is good :o)
			push @orcids, $_ if $_ =~ /0000/;
		}
		return \@orcids if  scalar @orcids > 0;
		return undef;
	},
};

# Process methods
# Any key here will take the same referenced key from the atom and eprint hashes and calculate a value from them.
# This value could be a simple true/false flag (e.g. to show if Symplectic thinks that a publication is more published than EPrints does)
$pubs->{'syrtug.summary-fields-process'} = {
	# merge-to and merge_from are specifically undefined here as there is processing included in the main summariser script to handle these fields.
	'merge_from' => undef,
	'merge_to' => undef,
	'publication_status' => sub {
		my( $atom_value, $eprint_value, $debug ) = @_;
		print "PROC (publication_status): ",$atom_value, $eprint_value, "\n" if $debug;

		return 0 if !defined $atom_value;
		$atom_value = [ $atom_value ] if ref($atom_value) ne 'ARRAY';
		# $atom_value may be an array.
		if( defined( $eprint_value) && $eprint_value ne 'pub' && $eprint_value ne 'published_online' ){
			if( grep( /^published/i, @$atom_value ) ){
				return 1;
			}
		}
		return 0;
	 },
	'orcids' => sub {
		my( $atom_value, $eprint_value, $debug ) = @_;
		print "PROC (orcids): ",$atom_value, $eprint_value, "\n" if $debug;

		if( defined $atom_value && !defined $eprint_value ){
			# ORCIDs in atom feed, but not in EPrint
			return 1;
		}
		$atom_value = [ $atom_value ] if ref($atom_value) ne 'ARRAY';
		foreach my $orcid (@$eprint_value){
			if( !grep( /$orcid/, @$atom_value ) ){
				return 1;
			}
		}

		return 0;
	},
};
