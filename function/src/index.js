import * as functions from "@google-cloud/functions-framework";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

// TODO: read from env
const CTP_AUTH_URL = "https://auth.europe-west1.gcp.commercetools.com";

const client = new SecretManagerServiceClient();

functions.cloudEvent("rotateSecret", async (cloudEvent) => {
  const eventType = cloudEvent.data.message.attributes.eventType;

  switch (eventType) {
    case "SECRET_CREATE":
    case "SECRET_ROTATE":
    case "SECRET_UPDATE":
      await rotateValue(cloudEvent.data.message.attributes.secretId);
      break;

    default:
      console.log("unhandled event type", eventType);
      break;
  }
});

// rotateValue rotates the access token with a new value
const rotateValue = async (secretId) => {
  const credentialsId = secretId.replace(/-access-token$/, "-credentials");

  const credentials = await readCredentials(credentialsId);
  const accessToken = await getAccessToken(credentials);

  // Create a new secret version
  const payload = Buffer.from(accessToken, "utf8");
  const [updatedVersion] = await client.addSecretVersion({
    parent: secretId,
    payload: {
      data: payload,
    },
  });

  console.log("Created secret version:", updatedVersion.name);

  await client.listSecretVersions({ parent: secretId }).then((versions) => {
    for (const [i, version] of versions[0].entries()) {
      if (version.state === "ENABLED" && version.name !== updatedVersion.name) {
        console.log("Deleting version:", version.name);
        client.destroySecretVersion({ name: version.name });
      }
    }
  });
  return true;
};

const readCredentials = async (secretId) => {
  const [version] = await client.accessSecretVersion({
    name: `${secretId}/versions/latest`,
  });
  return JSON.parse(version.payload.data);
};

const getAccessToken = async (credentials) => {
  const tokenData = new URLSearchParams();
  tokenData.append("grant_type", "client_credentials");
  tokenData.append("scope", credentials.clientScopes);

  const authHeader = `Basic ${Buffer.from(
    `${credentials.clientId}:${credentials.clientSecret}`
  ).toString("base64")}`;

  const endpoint = `${CTP_AUTH_URL}/oauth/token`;
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      Authorization: authHeader,
      "Content-Type": "application/x-www-form-urlencoded",
      "User-Agent":
        "GCP Token Rotator (https://github.com/mach-composer/mach-component-gcp-commercetools-token-refresher)",
    },
    body: tokenData,
  });
  if (!response.ok) {
    const body = await response.json();
    throw new Error(
      `Failed to fetch access token: ${response.status} ${
        response.statusText
      } (${JSON.stringify(body)})`
    );
  }
  const data = await response.json();
  return data.access_token;
};
