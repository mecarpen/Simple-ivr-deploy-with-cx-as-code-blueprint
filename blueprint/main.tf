terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

provider "genesyscloud" {
  sdk_debug = true
}

resource "genesyscloud_user" "sf_johnsmith" {
  email           = "john.smith@simplefinancial.com"
  name            = "John Smith"
  password        = "b@Zinga1972"
  state           = "active"
  department      = "IRA"
  title           = "Agent"
  acd_auto_answer = true
  addresses {

    phone_numbers {
      number     = "9205551212"
      media_type = "PHONE"
      type       = "MOBILE"
    }
  }
  employer_info {
    official_name = "John Smith"
    employee_id   = "12345"
    employee_type = "Full-time"
    date_hire     = "2021-03-18"
  }
}

resource "genesyscloud_user" "sf_janesmith" {
  email           = "jane.smith@simplefinancial.com"
  name            = "Jane Smith"
  password        = "b@Zinga1972"
  state           = "active"
  department      = "IRA"
  title           = "Agent"
  acd_auto_answer = true
  addresses {

    phone_numbers {
      number     = "9205551212"
      media_type = "PHONE"
      type       = "MOBILE"
    }
  }
  employer_info {
    official_name = "John Smith"
    employee_id   = "12345"
    employee_type = "Full-time"
    date_hire     = "2021-03-18"
  }
}

resource "genesyscloud_routing_queue" "queue_ira" {
  name                     = "Simple Financial IRA queue"
  description              = "Simple Financial IRA questions and answers"
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  acw_timeout_ms           = 300000
  skill_evaluation_method  = "BEST"
  auto_answer_only         = true
  enable_transcription     = true
  enable_manual_assignment = true

  members {
    user_id  = genesyscloud_user.sf_johnsmith.id
    ring_num = 1
  }
}

resource "genesyscloud_routing_queue" "queue_K401" {
  name                     = "Simple Financial 401K queue"
  description              = "Simple Financial 401K questions and answers"
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  acw_timeout_ms           = 300000
  skill_evaluation_method  = "BEST"
  auto_answer_only         = true
  enable_transcription     = true
  enable_manual_assignment = true
  members {
    user_id  = genesyscloud_user.sf_johnsmith.id
    ring_num = 1
  }

  members {
    user_id  = genesyscloud_user.sf_janesmith.id
    ring_num = 1
  }
}


###
#  Archy Work
###
resource "null_resource" "deploy_archy_flow" {
  depends_on = [
    genesyscloud_routing_queue.queue_K401,
    genesyscloud_routing_queue.queue_ira
  ]

  provisioner "local-exec" {
    command = "  archy publish --forceUnlock --file SimpleFinancialIvr_v2-0.yaml --clientId $GENESYSCLOUD_OAUTHCLIENT_ID --clientSecret $GENESYSCLOUD_OAUTHCLIENT_SECRET --location $GENESYSCLOUD_ARCHY_REGION  --overwriteResultsFile --resultsFile results.json "
  }
}

data "genesyscloud_flow" "mysimpleflow" {
  depends_on = [
    null_resource.deploy_archy_flow
  ]
  name = "SimpleFinancialIvr"
}

resource "genesyscloud_telephony_providers_edges_did_pool" "mygcv_number" {
  start_phone_number = "+19205422729"
  end_phone_number   = "+19205422729"
  description        = "GCV Number for inbound calls"
  comments           = "Additional comments"
  depends_on = [
    null_resource.deploy_archy_flow
  ]
}

resource "genesyscloud_architect_ivr" "mysimple_ivr" {
  name               = "A simple IVR"
  description        = "A sample IVR configuration"
  dnis               = ["+19205422729", "+19205422729"]
  open_hours_flow_id = data.genesyscloud_flow.mysimpleflow.id
  depends_on         = [genesyscloud_telephony_providers_edges_did_pool.mygcv_number]
}

module "AwsEventBridgeIntegration" {
  source              = "git::https://github.com/GenesysCloudDevOps/aws-event-bridge-module.git?ref=v0.0.2"
  aws_account_id      = "335611188682"
  aws_account_region  = "us-west-2"
  event_source_suffix = "-sample-eb1"
  topic_filters       = ["v2.audits.entitytype.{id}.entityid.{id}", "v2.analytics.flow.{id}.aggregates"]
}

