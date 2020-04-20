#!/bin/#!/usr/bin/env bash

# Test if the Elasticsearch on provided IP is up
# Read IP from argument

if [ "$1" == "" ]; then
  echo "usage $0: <Elasticsearch_IP_Address>"
  exit 1
fi

public_node_ip=$1

check_es_cluster() {
  # If cluster does not form correctly check all below
  ## ES cluster bootstrap (NOTE: node_names must be equal to dns names)
  # 1. stop
  # 2. remove data from data.path on all nodes
  # 3. cluster start on all nodes
  number_of_nodes="$(curl -s -X GET "${public_node_ip}:9200/_cluster/health?wait_for_status=yellow&timeout=50s&pretty"|jq -r .number_of_nodes)"
  if [ "${number_of_nodes}" == "3" ]; then
    echo "INFO: Elastic Cluster formed correctly."
  else
    echo "WARN: Custer didn't form"
  fi
}
check_es_status() {
  es_status="$(curl -s -X GET "${public_node_ip}:9200/_cluster/health?wait_for_status=yellow&timeout=50s&pretty"|jq -r .status)"
  if [ "${es_status}" == "red" ]; then
    echo "ERR: Elasticsearch status: ${es_status}"
    exit 1
  else
    echo "INFO: Elasticsearch status: ${es_status}"
  fi

  if [ "${es_status}" == "" ]; then
    echo "ERR: cannot ready ES server status"
    exit 1
  fi
}

# MAIN
check_es_cluster
check_es_status
