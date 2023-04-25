terraform {
  required_providers {
    genesyscloud = {
      source = "mypurecloud/genesyscloud"
    }
  }
}

provider "genesyscloud" {
  sdk_debug           = true
  aws_region          = "us-east-1"
  oauthclient_id      = "GENESYSCLOUD_OAUTHCLIENT_ID"
  oauthclient_secret  = "GENESYSCLOUD_OAUTHCLIENT_SECRET"
}

resource "genesyscloud_user" "mec_johnsmith" {
  email           = "john.smith@complexfinancial.com"
  name            = "John Smith"
  password        = "b@Zinga1972"
  state           = "active"
  department      = "IRA"
  title           = "Agent"
  acd_auto_answer = true
  addresses {

    phone_numbers {
      number     = "+19205551212"
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

resource "genesyscloud_user" "mec_janesmith" {
  email           = "jane.smith@complexfinancial.com"
  name            = "Jane Smith"
  password        = "b@Zinga1972"
  state           = "active"
  department      = "IRA"
  title           = "Agent"
  acd_auto_answer = true
  addresses {

    phone_numbers {
      number     = "+19205551212"
      media_type = "PHONE"
      type       = "MOBILE"
    }
  }
  employer_info {
    official_name = "Jane Smith"
    employee_id   = "67890"
    employee_type = "Full-time"
    date_hire     = "2021-03-18"
  }
}

resource "genesyscloud_routing_queue" "mec_queue_ira" {
  name                     = "Simple Financial IRA queue"
  description              = "Simple Financial IRA questions and answers"
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  acw_timeout_ms           = 300000
  skill_evaluation_method  = "BEST"
  auto_answer_only         = true
  enable_transcription     = true
  enable_manual_assignment = true

  members {
    user_id  = genesyscloud_user.mec_johnsmith.id
    ring_num = 1
  }
}

resource "genesyscloud_routing_queue" "mec_queue_K401" {
  name                     = "Simple Financial 401K queue"
  description              = "Simple Financial 401K questions and answers"
  acw_wrapup_prompt        = "MANDATORY_TIMEOUT"
  acw_timeout_ms           = 300000
  skill_evaluation_method  = "BEST"
  auto_answer_only         = true
  enable_transcription     = true
  enable_manual_assignment = true
  members {
    user_id  = genesyscloud_user.mec_johnsmith.id
    ring_num = 1
  }

  members {
    user_id  = genesyscloud_user.mec_janesmith.id
    ring_num = 1
  }
}

resource "genesyscloud_flow" "mec_mysimpleflow" {
  filepath = "./SimpleFinancialIvr_v2-0_MEC.yaml"
  file_content_hash = filesha256("./SimpleFinancialIvr_v2-0_MEC.yaml") 
}


resource "genesyscloud_telephony_providers_edges_did_pool" "gcv_mec_number" {
  start_phone_number = my_ivr_did_number
  end_phone_number   = my_ivr_did_number
  description        = "GCV Number for inbound calls"
  comments           = "Additional comments"
}

resource "genesyscloud_architect_ivr" "mec_mysimple_ivr" {
  name               = "A simple IVR"
  description        = "A sample IVR configuration"
  dnis               = [my_ivr_did_number, my_ivr_did_number]
  open_hours_flow_id = genesyscloud_flow.mec_mysimpleflow.id
  depends_on         = [
    genesyscloud_flow.mec_mysimpleflow,
    genesyscloud_telephony_providers_edges_did_pool.gcv_mec_number
  ]
}

