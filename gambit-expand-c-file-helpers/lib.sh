#!/bin/bash
set -eu

if [ $# -ne 1 ]; then
	echo "usage: $0 file"
	exit 1
fi

# shadow gcc:
export ORIG_GCC
ORIG_GCC=$(which gcc)
PATH=/opt/chj/bin/gambit-expand-c-file-helpers:"$PATH"


outfile="$1"_expanded.c


# hmm some hardcoded stuff:

export GSC_CC_O_GAMBCDIR_BIN=${GSC_CC_O_GAMBCDIR_BIN-/usr/local/Gambit-C/current/bin/gsc}
export GSC_CC_O_GAMBCDIR_INCLUDE=${GSC_CC_O_GAMBCDIR_INCLUDE-/usr/local/Gambit-C/current/include/}
export GSC_CC_O_GAMBCDIR_LIB=${GSC_CC_O_GAMBCDIR_LIB-/usr/local/Gambit-C/current/lib/}
export GSC_CC_O_OBJ_FILENAME=${GSC_CC_O_OBJ_FILENAME-"$(basename "$outfile")"}
export GSC_CC_O_C_FILENAME_DIR=${GSC_CC_O_C_FILENAME_DIR-"$(dirname "$1")"}
export GSC_CC_O_C_FILENAME_BASE=${GSC_CC_O_C_FILENAME_BASE-"$(basename "$1")"}
export GSC_CC_O_CC_OPTIONS=${GSC_CC_O_CC_OPTIONS-}
export GSC_CC_O_LD_OPTIONS_PRELUDE=${GSC_CC_O_LD_OPTIONS_PRELUDE-}
export GSC_CC_O_LD_OPTIONS=${GSC_CC_O_LD_OPTIONS-}
