#!/bin/bash - 
#===============================================================================
#
#		  USAGE: ./this.sh --help
# 
#	DESCRIPTION: Markup a text for proper speech synthesis with SSML for
#		     Amazon Polly.
# 
#          REQUIREMENTS: sed
#		 AUTHOR: Sylvain Saubier (ResponSyS), mail@sylsau.com
#		CREATED: 01/05/16 14:09
#===============================================================================

[[ $DEBUG ]] && set -o nounset
set -o pipefail -o errexit -o errtrace
trap 'echo -e "${FMT_BOLD}ERROR${FMT_OFF}: at $FUNCNAME:$LINENO"' ERR

readonly FMT_BOLD='\e[1m'
readonly FMT_UNDERL='\e[4m'
readonly FMT_OFF='\e[0m'

readonly PROGRAM_NAME="${0##*/}"
readonly SCRIPT_NAME="${0##*/}"
RES="$( stat -c %y $0 | cut -d" " -f1 )"
readonly VERSION=${RES//-/}

readonly ERR_NO_CMD=60

SED="${SED:-sed}"
OPT_OUTFILE=
OPT_PARA_BREAK=1s
OPT_RATE=slow
INPUT=

# $1 = command to test (string)
fn_need_cmd() {
	if ! command -v "$1" > /dev/null 2>&1
		then fn_err "need '$1' (command not found)" $ERR_NO_CMD
	fi
}
# $1 = message (string)
m_say() {
	echo -e "$PROGRAM_NAME: $1"
}
# $1 = error message (string), $2 = return code (int)
fn_err() {
	m_say "${FMT_BOLD}ERROR${FMT_OFF}: $1" >&2
	exit $2
}

fn_help() {
	cat << EOF
$PROGRAM_NAME v$VERSION
	Format a marked up text for proper speech synthesis with SSML for Amazon Polly. 
REQUIREMENTS
	sed
USAGE
	$PROGRAM_NAME FILES... [--output|-o OUTFILE] [-b BREAK_TIME] [-r BREAK_TIME]
OPTIONS AND ARGUMENTS
	OUTFILE 		filename of output file (overwrite if existing)
				(default: {INPUT_FILENAME}.ssml)
	BREAK_TIME 		duration of pauses between paragraphs, in seconds or milliseconds.
				(format: "{number}{s|ms}")
				(default: 1s)
	RATE 			Speaking rate of the whole text, either "x-slow", "slow", "medium", "fast" or "x-fast"
				(default: slow)
MARKUP FORMAT
	Each newline delimits a paragraph, marked ith <p> tags. 
	Here are the SSML tags and their corresponding markup:
		<prosody rate="slow">...</prosody>
			↳	{...{
		<prosody rate="fast">...</prosody>
			↳	}...}
		<prosody volume="soft">...</prosody>
			↳ 	_..._
		<prosody volume="loud">...</prosody>
			↳ 	*...*
		<s>
			↳ 	|...|
		<break time=XXs/>
			↳ 	#XX
			If a line starts with #, it will not be marked as a paragraph.
	(The following are not yet implemented:)
		<prosody pitch="±XX%">...</prosody>
			↳ 	=±XX...=
		<lang xml:lang="xx-XX">...</lang>
			↳ 	\`xx-XX...\`
		<phoneme alphabet="ipa" ph="XXX">...</phoneme>
			↳ 	~XXX...~
EXAMPLE
	$ $PROGRAM_NAME nietzsche-genealogy-of-morals.txt -o GoM-ssml.txt
AUTHOR
	Written by Sylvain Saubier
REPORTING BUGS
	Mail at: <feedback@sylsau.com>
EOF
}


fn_need_cmd "$SED"

# Check args
if [[ -z "$@" ]]; then
	fn_help 
	exit
else
	while [[  $# -gt 0 ]]; do
		case "$1" in
		 	"--help"|"-h")
				fn_help
				exit
				;;
			"--output"|"-o")
				OPT_OUTFILE=$2
				shift
				;;
			"--break"|"-b")
				OPT_PARA_BREAK=$2
				shift
				;;
			"--rate"|"-r")
				OPT_RATE=$2
				shift
				;;
			*)
				[[ -e "$1" ]] || fn_err "file '$1' does not exist" 127
				INFILE=$1
				;;
		esac	# --- end of case ---
		shift 	# delete $1
	done
fi

[[ $INFILE ]] || fn_err "please specify an input file" 127

# Créer le nom du fichier de sortie si besoin
[[ "$OPT_OUTFILE" ]] || OPT_OUTFILE="$INFILE.ssml"

[[ $DEBUG ]] && echo "$INFILE | $OPT_OUTFILE" && exit

m_say "formatting text..."
$SED 's/^\([^#].\+\)$/<p>\1<\/p>/ ;
	s/{\([^{]\+\){/<prosody rate="slow">\1<\/prosody>/g ;
	s/}\([^}]\+\)}/<prosody rate="fast">\1<\/prosody>/g ;
	s/_\([^_]\+\)_/<prosody volume="soft">\1<\/prosody>/g ;
	s/\*\([^\*]\+\)\*/<prosody volume="loud">\1<\/prosody>/g ;
	s/|\([^|]\+\)|/<s>\1<\/s>/g ;
	s/#\(\w\+\)/<break time="\1"\/>/g ;
	s/<\/p>/<\/p><break time="'$OPT_PARA_BREAK'"\/>/ ;
	1i<speak><prosody rate="'$OPT_RATE'>\n' \
	$INFILE > $OPT_OUTFILE && echo -e "\n</prosody></speak>" >> $OPT_OUTFILE
m_say "all done!"

exit
