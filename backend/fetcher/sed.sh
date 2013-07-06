#!/bin/bash

if [ $# != 2 ]; then
  cat >&2 << EOH
This is how to create a duplicate of the 'locationfields' module
so that you can create another version of the fields.

Usage:
  $0 WORD locationfields.module > WORDlocationfields.module

Example:

  $0 school locationfields.module > schoollocationfields.module
  $0 school locationfields.install > schoollocationfields.install
  
  This will allow you to use a new set of fields: school_location_country,
  school_location_state, school_location_city.
EOH

exit 1
fi

WORD=$1

sed "s/locationfields/${WORD}locationfields/;
     s/group_location/group_${WORD}_location/;
     s/group-location/group-${WORD}-location/;
     s/location-update-button/${WORD}-location-update-button/;
     s/location-content-wrapper/${WORD}-location-content-wrapper/;
     s/field\([_-]\)\(country\|state\|city\)/field\1${WORD}\1\2/;
     " $2
