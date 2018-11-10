#!/usr/bin/env bash

# Search for the requirements defined in FILE
# on HOMEASSISTANT_REQS in order to get the
# new versions

FILE="docker/requirements.txt"
HOMEASSISTANT_REQS="home-assistant/requirements_all.txt"

while read -r line;
do
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^#.*$ ]] && continue
    req=$(echo ${line} | cut -d'=' -f 1)

    awk -v r=${req} '
    BEGIN{
        found=0;
    }
    !/(^#.*$)|(^\s*$)/{
        split($1,a,"=");
        if (a[1] == r) {
          found=1;
          while ((getline reqs) > 0)
            if (reqs ~ /^#/) print reqs;
            else break;
          print $1"\n";
        }
    }
    END{
        if (found == 0)
            print "# ERROR: "r"\n";
    }' < <(tac ${HOMEASSISTANT_REQS})
done < ${FILE}

