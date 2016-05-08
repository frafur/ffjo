#!/bin/sh

# Define general variables
JOOMLACONF=./configuration.php
VERSIONF10=./includes/version.php
VERSIONF1516=./libraries/joomla/version.php

do_joomla10()
{
	# Grab information from Joomla 1.0 configuration.
    sitename=`grep '$mosConfig_sitename =' ${JOOMLACONF}| cut -d \' -f 2 | sed -e 's/ /_/g'`
	database=`grep '$mosConfig_db =' ${JOOMLACONF} | cut -d \' -f 2`
	dbuser=`grep '$mosConfig_user =' ${JOOMLACONF} | cut -d \' -f 2`
	password=`grep '$mosConfig_password =' ${JOOMLACONF} | cut -d \' -f 2`
	host=`grep '$mosConfig_host =' ${JOOMLACONF} | cut -d \' -f 2`
}
 
do_joomla1516()
{
	# Grab information from Joomla 1.5 configuration.
	sitename=`grep '$sitename =' ${JOOMLACONF} | cut -d \' -f 2 | sed -e 's/ /_/g'`
	database=`grep '$db =' ${JOOMLACONF} | cut -d \' -f 2`
	dbuser=`grep '$user =' ${JOOMLACONF} | cut -d \' -f 2`
	password=`grep '$password =' ${JOOMLACONF} | cut -d \' -f 2`
	host=`grep '$host =' ${JOOMLACONF} | cut -d \' -f 2`
}
 
# Check if configuration.php exists.
if [ ! -e ${JOOMLACONF} ]; then
    echo "File configuration.php not found. Are you at the root of the site?"
    exit 1
fi
 
# Test for Joomla 1.0.
if [ -e ${VERSIONF10} ]; then
    do_joomla10
fi
 
# Test for Joomla 1.5 and 1.6
if [ -e ${VERSIONF1516} ]; then
    do_joomla1516
fi

echo "Creating database dump..."

# Dump the database to a .sql file
if mysqldump --skip-opt --add-drop-table --add-locks --create-options --disable-keys --lock-tables --quick --set-charset --host=$host --user=$dbuser --password=$password $database > $database.sql
then
    echo "Database dump $database.sql created."
else
    echo "Error creating database dump."
    exit 1
fi

dbdump=`pwd`/$database.sql
usedfile=`pwd`/$sitename-used.txt
notusedfile=`pwd`/$sitename-notused.txt
echo "The following files were mentioned in your Joomla database:\n" > $usedfile
echo "The following files were NOT mentioned in your Joomla database:\n" > $notusedfile
echo "Checking for used and unused files..."

# Move into the images/stories directory
cd images/stories
# Find all files and check if they are mentioned in the database dump
for file in `find . -type f -print | cut -c 3- | sed 's/ /#}/g'`
do
  file2=`echo $file | sed 's/#}/ /g'`
  result=`grep -c "$file2" $dbdump`
  if [[ $result = 0 ]]; then
    echo $file2 >> $notusedfile
  else
    echo $file2 >> $usedfile
fi
done

# Move back to the root of the website
cd ../..

# Cleanup database dump
rm $dbdump

# Report findings
echo "Files checking done."
echo "Check the following text-files for results:"
echo "$usedfile"
echo "$notusedfile"
