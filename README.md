# Apigee AI Gateway Lab
This lab guides the user through templating a complete AI Gateway to manage & govern the usage of models, tools & agents in the organization.

## Step 1: Prerequisites
You will need a **Google Cloud Project** with the project permissions to provision [Apigee]([url](https://cloud.google.com/apigee)) and a [Google Cloud Load Balancer]([url](https://cloud.google.com/load-balancing)) to ingest traffic.

To begin, open the [Google Cloud Shell](https://docs.cloud.google.com/shell), or another shell with the [gcloud](https://cloud.google.com/cli) and [Terraform](https://developer.hashicorp.com/terraform/install) CLIs installed.

Set your **Google Cloud Project** and **Region** as environment variables in your shell.

```sh
GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID
GOOGLE_CLOUD_LOCATION=YOUR_REGION
```
Setting the variables in Google Cloud Shell:

![Google Cloud Shell Environment Variables](https://raw.githubusercontent.com/tyayers/public-files/refs/heads/main/apigee/apigee-aigw-shell1.png)

## Step 2: Provision Apigee in your Google Cloud project
Apigee X can easily be provisioned in Google Cloud either as a **Trial (60 days)**, **Pay-as-you-go**, or **Subscription** org. See [here](https://docs.cloud.google.com/apigee/docs/api-platform/get-started/provisioning-options) for more details. 

You will need a provisioned org before proceeding with this lab.

To provision Apigee with [Terraform](url) in your project:

```sh
BILLING_ID=YOUR_BILLING_ID
cd ./tf/provision
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "billing_id=$BILLING_ID" \
--var-file=variables.tfvars
cd ../..
```

To provision with the wizard in the Google Cloud console:

![Apigee provisioning wizard](https://raw.githubusercontent.com/tyayers/public-files/refs/heads/main/apigee/apigee-aigw-provision.png)

## Step 3: Create and deploy AI model proxies
A **proxy** in Apigee transfers, secures & mediates any type of network API traffic, so to start we're going to secure the **AI model** access.

There are a many ways to create and deploy proxies in Apigee. In this lab, we are going to demonstrate 2 ways, using **Proxy Templates** and **Terraform** deployments.

Let's first get the environment information from our Apigee org using the [apigeecli](https://github.com/apigee/apigeecli) command-line tool.

```sh
# install apigeecli
curl -L https://raw.githubusercontent.com/apigee/apigeecli/main/downloadLatest.sh | sh -

APIGEE_ENVIRONMENT=$(apigeecli environments list -o $PROJECT_ID --default-token | jq --raw-output '.[0]')
echo $APIGEE_ENVIRONMENT
APIGEE_HOST=$(apigeecli envgroups list -o $PROJECT_ID --default-token | jq --raw-output '.environmentGroups[0].hostnames[-1]')
echo $APIGEE_HOST
```

Now let's create an AI proxy in Apigee for Gemini from a YAML template.

```sh
# install apigee feature templater (aft) globally
npm i apigee-templater -g

# deploy the AI-Gemini template to our Apigee org
aft -i AI-Gemini.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Gemini:$APIGEE_ENVIRONMENT
```

Add authn/authz, cors, model armor security, pii masking, and some other features.

```sh
aft -a AI-Auth.yaml AI-Gemini.yaml
aft -a AI-Caching.yaml AI-Gemini.yaml
aft -a AI-PII-Masking.yaml AI-Gemini.yaml
aft -a CORS.yaml AI-Gemini.yaml
# deploy again
aft -i AI-Gemini.yaml -o $GOOGLE_CLOUD_PROJECT:AI-Gemini:$APIGEE_ENVIRONMENT
```

We can also convert the YAML to a native Apigee bundle, and apply it to our org using Terraform.

```sh
aft -i AI-Gemini.yaml -o ./AI-Gemini.zip
cd ./tf/proxies
terraform init
terraform apply
cd ../..
```

TODO
- test proxy with auth, product, security, etc...

## Step 4: Use AI model proxy in Gemini CLI and Claude Code

TODO
* Configure gemini cli to use Apigee proxy
* Make some calls, view analytics in Apigee console
* View analytics in AI Portal

## Step 5: Create and deploy AI tool proxies

TODO
* Deploy some tool proxies (REST, MCP, REST-TO-MCP)
* See how they are visible in Apigee & API Hub.

## Step 6: Create and deploy AI agent proxies

TODO
* Deploy some agent proxies (A2A)
* See how they are visisble in Apigee & API Hub, use and debug them.

## Step 7: Wrap up

TODO
* Review topics
