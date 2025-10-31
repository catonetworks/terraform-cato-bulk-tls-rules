locals {
  tls_rules_json         = jsondecode(file("${var.tls_rules_json_file_path}"))
  tls_rules_data         = local.tls_rules_json.data.policy.tlsInspect.policy.rules
  sections_data_unsorted = local.tls_rules_json.data.policy.tlsInspect.policy.sections
  # Create a map with section_index as key to sort sections correctly
  sections_by_index = {
    for section in local.sections_data_unsorted :
    tostring(section.section_index) => section
  }
  # Sort sections by section_index to ensure consistent ordering regardless of JSON file order
  sections_data_list = [
    for index in sort(keys(local.sections_by_index)) :
    local.sections_by_index[index]
  ]
  # Convert sections to map for provider schema compatibility
  sections_data = {
    for section in local.sections_data_list :
    section.section_name => section
  }
  # Convert rules to map for provider schema compatibility
  rules_data = {
    for rule in local.tls_rules_json.data.policy.tlsInspect.policy.rules_in_sections :
    rule.rule_name => rule
  }
}

resource "cato_tls_section" "sections" {
  for_each = local.sections_data
  at = {
    position = "LAST_IN_POLICY"
  }
  section = {
    name = each.value.section_name
  }
}

resource "cato_tls_rule" "rules" {
  depends_on = [cato_tls_section.sections]
  for_each   = { for rule in local.tls_rules_data : rule.rule.name => rule }

  at = {
    position = "LAST_IN_POLICY" // adding last to reorder in cato_bulk_tls_move_rule
  }

  rule = merge(
    {
      name                         = each.value.rule.name
      enabled                      = each.value.rule.enabled
      action                       = each.value.rule.action
      untrusted_certificate_action = each.value.rule.untrustedCertificateAction
    },

    # Only include description if it's not empty
    each.value.rule.description != "" ? {
      description = each.value.rule.description
    } : {},

    # Only include connection_origin if it exists
    try(each.value.rule.connectionOrigin, null) != null ? {
      connection_origin = each.value.rule.connectionOrigin
    } : {},

    # Only include platform if it exists and is not empty
    try(length(each.value.rule.platform), 0) > 0 ? {
      platform = each.value.rule.platform[0]
    } : {},

    # Only include country if it exists and is not empty
    try(length(each.value.rule.country), 0) > 0 ? {
      country = [for country in each.value.rule.country : can(country.name) ? { name = country.name } : { id = country.id }]
    } : {},

    # Only include device_posture_profile if it exists and is not empty
    try(length(each.value.rule.devicePostureProfile), 0) > 0 ? {
      device_posture_profile = [for profile in each.value.rule.devicePostureProfile : can(profile.name) ? { name = profile.name } : { id = profile.id }]
    } : {},

    # Dynamic source block - include if source exists (even if empty)
    try(each.value.rule.source, null) != null ? {
      source = {
        for k, v in {
          ip          = try(length(each.value.rule.source.ip), 0) > 0 ? each.value.rule.source.ip : null
          subnet      = try(length(each.value.rule.source.subnet), 0) > 0 ? each.value.rule.source.subnet : null
          host        = try(length(each.value.rule.source.host), 0) > 0 ? [for host in each.value.rule.source.host : can(host.name) ? { name = host.name } : { id = host.id }] : null
          site        = try(length(each.value.rule.source.site), 0) > 0 ? [for site in each.value.rule.source.site : can(site.name) ? { name = site.name } : { id = site.id }] : null
          users_group = try(length(each.value.rule.source.usersGroup), 0) > 0 ? [for group in each.value.rule.source.usersGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
          ip_range = try(length(each.value.rule.source.ipRangeTlsInspectSource), 0) > 0 ? [for range in each.value.rule.source.ipRangeTlsInspectSource : {
            from = range.from
            to   = range.to
          }] : null
          network_interface   = try(length(each.value.rule.source.networkInterface), 0) > 0 ? [for ni in each.value.rule.source.networkInterface : can(ni.name) ? { name = ni.name } : { id = ni.id }] : null
          floating_subnet     = try(length(each.value.rule.source.floatingSubnet), 0) > 0 ? [for subnet in each.value.rule.source.floatingSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
          site_network_subnet = try(length(each.value.rule.source.siteNetworkSubnet), 0) > 0 ? [for subnet in each.value.rule.source.siteNetworkSubnet : can(subnet.name) ? { name = subnet.name } : { id = subnet.id }] : null
          system_group        = try(length(each.value.rule.source.systemGroup), 0) > 0 ? [for group in each.value.rule.source.systemGroup : can(group.name) ? { name = group.name } : { id = group.id }] : null
          group               = try(length(each.value.rule.source.group), 0) > 0 ? [for group in each.value.rule.source.group : can(group.name) ? { name = group.name } : { id = group.id }] : null
          user                = try(length(each.value.rule.source.user), 0) > 0 ? [for user in each.value.rule.source.user : can(user.name) ? { name = user.name } : { id = user.id }] : null
          global_ip_range     = try(length(each.value.rule.source.globalIpRange), 0) > 0 ? [for range in each.value.rule.source.globalIpRange : can(range.name) ? { name = range.name } : { id = range.id }] : null
        } : k => v if v != null
      }
    } : {},

    # Dynamic application block - always include application even if empty (this is the destination for TLS rules)
    {
      application = {
        for k, v in {
          app_category     = try(length(each.value.rule.application.appCategory), 0) > 0 ? [for cat in each.value.rule.application.appCategory : can(cat.name) ? { name = cat.name } : { id = cat.id }] : null
          application      = try(length(each.value.rule.application.application), 0) > 0 ? [for app in each.value.rule.application.application : can(app.name) ? { name = app.name } : { id = app.id }] : null
          custom_app       = try(length(each.value.rule.application.customApp), 0) > 0 ? [for app in each.value.rule.application.customApp : can(app.name) ? { name = app.name } : { id = app.id }] : null
          custom_category  = try(length(each.value.rule.application.customCategory), 0) > 0 ? [for cat in each.value.rule.application.customCategory : can(cat.name) ? { name = cat.name } : { id = cat.id }] : null
          domain           = try(length(each.value.rule.application.domain), 0) > 0 ? each.value.rule.application.domain : null
          fqdn             = try(length(each.value.rule.application.fqdn), 0) > 0 ? each.value.rule.application.fqdn : null
          ip               = try(length(each.value.rule.application.ip), 0) > 0 ? each.value.rule.application.ip : null
          subnet           = try(length(each.value.rule.application.subnet), 0) > 0 ? each.value.rule.application.subnet : null
          ip_range = try(length(each.value.rule.application.ipRangeTlsInspectApplication), 0) > 0 ? [for range in each.value.rule.application.ipRangeTlsInspectApplication : {
            from = range.from
            to   = range.to
          }] : null
          country         = try(length(each.value.rule.application.country), 0) > 0 ? [for country in each.value.rule.application.country : can(country.name) ? { name = country.name } : { id = country.id }] : null
          remote_asn      = try(length(each.value.rule.application.remoteAsn), 0) > 0 ? each.value.rule.application.remoteAsn : null
          global_ip_range = try(length(each.value.rule.application.globalIpRange), 0) > 0 ? [for range in each.value.rule.application.globalIpRange : can(range.name) ? { name = range.name } : { id = range.id }] : null
          service = try(length(each.value.rule.application.service), 0) > 0 ? [for svc in each.value.rule.application.service : can(svc.name) ? { name = svc.name } : { id = svc.id }] : null
          # custom_service expects a single object, take the first service from the array
          custom_service = try(length(each.value.rule.application.customService), 0) > 0 ? merge(
            {
              protocol = each.value.rule.application.customService[0].protocol
            },
            try(length(each.value.rule.application.customService[0].port), 0) > 0 ? {
              port = [for p in each.value.rule.application.customService[0].port : tostring(p)]
            } : {},
            try(each.value.rule.application.customService[0].portRange, null) != null ? {
              port_range = {
                from = tostring(each.value.rule.application.customService[0].portRange.from)
                to   = tostring(each.value.rule.application.customService[0].portRange.to)
              }
            } : {}
          ) : null
          # custom_service_ip expects a single object, take the first service from the array
          custom_service_ip = try(length(each.value.rule.application.customServiceIp), 0) > 0 ? merge(
            {
              name = each.value.rule.application.customServiceIp[0].name
            },
            try(each.value.rule.application.customServiceIp[0].ip, null) != null ? {
              ip = each.value.rule.application.customServiceIp[0].ip
            } : {},
            try(each.value.rule.application.customServiceIp[0].ipRange, null) != null ? {
              ip_range = {
                from = each.value.rule.application.customServiceIp[0].ipRange.from
                to   = each.value.rule.application.customServiceIp[0].ipRange.to
              }
            } : {}
          ) : null
          # tls_inspect_category is a string, take the first category from the array
          tls_inspect_category = try(length(each.value.rule.application.tlsInspectCategory), 0) > 0 ? each.value.rule.application.tlsInspectCategory[0] : null
        } : k => v if v != null
      }
    },


  )
}

resource "cato_bulk_tls_move_rule" "all_if_rules" {
  depends_on                = [cato_tls_section.sections, cato_tls_rule.rules]
  rule_data                 = local.rules_data
  section_data              = local.sections_data
  section_to_start_after_id = var.section_to_start_after_id != null ? var.section_to_start_after_id : null
}
