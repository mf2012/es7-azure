#!/usr/bin/env bash


app_url="https://mf-events-test.azurewebsites.net/api/HttpTrigger1?name=Marek"

for a in $(seq 1 100); do curl ${app_url}; done
