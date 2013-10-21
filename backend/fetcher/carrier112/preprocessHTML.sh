#!/bin/bash

for x in *.html ; do
	# Ignore if it's not SHIFT-JIS or is already UTF-8:
	if grep -Fiq shift_jis ${x} && [[ "$(file -bi ${x})" != *utf-8* ]] ; then
		# Back-up:
		mv ${x} ${x/.html/_shiftjis.html}
		iconv -c -f SHIFT-JIS -t UTF-8 ${x/.html/_shiftjis.html} > ${x}
		sed -i 's/"text\/html; charset=shift_jis"/"text\/html; charset=utf-8"/I' ${x}
	fi
done


