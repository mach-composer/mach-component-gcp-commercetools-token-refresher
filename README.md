# Commercetools token refresher for GCP
Automatically rotate commercetools access tokens in GCP secretsmanager. There
are two secrets created for each instance of this component: a credentials and a
access-token secret. The credentials secret is used to request a new access
token from commercetools. The access-token secret can then be consumed by
services to do requests against commercetools.

This component is for GCP, for AWS see our
[other version](https://github.com/labd/mach-component-aws-commercetools-token-refresher)


## Usage
Use the following attributes to configure this component in MACH:

```yaml
sites:
  - identifier: some site
    components:
    - name: ct-refresher
...

components:
- name: ct-refresher
  source: git::https://github.com/mach-composer/mach-component-gcp-commercetools-token-refresher.git//function
  version: <git hash of version you want to release>
  integrations: ["aws", "commercetools", "sentry"]
```

Other components must configure their commercetools secrets with a reference to this refresher.

```terraform
locals {
  ct_scopes = formatlist("%s:%s", [
    "manage_orders",
    "view_orders",
    "manage_payments",
    "view_payments"
  ], var.ct_project_key)
}

module "ct_secret" {
  source = "git::https://github.com/mach-composer/mach-component-gcp-commercetools-token-refresher.git//secret"

  name   = "<your-component-name>"
  site   = var.site
  scopes = local.ct_scopes
}
```

In your lambda function you can pass the reference to the secretsmanager value as
```
CT_ACCESS_TOKEN_SECRET_NAME = module.ct_secret.name
```
