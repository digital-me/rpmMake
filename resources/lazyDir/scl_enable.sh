# Make sure home bin directory is in PATH 
if ! [[ "${PATH}" =~ "${HOME}/bin" ]]; then
  export PATH="${HOME}/bin:${PATH}"
fi

# Store current debug flag status
WAS_TRACE=0
if [[ ${SHELLOPTS} =~ xtrace ]]; then
  WAS_TRACE=1
fi

# Activate all Software Collections - if any
test -x /usr/bin/scl || { echo "ERROR: scl util not available"; exit 1; }
OIFS=$IFS
IFS=$'\n'
SCLS=($(scl --list))
if [ ${#SCLS[@]} -ne 0 ]; then
	test $WAS_TRACE -eq 0 || set +x
  source scl_source enable "${SCLS[@]}"
  test $WAS_TRACE -eq 0 || set -x
fi
IFS=$OIFS

unset BASH_ENV PROMPT_COMMAND ENV
