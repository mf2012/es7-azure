# es7-azure
Minimal installation of Elasticsearch 7.x on Free Tier Azure with 3xStandard_D1 nodes

# Elastic Search on Azure - Infrastructure as Code
1. Stand up an elastic search instance using Terraform on Azure
2. Stand up Azure Event Hubs on Azure using Terraform
3. Single Azure Function sending stack traces into elastic search every time it is invoked
4. Show scripts or automated tests to validate the deployment


# Possible solutions on Azure:
1. TF Fully blown ES cluster + TF Event Hubs + FaaS - ES not possible to execute on Azure Free Tier due to Limit per region: 4 core, 16GB RAM
2. TF with K8s(AKS) template + Helm ELK charts + TF Event/Serverless - ES not possible to execute on Azure Free Tier due to Limit per region: 4 core, 16GB RAM
3. TF IaaS (ES, Event hub) + Ansible for config + Serverless for FaaS - ES on 3x Standard_D1 nodes with TF + Ansible to configure cluster + logstash as an aggregator + Serverless for Python App

**Due to Azure free tier limitations only solution 3 is viable**
- no loadbalancers for ES ingestion/Logstash/Kibana - only HAProxy possible
- Azure's machine_scale_set limit is too small on Free Tier


# Desired Event Flow Architecture

Event -> App -> Eventhub -> BLOBStorage -> Logstash -> Elasticsearch


# Desired UI Client Access

Browser -> SSL Proxy -> Kibana -> Elasticsearch

# Desired API Client Access?


# DONE:
* TF deployment of 3 nodes with permanent container storage for Elasticsearch cluster
* bootstrap.sh for Elasticsearch, Logstash, Kibana packages
* Eventhub created - no BLOB Storage for Logstash ATM
* Basic configurations, Public IPs, Private IPs

# TODO:
* Elasticsearch configuration of a cluster - TF or Ansible needs to set all node IPs
* TF pass the Eventhub's BLOBStorage output endpoint for logstash
* send_event app needs to get the Eventhub's input endpoint
* Serverless definition YAML for app
* Test validation scripts for each stage (ES, Kibana, Logstash, Eventhub - TF can use depends on with null_resource test scripts Note:Split TF repo into stages - this would probably get rid of a need for Ansible configuration)
* End-to-end test validation (ideal would be API call to Function with payload then request elastic to confirm if the same event with matching hash has been delivered and has the same payload, can use Bash/curl/jq or full Python)
* Security hardening: SSL certs, SSH ciphers, etc - lynis check, Lestencrypt SSL cert for Kibana
