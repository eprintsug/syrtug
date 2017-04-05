# SyRT-UG EPrints Tools

This is a collection of scripts that will hopefully make working with the Symplectic/EPrints connector a bit easier.

The tools here don't have a nice friendly interface. They're command-line tools that will hopefully help you (or your
pet geek) do things a bit more efficiently when working with an EPrints Repository Tools 1 connector.

If you're happy on the command-line, things should make sense.
If you're not, find your local friendly computer-monkey who is!

The tools include:
* `bin/syrtug/make_epconfig_xml` - a script to generate the xslt config file based on current repostory config
    * name of file generated is configurable
    * date when config was generated is added to the file
* `bin/syrtug/test_crosswalks` - a script to process records from an Elements server into EPrints XML
    * takes a list of Symplectic RT-API URLs and saves the atom feed, and the resulting transformed record for inspection
	* Can be configured to use a newer version of the xwalks toolkit (saved in a new directory) to test before deployment
    * See also: 
        * https://github.com/eprintsug/crosswalks_sgul
        * Postings on the Symplectic support site
* `bin/syrtug/summariser` - a script which produces a CSV (tab-delineated; repeated values joined with semi-colons) that can be imported into e.g. Excel. The script can be configured to:
    * take simple values from EPrint fields
	* call methods on an EPrint object (e.g. `$eprint->uri`)
	* calculate values from an EPrint (e.g. extract 'acceptance date' from datesdatesdates field)
	* use XPath expressions to get values from the RT-API atom feed
	* compare values obtained from the EPrint and the RT-API feed, and flag if there is something of interest (e.g. Symplectic shows an item is more published that EPrints thinks it is)
	* output columns are: processed data first (prefixed with 'PROC'), EPrint data (prefix: EP_) and Symplectic data (prefix: SYMP_)

If you find any issues with these tools, or have any suggestions to improve them, please let us know - either on the SyRT-UG mailing list, or on GitHub: https://github.com/eprintsug/syrtug
