# AI Gateway Tools Lab
![Gemini proxy debug](https://amalbagee.web.app/apigee/ai-tools-gov1.png)

---

In this lab you will add tool goverance & integration to the **AI Gateway** that you created in the first **Foundations Lab**.

Let's get started!

---

### Set Environment Variables

<img src="https://iili.io/C9AvqyN.png" />

1. **Copy** the `./sh/env.sh` file to a local `.env` file by running this command.

```sh
cp --update=none ./sh/env.sh .env
```

2. **Click**  <walkthrough-editor-open-file filePath=".env">here</walkthrough-editor-open-file> to open the `.env` file in the editor.

3. After **saving** your changes, load the variables by running these commands:

```sh
source .env
source ./sh/script_get_apigee.sh
```

### Install Tooling

Just in case they are no longer installed:
```sh
npm i apigee-templater -g
```
