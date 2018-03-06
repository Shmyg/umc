#!/usr/local/bin/bash

# Script for processing payment files from banks
# Parses files, creates input files for SQLLoader and loads them into DB
# Creates 3 files:
# 1 - custcode | amount
# 2 - phone_number | amount
# 3 - discarded records
# Created by Shmyg with great help from San and Sobko

ORAENV_ASK=NO
WORKING_DIR=/daily/UTL
CURR_DATE=`date +%d%m%Y`
FILENAME=BANK.DAT

DATA_FILE=$WORKING_DIR/$FILENAME
CUSTCODE_FILE=$WORKING_DIR/bank1.txt
PHONE_FILE=$WORKING_DIR/bank2.txt
DISCARD_FILE=$WORKING_DIR/bank3.txt

# Checking if file exists
if [ ! -f $WORKING_DIR/$FILENAME ]
then
 echo "File BANK.DAT doesn't exist!"
 exit 1
fi

#dos2unix $DATA_FILE
cat $DATA_FILE | \
# Removing all the line breaks and replacing ---- with line break
/usr/bin/perl -e 'while (<STDIN>) {  $str=$_; if ( $str =~ /^-/) {print "\n" ;} else {chop $str; print "${str} ";} }' | \
# Replacing ~ in 'purpose of payment' field with |
sed 's/~/|/g' | \
# Removing unnecessary fields
# Here we should receieve 4 fields: amount, custcode, phone_number and whole string
awk -F "|" '{ printf("%.2f|%s|%s|%s\n"), $4, $6, $8, $0}' | \
# Beginning main processing
awk -F "|" 'BEGIN {printf ("") > "'"$CUSTCODE_FILE"'"; printf ("") > "'"$PHONE_FILE"'"; printf ("") > "'"$DISCARD_FILE"'" }
{
 # Pinning string - if we cannot parse string - will place it in discard file
 string_processed = $0;
 # Replacing commas with dots
 gsub( ",", ".", $0 );
 # Removing all the trash
 gsub( "[^0-9.|]", "", $0 );
 # Removing possible dots in phone number
 gsub( "\\.", "", $3 );
 # Removing possible spaces and dashes in phone number
 gsub( "[[:space:]-]", "", $3 );
 # Trimming possible 50, 050, 8050 from the beginning of phone number
 gsub( "^8*0*50", "", $3 );

 # Splitting all records to different files
 # Checking custcode - it must be not null and begin with 1 digit followed by dot
 if ( length($2) != 0 && match( $2, "^[1-9]\\." ) != 0 && length($2) <= 24 ) {
  printf ("%s;%.2f\n", $2, $1 ) >> "'"$CUSTCODE_FILE"'"
 }
 else {
  # Phone number could be in 2nd field
  # Phone number length must be 7 symbols and cannot contain any
  # symbols except digits
  if ( length($2) == 7 && match( $2, "[^[:digit:]]" ) == 0 ) {
   # Here we should add 50 before phone number
   printf ("50%s;%.2f\n", $2, $1 ) >> "'"$PHONE_FILE"'"    
  }
  else {
   # Now we check 3rd field with all the rules described above
   # Here we need to add '50' before first field
   if ( length($3) == 7 && match( $3, "[^[:digit:]]" ) == 0 ) {
    printf ("50%s;%.2f\n", $3, $1 ) >> "'"$PHONE_FILE"'"    
   }
   else {
    # The last resort - we should not be here, but...
    printf ("%s\n", string_processed ) >> "'"$DISCARD_FILE"'"
   }
  }
 }
}'

echo $DB_PASS | sqlldr $DB_USER@$DB_NAME control=../SQL/bank1.ctl data=$WORKING_DIR/bank1.txt log=$LOGDIR/bank1_$CURR_DATE.log  bad=$LOGDIR/bank1_$CURR_DATE.bad rows=100

echo $DB_PASS | sqlldr $DB_USER@$DB_NAME control=../SQL/bank2.ctl data=$WORKING_DIR/bank2.txt log=$LOGDIR/bank2_$CURR_DATE.log bad=$LOGDIR/bank2_$CURR_DATE.bad rows=100

mv $WORKING_DIR/$FILENAME $WORKING_DIR/bank_$CURR_DATE.dat
mv $WORKING_DIR/bank3.txt $LOGDIR/bank3_$CURR_DATE.txt

