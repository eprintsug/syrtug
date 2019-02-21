# Generate a CSV file with 6 columns:
#   eprintid
#   docid,
#   filename,
#   last_nonnull_date_embargo,
#   date_embargo_last_became_null_when,
#   security_when_date_embargo_last_became_null
### TODO

# For each file, run get_historical_embargo_data_for_file
# If the output is not null, add it as a row in the CSV file
### TODO

# Close and output the CSV file 
### TODO

# For a given file object, get its parent document's historical embargo data.
sub get_historical_embargo_data_for_file {

  my($file) = @_;

  # Get the parent document and grandparent EPrint.
  my $document = $file->get_parent;
  my $eprint = $document->get_parent;

  # These are the values we want to find.
  # Since we already have the most recent revision, we'll start with that
  # and work backwards to find the real values.
  my $last_nonnull_date_embargo = $document->value( "date_embargo" );
  my $date_embargo_last_became_null_when = $eprint->value( "lastmod" );
  my $security_when_date_embargo_last_became_null = $document->value( "security" );

  # If date_embargo is set, there is nothing to do
  return if $last_nonnull_date_embargo;
  # otherwise loop back through revisions, starting with the most recent

  # Some values we'll need to use and/or return later on.
  my $filename = $file->value( "filename" );
  my $docid = $document->value( "docid" );
  my $eprintid = $eprint->value( "eprintid" );

  # A pointer to manage the loop.
  my $current_eprint_revision_number = $eprint->value( "rev_number" );

  # Do the loop.
  do {
    # Go back one revision.
      $current_eprint_revision_number--;

    # Get that revision's data.
    ### TODO
    my $current_eprint_revision = {some code here to fetch the correct eprint revision};
    ### TODO
    my $current_document_revision = {some code here to fetch the correct document revision};

    # If date_embargo is set in this revision, record it; otherwise update the "became null" values with this revision's data.
    if $document->exists_and_set( "date_embargo" ) {
      $last_nonnull_date_embargo = $document->value( "date_embargo" );
    } else {
      $date_embargo_last_became_null_when = $current_eprint_revision->value( "lastmod" );
      $security_when_date_embargo_last_became_null = $current_document_revision->value( "security" );
    }

  # Exit the loop if we've either found a non-null date_embargo OR gone back through all the revisions.
  } while (!$last_nonnull_date_embargo && $current_eprint_revision_number > 1);

  # If we didn't find a non-null date_embargo, return nothing.
  return if !$last_nonnull_date_embargo;

  # Otherwise return an array of what we found.
  return ( 
    $eprintid,
    $docid,
    $filename,
    $last_nonnull_date_embargo,
    $date_embargo_last_became_null_when,
    $security_when_date_embargo_last_became_null
  )
}
