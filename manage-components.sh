#!/usr/bin/env bash

# Search for the components (regex) defined in FILE
# on HOMEASSISTANT_REQS in order to get the requirements
# It does not check duplicates!

FILE="components.txt"
HOMEASSISTANT_REQS="home-assistant/requirements_all.txt"

while read -r line;
do
    [[ -z "${line}" ]] && continue
    [[ "${line}" =~ ^#.*$ ]] && continue
    awk -v r="${line}" '
    BEGIN{
        print "##### "r;
        found=0;
        dependencies=0;
    }
    /^#.*$/{
      if ($1 ~ /^#/) {
        if ($2 ~ r) {
            found = 1;
            dependencies=0;
            print "# ("NR") "$2;
            while ((getline) > 0) {
                if ($0 ~ /^#/) continue;
                if ($0 ~ /^\s*$/) break;
                print $0"\n";
                dependencies+=1;
            }
            if (dependencies == 0)
                print "";
        }
      }
    }
    END{
        if (found == 0)
            print "# ERROR: "r"\n";
    }' ${HOMEASSISTANT_REQS}
done < ${FILE}

