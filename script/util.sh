#!/bin/bash - 
#===============================================================================
#
#          FILE: util.sh
# 
#         USAGE: ./util.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Nick Shevelev (Beggy), BeggyCode@gmail.com
#  ORGANIZATION: BeggyCode
#       CREATED: 02.10.2019 21:24:02
#      REVISION:  ---
#===============================================================================


#===  FUNCTION  ================================================================
#          NAME:  assertNotEmpty
#   DESCRIPTION:  
#    PARAMETERS:  value propertyName
#       RETURNS:
#===============================================================================
function assertNotEmpty () {
    if [[ -z "$1" ]]; then
        [[ -n "$2" ]] && echo "$2 is undefined" >&2
        return 1
    fi
    return 0
}
# ----------  end of function assertNotEmpty  ----------


#===  FUNCTION  ================================================================
#          NAME:  assertReadableFile
#   DESCRIPTION:  
#    PARAMETERS:  value propertyName
#       RETURNS:
#===============================================================================
function assertReadableFile () {
    assertNotEmpty "$1" "$2" || return 1
    if [[ ! -r "$1" ]]; then
        [[ -n "$2" ]] && echo "$2 is not readable" >&2
        return 1
    fi
    return 0
}
# ----------  end of function assertReadableFile  ----------


#===  FUNCTION  ================================================================
#          NAME:  assertExistingDirectory
#   DESCRIPTION:  
#    PARAMETERS:  value propertyName
#       RETURNS:
#===============================================================================
function assertExistingDirectory () {
    assertNotEmpty "$1" "$2" || return 1
    if [[ ! -d "$1" ]]; then
        [[ -n "$2" ]] && echo "$2 is not directory" >&2
        return 1
    fi
    return 0
}
# ----------  end of function assertExistingDirectory  ----------

