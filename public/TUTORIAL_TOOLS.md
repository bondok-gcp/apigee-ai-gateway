# AI Gateway Tools Lab
![Gemini proxy debug](https://amalbagee.web.app/apigee/ai-tools-gov1.png)

---

In this lab you will add tool goverance & integration to the **AI Gateway** that you created in the first **Foundations Lab**.

Let's get started!

---

## Set Environment Variables

<img src="https://iili.io/C9AvqyN.png" />

1. **Copy** the `./sh/env.sh` file to a local `.env` file by running this command.

```sh
cp --update=none ./sh/env.sh .env
```

2. **Click**  <walkthrough-editor-open-file filePath=".env">here</walkthrough-editor-open-file> to open the `.env` file in the editor.

3. After **saving** your changes, install the [aft tool](https://github.com/apigee/apigee-templater) and load the variables by running these commands:

```sh
npm install apigee-templater -g
source .env
source ./sh/script_get_apigee.sh
```

## Provision API Hub (if not already provisioned)

[![API Hub](https://amalbagee.web.app/apigee/apihub1.png)](https://amalbagee.web.app/apigee/apihub1.png)

[Apigee API Hub](https://docs.cloud.google.com/apigee/docs/apihub/what-is-api-hub) is a universal repository for any type of API, and so will be used in this lab to manage and store the AI tools' metadata and schemas.

In case API Hub is not already provisioned in your **Google Cloud Project**, then you can easily provision it with this **Terraform** command and entering **yes** after reviewing the changes:

```sh
cd tf/hub
terraform init
terraform apply -var "project_id=$GOOGLE_CLOUD_PROJECT" -var "region=$GOOGLE_CLOUD_LOCATION"
cd ../..
source ./sh/script_hub_init.sh
```

Provisioning usually takes 10-15 minutes.

At the moment you also need to manually configure the attachment for Apigee X, so [open the console](https://console.cloud.google.com/apigee/api-hub/settings/project-associations) and make sure that **Apigee X and Hybrid** is configured under **Associated plugins**. If it's blank, click on **Edit settings** and click **Apigee X and Hybrid**, and then save.

![API Hub plugin configuration](https://amalbagee.web.app/apigee/apihub-plugins1.png)

## Add Tools to Catalog

If you [open the API Hub console](https://console.cloud.google.com/apigee/api-hub/apis), you should see the **AI model proxies** that we deployed in the **Foundations Lab**.

[![API Hub Catalog](https://amalbagee.web.app/apigee/apihub-catalog1.png)](https://amalbagee.web.app/apigee/apihub-catalog1.png)
