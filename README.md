# Drupal

Drupal is content management software. It's used to make many of the websites and applications you use every day. Drupal has great standard features, like easy content authoring, reliable performance, and excellent security. But what sets it apart is its flexibility; modularity is one of its core principles. Its tools help you build the versatile, structured content that dynamic web experiences need.

This repository contains the infra-as-code components to quickly scaffold a new Drupal environment.

_Please note these artifacts are under development and subject to change._

---

### Getting Started

Before deploying the Drupal resources, the parameters file `src/parameters/main.json` needs to be updated.

#### Using locally with Azure CLI

```bash
az deployment sub create \
    --name 'Microsoft.Bicep' \
    --location 'uksouth' \
    --template-file './src/main.bicep' \
    --parameters \
      '@./src/parameters/main.json' \
    --parameters \
      username=replace \
      password=replace
```

#### Using with GitHub Actions

Azure Active Directory - Application

- Navigate to the 'App Registration' blade wihin the Azure portal
- Select 'New registration' and provide a Name for the application
- Select the newly created application and select 'Certificates & secrets'
- Select 'Federated Credentials' and 'Add credential'
- Provide the 'Organization (username)' and Repository for the credential
- Select 'Entity type' - Branch and provide 'main'
- Repeat process for 'Entity type' - Pull Request

Azure Resource Manager - Role Assignment

- Navigate to the Subscription in the Azure portal
- Select 'Access control (IAM)' and 'Add' - 'Add role assignment'
- Select Role - Contributor and select 'Members'
- Provide the 'Name' of the application from the previous steps

GitHub Actions - Secrets

- Navigate to 'Settings' on the repository
- Select 'Secrets' and 'Actions' link
- Select 'New repository secret' and create secrets for the following:
  - AZURE_TENANT_ID
  - AZURE_SUBSCRIPTION_ID
  - AZURE_CLIENT_ID

---

### Links

- [Drupal](https://www.drupal.org/)
- [Bicep](https://github.com/Azure/bicep)
- [Templates](https://learn.microsoft.com/azure/templates/)
