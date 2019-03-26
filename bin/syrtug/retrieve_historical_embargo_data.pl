#!/usr/bin/perl -w

use FindBin;
use lib "$FindBin::Bin/../../../perl_lib";

use strict;
use warnings;
use Text::CSV; ## TODO: work out whether this is needed
use Getopt::Long;
use Pod::Usage;

use EPrints;

# Get command line options.
my $output_filename;
Getopt::Long::Configure("permute");
GetOptions( 
  'output=s' => \$output_filename,
);

# Set up the repository connection.
my $repositoryid = $ARGV[0];
my $eprints = EPrints->new();
my $repo = $eprints->repository($repositoryid);
# If we don't have a repository connection, die straight away.
die "Could not find repository with id: $repositoryid" unless $repo;

# Open a CSV file with columns:
#   eprint_id
#   document_id,
#   last_nonnull_date_embargo,
#   date_embargo_last_became_null_when,
#   security_when_date_embargo_last_became_null
die "Output file not specified." unless $output_filename;
# Make sure that the output filename has the correct '.csv' extension.
$output_filename += '.csv' if substr( $output_filename, -4 ) != '.csv';
# Open the output file (or die trying).
open(my $output_file_handle, '>', $output_filename) or die "Could not open output file '$output_file' : $!";

# Print the CSV header row.
print $output_file_handle "eprint_id,document_id,last_nonnull_date_embargo,date_embargo_last_became_null_when,security_when_date_embargo_last_became_null\n";
# Set up a counter for the number of data rows added to the CSV.
my $CSV_COUNT = 0;

# Get the document dataset.
my $document_dataset = $repo->dataset("document");

# Get all documents that do not have date_embargo set.
my $document_list = $document_dataset->search(
  # satisfy all the conditions of the search (1 is the default but we defensively make it explicit)
  "satisfy_all" => 1
  # search as staff to get all results
  "staff" => 1,
  # we are only interested in documents that do not have date_embargo set
  "filters" =>[
    ## TODO: is this the correct way to look for undefined fields?
    { meta_fields => ["date_embargo"], value => undef }
  ]
)

# Set up a pointer pointing to the most recent history item
my $document_list_pointer = $document_list->count - 1;

### TODO Can we undefine $document_dataset here to free up memory? Would that actually help?

# Get the history dataset.
my $history_dataset = $repo->dataset("history");

# For each candidate document, run get_historical_embargo_data_for_document.
while ($document_list_pointer-- >= 0) do {
  ## TODO: is this the right way to call the subroutine?
  ## N.B. the subroutine returns a message string, so print it!
  print get_historical_embargo_data_for_document( $document_list->item( $document_list_pointer ) )."\n";
}

# Close the CSV file.
close($output_file_handle);

# Give some final feedback on what has happened.
print '----------------------------------\n'
print "Data rows added to CSV: $CSV_COUNT\n";

# Subroutine: get_historical_embargo_data_for_document
# Parameters: a single document object.
# Purpose: For a given document object, get its historical embargo data.
# If the document has date_embargo set, we do not need to do anything.
# Otherwise, we go back through the document revisions to find the most recent
# non-null date_embargo, if it exists, and write it to the CSV output file.
sub get_historical_embargo_data_for_document {

  my $document = @_;

  # Get the document ID.
  my $document_id = $document->get_id;
  # Get the parent EPrint and its ID.
  my $eprint = $document->get_parent;
  my $eprint_id = $eprint->get_id;

  # Get the current value of date_embargo, if any
  my $last_nonnull_date_embargo = $document->value( 'date_embargo' );
  # If date_embargo is set, there is nothing to do, return a message.
  return "Document $document_id has date_embargo set currently to $last_nonnull_date_embargo." if $last_nonnull_date_embargo;
  # Otherwise loop back through revisions, starting with the most recent

  # Along with $last_nonnull_date_embargo, these are the values we want to find.
  # Since we already have the most recent revision, we'll start with that and
  # work backwards to find the real values.
  my $date_embargo_last_became_null_when = $eprint->value( "lastmod" );
  my $security_when_date_embargo_last_became_null = $document->value( "security" );

  # Get all the history items for the parent eprint
  my $history_list = $history_dataset->search(
    # Search Options
    # satisfy all the conditions of the search (1 is the default but we defensively make it explicit)
    "satisfy_all" => 1
    # search as staff to get all results
    "staff" => 1,
    # order chronologically
    "custom_order" => "timestamp",
    # return results for the selected parent document only
    "filters" => [
      { meta_fields => [ "datasetid" ], value => "eprint", },
      { meta_fields => [ "objectid" ], value => $eprint_id, },
    ]
  );

  # Set up a pointer pointing to the most recent history item
  my $history_list_pointer = $history_list->count - 1;

  # Start the loop. Decrement the pointer each time and leave when it passes zero OR
  # when we have found $last_nonnull_date_embargo (using the "last" statement below).
  while ($history_list_pointer-- >= 0) do {

    # Get the history item.
    my $history_item = $history_list->item( $history_list_pointer );
    # Now we have a history item, get the revision file associated with it.
    my $revision_file = $history_item->get_stored_file( "dataobj.xml" )->get_local_copy;
    # If the history item does not have a revision file associated with it, move straight on to the previous history item.
    next unless $revision_file;

    # If we're still in the loop, we have a revision file. Turn it into XML we can read.
    my $revision_xml_doc = XML::LibXML->load_xml(location => $revision_file);
    my $revision_xml_path_context = XML::LibXML::XPathContext->new($revision_xml_doc);
    $revision_xml_path_context->registerNs("eprints" => "http://eprints.org/ep2/data/2.0");

    # Get date_embargo, if it exists.
    $last_nonnull_date_embargo = $revision_xml_path_context->find("//eprints:eprint/eprints:document[eprints:docid = $document_id]/eprints:date_embargo")->to_literal;

    # If date_embargo is set in this revision, we quit the loop.
    last if $last_nonnull_date_embargo;

    # Otherwise update the "became null" values with this revision's data.
    $date_embargo_last_became_null_when = $revision_xml_path_context->find("//eprints:eprint/eprints:lastmod")->to_literal;
    $security_when_date_embargo_last_became_null = $revision_xml_path_context->find("//eprints:eprint/eprints:document[eprints:docid = $document_id]/eprints:security")->to_literal;

  }

  # If we didn't find a non-null date_embargo, return a message.
  return "Document $document_id has no date_embargo in revision data." unless defined $last_nonnull_date_embargo;

  # Otherwise print a new CSV row with what we found, increment the count of data rows added to the CSV and return a message
  print $output_file_handle "$eprint_id,$document_id,$last_nonnull_date_embargo,$date_embargo_last_became_null_when,$security_when_date_embargo_last_became_null\n";
  $CSV_COUNT++;
  return "Document $document_id previously had non-null date_embargo $last_nonnull_date_embargo until $date_embargo_last_became_null_when";
}
