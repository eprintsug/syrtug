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
