#!/bin/bash

# Calling script must set ${htmlfile}
if [ -e "${htmlfile}" ] ; then

	# Ignore if it's not SHIFT-JIS or is already UTF-8:
	if grep -Fiq shift_jis ${htmlfile} && [[ "$(file -bi ${htmlfile})" != *utf-8* ]] ; then
		# Back-up:
		mv ${htmlfile} ${htmlfile/.html/_shiftjis.htm}
		iconv -c -f SHIFT-JIS -t UTF-8 ${htmlfile/.html/_shiftjis.htm} > ${htmlfile}
		sed -i 's/"text\/html; charset=shift_jis"/"text\/html; charset=utf-8"/I' ${htmlfile}
	fi

fi
