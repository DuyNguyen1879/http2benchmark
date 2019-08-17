#!/usr/bin/env bash
# /********************************************************************
# HTTP2 Benchmark Parse Script
# *********************************************************************/

TEST_RAN='N/A'
SERVER_NAME='N/A'
SERVER_VERSION='N/A'
BENCHMARK_TOOL='N/A'
APPLICATION_PROTOCOL='N/A'
CONCURRENT_CONNECTIONS='N/A'
CONCURRENT_STREAMS='N/A'
URL='N/A'
TOTAL_TIME_SPENT='N/A'
REQUESTS_PER_SECOND='N/A'
BANDWIDTH_PER_SECOND='N/A'
TOTAL_BANDWIDTH='N/A'
TOTAL_REQUESTS='N/A'
TOTAL_FAILURES='N/A'
STATUS_CODE_STATS='N/A'
HEADER_COMPRESSION='N/A'

function parse_wrk() {
  local ITERATION="$1"
  CONCURRENT_CONNECTIONS=$(grep 'connections' ${LOG_FILE}.${ITERATION} | awk '{print $4}')
  TOTAL_TIME_SPENT=$(grep 'requests in' ${LOG_FILE}.${ITERATION} | awk '{print $4}' | sed 's/.$//')
  REQUESTS_PER_SECOND=$(grep 'Requests/sec:' ${LOG_FILE}.${ITERATION} | awk '{print $2}')
  BANDWIDTH_PER_SECOND=$(grep 'Transfer/sec:' ${LOG_FILE}.${ITERATION} | awk '{print $2}')
  TOTAL_BANDWIDTH=$(grep 'requests in' ${LOG_FILE}.${ITERATION} | awk '{print $5}')
  TOTAL_REQUESTS=$(grep 'requests in' ${LOG_FILE}.${ITERATION} | awk '{print $1}')
}

function parse_h2load() {
  local ITERATION="$1"
  APPLICATION_PROTOCOL=$(grep 'Application protocol:' ${LOG_FILE}.${ITERATION} | awk '{print $3}')
  TLS_PROTOCOL=$(grep 'TLS Protocol:' ${LOG_FILE}.${ITERATION} | awk '{print $3}')
  CIPHER=$(grep 'Cipher:' ${LOG_FILE}.${ITERATION} | awk '{print $2}')
  SERVER_TEMP_KEY=$(awk -F ': ' '/Server Temp Key:/ {print $2}' ${LOG_FILE}.${ITERATION} | sed -e 's| |-|g')
  CONCURRENT_CONNECTIONS=$(grep 'total client' ${LOG_FILE}.${ITERATION} | awk '{print $4}')
  TOTAL_TIME_SPENT=$(grep 'finished in' ${LOG_FILE}.${ITERATION} | awk '{print $3}' | sed 's/.$//')
  REQUESTS_PER_SECOND=$(grep 'finished in' ${LOG_FILE}.${ITERATION} | awk '{print $4}' | sed 's/.$//')
  BANDWIDTH_PER_SECOND=$(grep 'finished in' ${LOG_FILE}.${ITERATION} | awk '{print $6}' | sed 's/.$//' | sed 's/.$//')
  TOTAL_BANDWIDTH=$(grep 'traffic:' ${LOG_FILE}.${ITERATION} | awk '{print $2}')
  TOTAL_REQUESTS=$(grep 'requests:' ${LOG_FILE}.${ITERATION} | awk '{print $2}')
  #HEADER_SPACESAVINGS=$(grep 'space savings' ${LOG_FILE}.${ITERATION} |  grep -oP '\(\K[^\)]+' | awk '/^space savings/ {print $3}')
  local TOTAL_SUCCESS=$(grep 'requests:' ${LOG_FILE}.${ITERATION} | awk '{print $8}')
  if [[ ${TOTAL_REQUESTS} != ${TOTAL_SUCCESS} ]]; then
    TOTAL_FAILURES=$(( ${TOTAL_REQUESTS} - ${TOTAL_SUCCESS} ))
  else
    TOTAL_FAILURES='0'
  fi
  STATUS_CODE_STATS=$(grep 'status codes:' ${LOG_FILE}.${ITERATION} | perl -pe "s/status codes: (.*?)/\1/")
  HEADER_COMPRESSION=$(grep 'traffic:' ${LOG_FILE}.${ITERATION} | awk '{print $10}' | grep -Po '[0-9]+.[0-9]+')
  TTFB_MIN=$(grep '^time to 1st byte:' ${LOG_FILE}.${ITERATION} | xargs | awk '{print $5}')
  TTFB_MEAN=$(grep '^time to 1st byte:' ${LOG_FILE}.${ITERATION} | xargs | awk '{print $6}')
  TTFB_MAX=$(grep '^time to 1st byte:' ${LOG_FILE}.${ITERATION} | xargs | awk '{print $7}')
  TTFB_SD=$(grep '^time to 1st byte:' ${LOG_FILE}.${ITERATION} | xargs | awk '{print $8}')
}

function generate_csv() {
  local ITERATION="${1}"
  if [[ ! -f ${WORKING_PATH}/RESULTS.csv ]]; then
    printf "Test Ran,Iteration,Log File,Server Name,Server Version,Benchmark Tool,Concurrent Connections,Concurrent Streams,URL,Application Protocol,TLS Protocol,Cipher,Server Temp Key,Total Time Spent,Requests Per Second,Bandwidth Per Second,Total Bandwidth,Total Requests,Total Failures,Header Compression,Status Code Stats,TTFB Min, TTFB Avg, TTFB Max, TTFB SD\n" >> ${WORKING_PATH}/RESULTS.csv
  fi
    printf "${TEST_RAN},${ITERATION},${LOG_FILE},${SERVER_NAME},${SERVER_VERSION},${BENCHMARK_TOOL},${CONCURRENT_CONNECTIONS},${CONCURRENT_STREAMS},${URL},${APPLICATION_PROTOCOL},${TLS_PROTOCOL},${CIPHER},${SERVER_TEMP_KEY},${TOTAL_TIME_SPENT},${REQUESTS_PER_SECOND},${BANDWIDTH_PER_SECOND},${TOTAL_BANDWIDTH},${TOTAL_REQUESTS},${TOTAL_FAILURES},${HEADER_COMPRESSION},${STATUS_CODE_STATS},${TTFB_MIN},${TTFB_MEAN},${TTFB_MAX},${TTFB_SD}//,}\n" >> ${WORKING_PATH}/RESULTS.csv
}

function pretty_display() {
  local ITERATION="${1}"
  cat >> ${WORKING_PATH}/RESULTS.txt << EOF
############### ${TEST_RAN}.${ITERATION} ###############
Server Name:            ${SERVER_NAME}
Server Version:         ${SERVER_VERSION}
Benchmark Tool:         ${BENCHMARK_TOOL}
URL:                    ${URL}
Application Protocol:   ${APPLICATION_PROTOCOL}
TLS Protocol:           ${TLS_PROTOCOL}
Cipher:                 ${CIPHER}
Server Temp Key:        ${SERVER_TEMP_KEY}
Total Time Spent:       ${TOTAL_TIME_SPENT}
Concurrent Connections: ${CONCURRENT_CONNECTIONS}
Concurrent Streams:     ${CONCURRENT_STREAMS}
Total Requests:         ${TOTAL_REQUESTS}
Requests Per Second:    ${REQUESTS_PER_SECOND}
Total Bandwidth:        ${TOTAL_BANDWIDTH}
Bandwidth Per Second:   ${BANDWIDTH_PER_SECOND}
Total Failures:         ${TOTAL_FAILURES}
Status Code Stats:      ${STATUS_CODE_STATS}
Header Compression:     ${HEADER_COMPRESSION}%
TTFB Min:               ${TTFB_MIN}
TTFB Avg:               ${TTFB_MEAN}
TTFB Max:               ${TTFB_MAX}
TTFB SD:                ${TTFB_SD}

EOF
}

function main() {
  if [[ $1 == '' ]]; then
    exit 1
  else
    if [[ $# -lt 6 ]]; then
      exit 1
    else
      BENCHMARK_TOOL="$1"
      URL="$2"
      WORKING_PATH="$3"
      LOG_FILE="${WORKING_PATH}/$4"
      TEST_RAN="$5"
      SERVER_NAME="$6"
      SERVER_VERSION="$7"
      ITERATIONS="$8"
      CONCURRENT_STREAMS="$9"
    fi
  fi

  for (( ITERATION = 1; ITERATION<=${ITERATIONS}; ITERATION++)); do
    if [[ ${BENCHMARK_TOOL} == 'h2load' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-low' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-m80' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-ecc128' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-low-ecc128' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-m80-ecc128' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-ecc256' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-low-ecc256' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-m80-ecc256' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-rsa128' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-low-rsa128' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-m80-rsa128' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-rsa256' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-low-rsa256' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'h2load-m80-rsa256' ]]; then
      parse_h2load ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'wrk' ]]; then
      parse_wrk ${ITERATION}
    elif [[ ${BENCHMARK_TOOL} == 'wrkcmm' ]]; then
      parse_wrk ${ITERATION}
    fi

    generate_csv "${ITERATION}"
    pretty_display "${ITERATION}"
  done

  exit 0
}

main "$@"