# Install AWS S3 plugin How can we do this in a better way? this requires some scripting
#`helm plugin install https://github.com/hypnoglow/helm-s3.git`

#PJ - 2021-03-18 - This is a workaround for the helm provider plugin not being able to handle the s3:// protocol
#PJ also we need to script AWS login. This is a workaround for now

resource "kubernetes_namespace" "test" {
  metadata {
    name = "test"
  }
}
 
resource "helm_release" "brix-core" {
  name      = "brix-core"
  chart     = "kp-helm-charts/avaya/brix-core"
  namespace = "test"
  version   = "0.0.15-azure-dev"
}

#Set config Map vars
set {
    name  = "global.configMapName"
    value = "brix"
  }

  set {
    name  = "global.ingress.hosts[0]"
    value = "ingress_placeholder.ch"
  }


#   set {
#     name  = "PRESENCE_HOST"
#     value = "amm.tn-ict.com"
#   }

#   set {
#     name  = "MS_APP_ID"
#     value = "494acebc-59bb-4e10-b5ba-bff7373cdf43"
#   }

#   set_sensitive {
#     name  = "MS_CLIENT_SECRET"
#     value = "jxq8Q~Ry.ZHs8svzO0QDFAmgmCttB6gzfrdUFa_3"
#   }

#   set {
#     name  = "MS_PUBLIC_FQDN"
#     value = "put "
#   }

#   set {
#     name  = "MS_TENANT"
#     value = "c832e0fe-e3ad-438f-9749-28f864f45fad"
#   }

# #   set {
# #     name  = "MS_ENCRYPTION_KEY"
# #     value = "12345678901234567890123456789012"
# #   }

#   set {
#     name  = "MS_DISABLE_SHAREPOINT"
#     value = "true"
#   }

  set {
    name  = "configuration.COUCHDB_PASSWORD"
    value = "pr3s3nc3-d3mo"
  }

  # AWS Keys (how do we handle this?)
  set {
    name  = "configuration.AWS_ACCESS_KEY_ID"
    value = ""
  }

  set_sensitive {
    name  = "configuration.AWS_SECRET_ACCESS_KEY"
    value = "your_aws_secret_access_key"
  }

  set {
    name  = "configuration.YUGABYTE_USER"
    value = "yugabyte"
  }

  set {
    name  = "configuration.YUGABYTE_PASSWORD"
    value = "yugabyte"
  }

  set {
    name  = "configuration.YUGABYTE_HOST"
    value = "yb-tservers"
  }

  set {
    name  = "configuration.USER_SECRETS_MASTER_PASSWORD"
    value = "USER_SECRETS_MASTER_PASSWORD1234"
  }

  set {
    name  = "yugabyte.authCredentials.ysql.password"
    value = "yugabyte"
  }

  set {
    name  = "yugabyte.authCredentials.ycql.password"
    value = "yugabyte"
  }

  set {
    name  = "yugabyte.resource.master.requests.cpu"
    value = "0.1"
  }

  set {
    name  = "yugabyte.resource.tserver.requests.cpu"
    value = "0.1"
  }

  set {
    name  = "kp_micro_user.kp_micro_user.enabled"
    value = "true"
  }

  set {
    name  = "kp_micro_user.kp_micro_user.tag"
    value = "0.0.37"
  }

  set {
    name  = "token.tag"
    value = "0.0.308"
  }

  set {
    name  = "permissions.tag"
    value = "0.0.268"
  }

  set {
    name  = "user.enabled"
    value = "false"
  }
}