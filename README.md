# Terraform Cato Bulk TLS Inspection Rules Module

This module allows you to bulk import TLS Inspection rules and sections from a JSON configuration file, and define the order of those rules and sections within the Cato policy.

## Usage

The module reads a JSON configuration file that defines:
- **Rules**: Individual firewall rules with their configurations
- **Sections**: Logical groupings for organizing rules
- **Rule ordering**: Defines which rules belong to which sections and their order within sections

## Best Practices for TLS Rules

As a best practice, add the following custom categories to map to the following phases for TLS Inspection which can be used in rules as seen below — see [Working with Categories](https://support.catonetworks.com/hc/en-us/articles/13314286857501-Working-with-Categories).

1. `TLSi_Phase_1`: Alcohol and Tobacco, Anonymizers, Botnets, Cheating, Compromised, Criminal Activity, Cults, Hacking, Illegal Drugs, Keyloggers, Malware, Nudity, P2P, Parked domains, Phishing, Porn, Questionable, SPAM, Spyware, Tasteless, Violence and Hate, Weapons, 
1. `TLSi_Phase_2`: Entertainment, Gambling, Games, Greeting Cards, Leisure and Recreation, News, Politics, Real Estate, Religion, Sex education, Shopping, Sports, Vehicles, Web Hosting, 

### Basic Example

```hcl
module "bulk_tls_rules" {
  source = "catonetworks/bulk-tls-rules/cato"
  
  tls_rules_json_file_path = "./config_data/all_tls_rules_and_sections_11484.json"
  section_to_start_after_id = "existing-section-id" # Optional
}
```

### JSON Configuration Structure

The JSON file should contain a nested structure with the following key components:

- `data.policy.tlsInspect.policy.rules[]` - Array of TLS rules
- `data.policy.tlsInspect.policy.sections[]` - Array of sections with index and name
- `data.policy.tlsInspect.policy.rules_in_sections[]` - Mapping of rules to sections with ordering

#### Key Fields:

**Rules Array**: Each rule contains standard TLS rule properties like name, description, enabled status, source, platform, country, connectionOrigin, application, action, and untrustedCertificateAction settings.

**Sections Array**: Defines sections with:
- `section_index`: The order of the section in the policy
- `section_name`: The display name of the section

**Rules in Sections Array**: Maps rules to sections with:
- `index_in_section`: The order of the rule within its section
- `section_name`: The section this rule belongs to
- `rule_name`: The name of the rule to place in the section

<details>
<summary>Click to expand full JSON configuration example</summary>

```json
{
  "data": {
    "policy": {
      "tlsInspect": {
        "policy": {
          "enabled": true,
          "rules": [
            {
              "rule": {
                "name": "TLSi_Phase_1_inspection",
                "description": "",
                "enabled": true,
                "source": {
                  "site": [
                    {
                      "name": "1600_LTE"
                    }
                  ]
                },
                "platform": [],
                "country": [],
                "devicePostureProfile": [],
                "connectionOrigin": "ANY",
                "application": {
                  "customCategory": [
                    {
                      "name": "TLSi_Phase_1"
                    }
                  ]
                },
                "action": "INSPECT",
                "untrustedCertificateAction": "ALLOW"
              }
            },
            {
              "rule": {
                "name": "TLSi_Phase_2_inspection",
                "description": "",
                "enabled": true,
                "source": {
                  "usersGroup": [
                    {
                      "name": "Corporate Users"
                    }
                  ]
                },
                "platform": [],
                "country": [],
                "devicePostureProfile": [],
                "connectionOrigin": "ANY",
                "application": {
                  "customCategory": [
                    {
                      "name": "TLSi_Phase_2"
                    }
                  ]
                },
                "action": "INSPECT",
                "untrustedCertificateAction": "ALLOW"
              }
            },
            {
              "audit": {
                "updatedTime": "2025-10-31T17:54:21.486",
                "updatedBy": "baseapi"
              },
              "rule": {
                "id": "dfbfd131-9042-41c9-92c6-d894a8bc905f",
                "name": "TLSi_Phase_3_inspection",
                "description": "",
                "section": {
                  "name": "TLS Phases"
                },
                "enabled": true,
                "source": {
                  "user": [],
                  "floatingSubnet": [],
                  "globalIpRange": [],
                  "group": [],
                  "host": [],
                  "subnet": [],
                  "ipRangeTlsInspectSource": [],
                  "networkInterface": [],
                  "site": [],
                  "systemGroup": [],
                  "usersGroup": [],
                  "ip": [],
                  "siteNetworkSubnet": []
                },
                "platform": [],
                "country": [],
                "devicePostureProfile": [],
                "connectionOrigin": "ANY",
                "application": {
                  "application": [],
                  "appCategory": [],
                  "country": [],
                  "customApp": [],
                  "customCategory": [],
                  "customServiceIp": [],
                  "domain": [],
                  "fqdn": [],
                  "subnet": [],
                  "ip": [],
                  "ipRangeTlsInspectApplication": [],
                  "globalIpRange": [],
                  "customService": [],
                  "remoteAsn": [],
                  "service": [],
                  "tlsInspectCategory": []
                },
                "action": "INSPECT",
                "untrustedCertificateAction": "ALLOW"
              },
              "properties": []
            }
          ],
          "sections": [
            {
              "section_index": 1,
              "section_name": "TLS Phases"
            },
            {
              "section_index": 2,
              "section_name": "Custom TLS Rules"
            }
          ],
          "rules_in_sections": [
            {
              "index_in_section": 1,
              "section_name": "TLS Phases",
              "rule_name": "TLSi_Phase_1_inspection"
            },
            {
              "index_in_section": 2,
              "section_name": "TLS Phases",
              "rule_name": "TLSi_Phase_2_inspection"
            },
            {
              "index_in_section": 3,
              "section_name": "TLS Phases",
              "rule_name": "TLSi_Phase_3_inspection"
            }
          ]
        }
      }
    }
  }
}
```
</details>

### How Rule Ordering Works

Based on the example above:
1. **Section 1** ("TLS Phases") is created first
2. **Section 2** ("Custom TLS Rules") is created second
3. **TLSi_Phase_1_inspection** is placed in "TLS Phases" at position 1
4. **TLSi_Phase_2_inspection** is placed in "TLS Phases" at position 2
5. **Kitchen Sink Rule** is placed in "Custom TLS Rules" at position 1

The final policy structure will be:
```
├── TLS Phases
│   ├── TLSi_Phase_1_inspection
│   └── TLSi_Phase_2_inspection
└── Custom TLS Rules
    └── Kitchen Sink Rule
```

### Parameters

- `tls_rules_json_file_path`: Path to your JSON configuration file
- `section_to_start_after_id`: (Optional) ID of an existing section after which to insert the new sections

## Working with Existing Rules (Brownfield Deployments)

For brownfield deployments where you have existing TLS Inspection rules in your Cato Management Application, you can use the Cato CLI to export and import these rules into Terraform state.

### Installing and Configuring Cato CLI

1. **Install the Cato CLI:**
   ```bash
   pip3 install catocli
   ```

2. **Configure the CLI with your Cato credentials:**
   ```bash
   catocli configure set
   ```
   This will prompt you for your Cato Management Application credentials and account information.

### Exporting Existing Rules

To export your existing TLS Inspection rules and sections into the JSON format required by this module:

```bash
catocli export tls_rules
```

This command will generate a JSON file containing all your existing TLS Inspection rules and sections in the correct format for this Terraform module.

### Importing Rules into Terraform State

Once you have the JSON configuration file, you can import the existing rules and sections into Terraform state. This is useful for:

- **Brownfield deployments**: Managing existing rules with Terraform
- **Backup and restore**: Restoring rules to a known good state after unintended changes
- **State management**: Bringing existing infrastructure under Terraform control

To import the rules into Terraform state:

```bash
catocli import tls_rules_to_tf config_data/all_tls_rules_and_sections.json --module-name=module.tls_rules
```

**Parameters:**
- `config_data/all_tls_rules_and_sections.json`: Path to your exported JSON file
- `--module-name=module.tls_rules`: The name of your Terraform module instance

### Typical Brownfield Workflow

1. **Export existing rules:**
   ```bash
   catocli export tls_rules
   ```

2. **Create your Terraform configuration:**
   ```hcl
   module "tls_rules" {
     source = "./terraform-cato-bulk-tls-rules"
     
     tls_rules_json_file_path = "./config_data/all_tls_rules_and_sections.json"
   }
   ```

3. **Import existing state:**
   ```bash
   catocli import tls_rules_to_tf config_data/all_tls_rules_and_sections.json --module-name=module.tls_rules
   ```

4. **Run Terraform plan to verify:**
   ```bash
   terraform plan
   ```
   This should show no changes if the import was successful.

### Backup and Restore Workflow

If unintended changes are made directly to rules and sections in the Cato Management Application, you can restore to the last known good state:

1. **Apply your last known good configuration:**
   ```bash
   terraform apply
   ```
   This will restore rules and sections to match your Terraform configuration.

2. **Alternatively, re-export and compare:**
   ```bash
   catocli export tls_rules
   # Compare with your existing JSON file to identify changes
   ```

## Using Module Outputs

The module provides comprehensive outputs that can be used for monitoring, auditing, integration with other systems, and operational insights. Below are practical examples of how to use these outputs in your Terraform configuration.

<details>
<summary>Click to expand example client-side outputs</summary>

```hcl
# Basic deployment information
output "deployment_info" {
  description = "Basic information about the TLS Inspection deployment"
  value = {
    total_sections = module.tls_rules.deployment_summary.total_sections_created
    total_rules    = module.tls_rules.deployment_summary.total_rules_created
    enabled_rules  = module.tls_rules.deployment_summary.enabled_rules_count
    disabled_rules = module.tls_rules.deployment_summary.disabled_rules_count
    source_file    = module.tls_rules.parsed_configuration.source_file_path
  }
}

# Quick reference for rule and section IDs
output "quick_reference" {
  description = "Quick reference maps for rules and sections"
  value = {
    section_ids = module.tls_rules.section_ids
    rule_ids    = module.tls_rules.rule_ids
  }
}

# Security policy overview
output "tls_policy_overview" {
  description = "Overview of the TLS Inspection policy configuration"
  value = {
    inspect_rules_count = module.tls_rules.deployment_summary.inspect_rules_count
    bypass_rules_count = module.tls_rules.deployment_summary.bypass_rules_count
    inspect_rules       = module.tls_rules.inspect_rules
    bypass_rules       = module.tls_rules.bypass_rules
    disabled_rules    = module.tls_rules.disabled_rules
  }
}

# Detailed section structure
output "section_structure" {
  description = "Detailed view of how rules are organized in sections"
  value       = module.tls_rules.sections_to_rules_mapping
}

# Bulk move operation details
output "bulk_move_details" {
  description = "Details about the bulk move operation that organized the rules"
  value       = module.tls_rules.bulk_move_operation
}

# Configuration validation
output "configuration_validation" {
  description = "Validation information about the parsed configuration"
  value = {
    source_file           = module.tls_rules.parsed_configuration.source_file_path
    rules_in_json         = module.tls_rules.parsed_configuration.rules_data_count
    sections_in_json      = module.tls_rules.parsed_configuration.sections_data_count
    rule_mappings_in_json = module.tls_rules.parsed_configuration.rules_mapping_count
    section_order         = module.tls_rules.parsed_configuration.section_names_ordered
    rules_created         = module.tls_rules.deployment_summary.total_rules_created
    sections_created      = module.tls_rules.deployment_summary.total_sections_created
  }
}

# Example: Filtered outputs for specific use cases
output "inspection_rules" {
  description = "Example of filtering rules for TLS inspection (INSPECT actions)"
  value = {
    inspect_rule_names = module.tls_rules.inspect_rules
    inspect_rule_count = length(module.tls_rules.inspect_rules)
    inspect_rule_ids   = [for rule_name in module.tls_rules.inspect_rules : module.tls_rules.rule_ids[rule_name]]
  }
}

# Example: Rules that might need attention
output "rules_needing_attention" {
  description = "Example of identifying rules that might need attention"
  value = {
    disabled_rules       = module.tls_rules.disabled_rules
    disabled_rules_count = length(module.tls_rules.disabled_rules)
    disabled_rule_ids    = [for rule_name in module.tls_rules.disabled_rules : module.tls_rules.rule_ids[rule_name]]
  }
}

# Example: Section-specific information
output "section_details" {
  description = "Example of extracting detailed information about sections"
  value = {
    section_names = module.tls_rules.section_names
    sections_with_rule_counts = {
      for section_name, section_data in module.tls_rules.sections_to_rules_mapping :
      section_name => {
        section_id = section_data.section_id
        rule_count = length(section_data.rules)
        rule_names = [for rule in section_data.rules : rule.rule_name]
      }
    }
  }
}

# Example: For integration with monitoring systems
output "monitoring_metrics" {
  description = "Example metrics that could be sent to monitoring systems"
  value = {
    deployment_timestamp     = timestamp()
    total_tls_rules     = module.tls_rules.deployment_summary.total_rules_created
    total_tls_sections  = module.tls_rules.deployment_summary.total_sections_created
    active_tls_rules    = module.tls_rules.deployment_summary.enabled_rules_count
    inactive_tls_rules  = module.tls_rules.deployment_summary.disabled_rules_count
    inspect_rules_count   = module.tls_rules.deployment_summary.inspect_rules_count
    bypass_rules_count  = module.tls_rules.deployment_summary.bypass_rules_count
    configuration_source     = basename(module.tls_rules.parsed_configuration.source_file_path)
    bulk_move_operation_data = module.tls_rules.bulk_move_operation
  }
}

# Example: For audit and compliance reporting
output "audit_report" {
  description = "Example audit report using module outputs"
  value = {
    deployment_summary = {
      date                = timestamp()
      source_config_file  = module.tls_rules.parsed_configuration.source_file_path
      sections_deployed   = module.tls_rules.deployment_summary.total_sections_created
      rules_deployed      = module.tls_rules.deployment_summary.total_rules_created
      rules_by_status = {
        enabled  = module.tls_rules.deployment_summary.enabled_rules_count
        disabled = module.tls_rules.deployment_summary.disabled_rules_count
      }
      rules_by_action = {
        inspect = module.tls_rules.deployment_summary.inspect_rules_count
        bypass  = module.tls_rules.deployment_summary.bypass_rules_count
      }
    }
    rule_organization   = module.tls_rules.sections_to_rules_mapping
    disabled_rules_list = module.tls_rules.disabled_rules
    inspect_rules_list  = module.tls_rules.inspect_rules
    bypass_rules_list   = module.tls_rules.bypass_rules
  }
}
```
</details>

### Output Use Cases

These example outputs demonstrate various practical applications:

- **`deployment_info`**: Quick deployment overview for dashboards
- **`quick_reference`**: ID mappings for referencing resources in other modules
- **`tls_policy_overview`**: TLS Inspection-focused analysis of rule actions
- **`section_structure`**: Understanding rule organization and hierarchy
- **`bulk_move_details`**: Operational details about the deployment process
- **`configuration_validation`**: Comparing JSON input with actual deployment
- **`inspection_rules`**: Filtering for TLS inspection rules (INSPECT actions)
- **`rules_needing_attention`**: Identifying disabled rules for review
- **`section_details`**: Detailed section analysis with rule counts
- **`monitoring_metrics`**: Metrics formatted for monitoring systems
- **`audit_report`**: Comprehensive audit trail for compliance

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.13 |
| <a name="requirement_cato"></a> [cato](#requirement\_cato) | >= 0.0.50 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_cato"></a> [cato](#provider\_cato) | >= 0.0.50 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [cato_bulk_tls_move_rule.all_if_rules](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/bulk_tls_move_rule) | resource |
| [cato_tls_rule.rules](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/tls_rule) | resource |
| [cato_tls_section.sections](https://registry.terraform.io/providers/catonetworks/cato/latest/docs/resources/tls_section) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_section_to_start_after_id"></a> [section\_to\_start\_after\_id](#input\_section\_to\_start\_after\_id) | The ID of the section after which to start adding rules. | `string` | `null` | no |
| <a name="input_tls_rules_json_file_path"></a> [tls\_rules\_json\_file\_path](#input\_tls\_rules\_json\_file\_path) | Path to the json file containing the ifw rule data. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_allow_rules"></a> [allow\_rules](#output\_allow\_rules) | List of rules with ALLOW action |
| <a name="output_block_rules"></a> [block\_rules](#output\_block\_rules) | List of rules with BLOCK action |
| <a name="output_bulk_move_operation"></a> [bulk\_move\_operation](#output\_bulk\_move\_operation) | Details of the bulk move operation |
| <a name="output_deployment_summary"></a> [deployment\_summary](#output\_deployment\_summary) | Summary statistics of the deployment |
| <a name="output_disabled_rules"></a> [disabled\_rules](#output\_disabled\_rules) | List of disabled rule names |
| <a name="output_enabled_rules"></a> [enabled\_rules](#output\_enabled\_rules) | List of enabled rule names |
| <a name="output_parsed_configuration"></a> [parsed\_configuration](#output\_parsed\_configuration) | Parsed configuration data from the JSON file |
| <a name="output_rule_ids"></a> [rule\_ids](#output\_rule\_ids) | Map of rule names to their IDs |
| <a name="output_rule_names"></a> [rule\_names](#output\_rule\_names) | List of all created rule names |
| <a name="output_rules"></a> [rules](#output\_rules) | Map of all created TLS Inspection rules with their details |
| <a name="output_rules_to_sections_mapping"></a> [rules\_to\_sections\_mapping](#output\_rules\_to\_sections\_mapping) | Mapping of rules to their assigned sections with ordering |
| <a name="output_section_ids"></a> [section\_ids](#output\_section\_ids) | Map of section names to their IDs |
| <a name="output_section_names"></a> [section\_names](#output\_section\_names) | List of all created section names |
| <a name="output_sections"></a> [sections](#output\_sections) | Map of all created TLS Inspection sections with their details |
| <a name="output_sections_to_rules_mapping"></a> [sections\_to\_rules\_mapping](#output\_sections\_to\_rules\_mapping) | Mapping of sections to their assigned rules with ordering |
<!-- END_TF_DOCS -->