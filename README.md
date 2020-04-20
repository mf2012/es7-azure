# es7-azure
Minimal installation of Elasticsearch 7.x on Free Tier Azure with 3xStandard_D1 nodes

### Task 1 Elastic Search on Azure - Infrastructure as Code
1. Stand up an Elasticsearch instance using Terraform on Azure
2. Stand up Azure Event Hubs on Azure using Terraform
3. Single Azure Function sending stack traces into Elasticsearch every time it is invoked
4. Show scripts or automated tests to validate the deployment

### Task 2 Check elastic cluster
1. Take Go server from the Gitlab repo and hook it directly to Elastic cluster
2. Run Go client with load and check how ES cluster performs (we are still in Free Tier)

### Possible solutions on Azure
1. TF Fully blown ES cluster + TF Event Hubs + FaaS - ES not possible to execute on Azure Free Tier due to Limit per region: 4 core, 16GB RAM
2. TF with K8s(AKS) template + Helm ELK charts + TF Event/Serverless - ES not possible to execute on Azure Free Tier due to Limit per region: 4 core, 16GB RAM
3. TF IaaS (ES, Event hub) + TF/Serverless for FaaS - ES on 3x Standard_D1 nodes with TF + logstash as an aggregator + Serverless for Python App

**Due to Azure free tier limitations only solution 3 is viable**
- Azure's machine_scale_set limit is too small on Free Tier

### Desired Event Flow Architecture
- Basic: Event -> App -> Logstash -> Elasticsearch
- Extended: Event -> App -> Eventhub -> BLOBStorage -> Logstash -> Elasticsearch (if time allows)

### Desired UI Client Access
Browser -> SSL Proxy -> Kibana -> Elasticsearch

### Desired API Client Access
Elasticsearch - Task 2

### DONE:
* TF deployment of 3 nodes with permanent container storage for Elasticsearch cluster
* Elasticsearch configuration of a cluster with TF
* bootstrap.sh for Elasticsearch, Logstash, Kibana packages
* TF Eventhub's BLOBStorage output endpoint for logstash
* Test validation scripts: Elasticsearch


### TODO:
* Azure Function with TRACE
* Send TRACE from the Function App to Elasticsearch (direct or via logstash)
* Bash script with curl to drive Function exec in Azure's FunctionApp
* Test validation scripts: Eventhub (TF can use depends on with null_resource test scripts Note:Split TF repo into stages, if required)
* End-to-end test validation (ideal would be API call to Function, and check in ES if new event is being registered - Bash/Python/jq)
* Security hardening: Encrypt all the traffic, Add Authentication to ES, Use SSL Lestencrypt SSL cert for Kibana, Encrypt data at rest (enable encryption on storage in Azure)
