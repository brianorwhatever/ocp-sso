
$CA_CERT=([IO.File]::ReadAllText(".\.tmp\https.pem.crt") -replace "`r`n","`n") -replace "`n","\n"

oc process --param-file=template.env openshift//sso71-postgresql-persistent -o json | `
jq "del(.items[] | select((.kind == \`"Service\`" and .metadata.name == \`"sso\`") or (.kind == \`"Route\`" and .spec.to.name == \`"sso\`")))" | `
jq "(.items[] | select(.kind == \`"Route\`" and .spec.to.name == \`"secure-sso\`") | .spec.tls) |= {\`"termination\`": \`"reencrypt\`", \`"insecureEdgeTerminationPolicy\`": \`"Redirect\`", \`"destinationCACertificate\`": \`"${CA_CERT}\`"}"  | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso\`")) | .spec.template.spec.containers[] | select(.image=\`"sso\`") | .env[] | select(.name==\`"SSO_ADMIN_USERNAME\`")) |= {name:\`"SSO_ADMIN_USERNAME\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"sso.admin.user\`"}}}"  | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso\`")) | .spec.template.spec.containers[] | select(.image=\`"sso\`") | .env[] | select(.name==\`"SSO_ADMIN_PASSWORD\`")) |= {name:\`"SSO_ADMIN_PASSWORD\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"sso.admin.password\`"}}}"  | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso\`")) | .spec.template.spec.containers[] | select(.image=\`"sso\`") | .env[] | select(.name==\`"HTTPS_PASSWORD\`")) |= {name:\`"HTTPS_PASSWORD\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"keystore.password\`"}}}"  | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso\`")) | .spec.template.spec.containers[] | select(.image=\`"sso\`") | .env[] | select(.name==\`"JGROUPS_ENCRYPT_PASSWORD\`")) |= {name:\`"JGROUPS_ENCRYPT_PASSWORD\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"jgroups.password\`"}}}" | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso\`")) | .spec.template.spec.containers[] | select(.image=\`"sso\`") | .env[] | select(.name==\`"JGROUPS_CLUSTER_PASSWORD\`")) |= {name:\`"JGROUPS_CLUSTER_PASSWORD\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"jgroups.cluster.password\`"}}}" | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso\`")) | .spec.template.spec.containers[] | select(.image=\`"sso\`") | .env[] | select(.name==\`"DB_USERNAME\`")) |= {name:\`"DB_USERNAME\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"postgresql.user\`"}}}" | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso\`")) | .spec.template.spec.containers[] | select(.image=\`"sso\`") | .env[] | select(.name==\`"DB_PASSWORD\`")) |= {name:\`"DB_PASSWORD\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"postgresql.password\`"}}}" | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso-postgresql\`")) | .spec.template.spec.containers[] | select(.image=\`"postgresql\`") | .env[] | select(.name==\`"POSTGRESQL_USER\`")) |= {name:\`"POSTGRESQL_USER\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"postgresql.user\`"}}}" | `
jq "(.items[] | select((.kind == \`"DeploymentConfig\`" and .metadata.name == \`"sso-postgresql\`")) | .spec.template.spec.containers[] | select(.image=\`"postgresql\`") | .env[] | select(.name==\`"POSTGRESQL_PASSWORD\`")) |= {name:\`"POSTGRESQL_PASSWORD\`", valueFrom:{secretKeyRef:{name:\`"sso-app-secret\`", key:\`"postgresql.password\`"}}}" | out-file "app.json" -encoding utf8

oc create -f app.json -n devops-sso-sandbox
