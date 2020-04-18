#!/bin/bash

# default path to our configuration file
CONFIG=$(dirname $0)/plex-storage-report.conf
# array housing regular expressions to search for; set the key to the expression name and value to the expression
declare -A REGEXS
# default minimum age for files to be operated on if not specified (4 weeks, 1 day)
DEFAULT_MIN_AGE_SEC=2505600
# arguments for `find`
FIND_CMD_ARGS="-not -newer $AGE_FILE"

# help page
usage () {
	cat <<- EOF
	Usage: $(basename $0) [options]

	Options:
	  -d			Run report and delete all files found
	  -b	[directory]	Base directory to operate on
	  -c	[file]		Configuration file to use (default: $CONFIG)
	  -d	[seconds]	Minumum age a file must be to be operated on (default: $DEFAULT_MIN_AGE_SEC)
	  -h			Display usage (this page)

	Configuration:
	  BASE_DIR=		[directory]		Base directory to operate on
	  DELETE=		[integer]		(if set to 1) Delete all files found
	  MIN_AGE_SEC=		[seconds]		Minimum age a file must be to be operated on
	  DIRS_TO_PROCESS=	[directory]		Indexed array of directories to process under \$BASE_DIR
	  REGEXS=		["label"]="[regex]"	Associative array of regular expressions to use for processing

	Regular Expressions (for REGEXS):
	  [label]	[text]		Label name for the expression, this is seen in the generated report
	  [regex]	[text]		Pattern to match; all patterns are auto-prefixed with \* and are case-insensitive

	  Example:  REGEXS=( ["trailers"]="theatrical\ trailer*" )
	    - Matches all files with the word "theatrical trailer" in them
	EOF
}

# process flags (if any)
while getopts ":hdb:c:d:" ARG; do
	case $ARG in
		d )	DELETE=1 ;;
		b )	BASE_DIR=$OPTARG ;;
		c )	CONFIG=$OPTARG ;;
		d )	MIN_AGE_SEC=$OPTARG ;;
		h )	usage; exit 100 ;;
	esac
done

# import our configuration
[ -f "$CONFIG" ] && . $CONFIG || { echo "Error: configuration not found: $CONFIG"; exit 2 ;}

# bail out if BASE_DIR is not found mentally or physically
[ -n "$BASE_DIR" ] || { echo "Error: base directory not specified"; usage; exit 3 ;}
[ -d "$BASE_DIR" ] || { echo "Error: base directory not found: $BASE_DIR"; exit 4 ;}
# strip a trailing slash to make the reports prettier
BASE_DIR=${BASE_DIR/%\/}

# set DIRS_TO_PROCESS to all sub-directories if not specified
[ -n "$DIRS_TO_PROCESS" ] || DIRS_TO_PROCESS=( $(for DIR in $BASE_DIR/*; do [ $DIR = $BASE_DIR ] || [ -f $DIR ] || echo $(basename $DIR);done ) )

# reference file that will be created which contains the timestamp no other file should be newer than
AGE_FILE=$BASE_DIR/.ts_reference
# apply default minimum age if not otherwise specified
: ${MIN_AGE_SEC:=$DEFAULT_MIN_AGE_SEC}

echo
echo "Operating on files older than: $(date -d @$(( $(date +%s) - $MIN_AGE_SEC )))"
[ ! -f "$AGE_FILE" ] || rm -f $AGE_FILE
touch -t $(date -d @$(( $(date +%s) - $MIN_AGE_SEC )) +%Y%m%d%H%M) $AGE_FILE

# stat variables
TOTAL_START=$SECONDS
TOTAL_USAGE=0
TOTAL_FILE_COUNT=0

# list of files that will be deleted if ran in the appropriate mode
FILES_TO_DELETE=()

for DIR in "${DIRS_TO_PROCESS[@]}";do
	# stat variables
	DIR_USAGE=0
	DIR_FILE_COUNT=0
	DIR_START=$SECONDS
	echo
	echo + Processing directory: $BASE_DIR/$DIR

	for REGEX in "${!REGEXS[@]}"; do
		# stat variables
		REGEX_USAGE=0
		REGEX_FILE_COUNT=0
		REGEX_START=$SECONDS
		echo -n "  ++ Processing pattern: $REGEX ... "
		while read; do 
			[[ ! -z "$REPLY" ]] || continue
			REGEX_USAGE=$(( $REGEX_USAGE + $(stat -c %s "$REPLY") ))
			(( REGEX_FILE_COUNT++ ))
			FILES_TO_DELETE+=( "$REPLY" )
		done <<< "$(find $BASE_DIR/$DIR $FIND_CMD_ARGS -iname \*"${REGEXS[$REGEX]}" 2>/dev/null)"
#		echo find $BASE_DIR/$DIR $FIND_CMD_ARGS -iname \*"${REGEXS[$REGEX]}"
		echo "$(numfmt --to=iec-i --suffix=B $REGEX_USAGE) in $REGEX_FILE_COUNT files ($(( $SECONDS - $REGEX_START )) seconds)"
		DIR_USAGE=$(( $DIR_USAGE + REGEX_USAGE ))
		DIR_FILE_COUNT=$(( $DIR_FILE_COUNT + $REGEX_FILE_COUNT ))
	done
	TOTAL_USAGE=$(( $TOTAL_USAGE + $DIR_USAGE ))
	TOTAL_FILE_COUNT=$(( $TOTAL_FILE_COUNT + $DIR_FILE_COUNT ))
	echo "  Reclaimable space from $BASE_DIR/$DIR: $(numfmt --to=iec-i --suffix=B $DIR_USAGE) in $DIR_FILE_COUNT files ($(( $SECONDS - $DIR_START )) seconds)"
done

echo "Total reclaimable space from $BASE_DIR: $(numfmt --to=iec-i --suffix=B $TOTAL_USAGE) in $TOTAL_FILE_COUNT files"
echo

if [ "$DELETE" -ne 1 ]; then
	echo "${#FILES_TO_DELETE[*]} files waiting to be deleted, processed in $(( $SECONDS - $TOTAL_START )) seconds"
	echo
else
	echo -n "+ Removing files ... "
	for FILE in "${FILES_TO_DELETE[@]}"; do
		/bin/rm "$FILE"
	done
	echo "[DONE]"
	echo "${#FILES_TO_DELETE[*]} files deleted, processed in $(( $SECONDS - $TOTAL_START )) seconds"
	echo
fi
