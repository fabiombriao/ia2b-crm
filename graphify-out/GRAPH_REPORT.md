# Graph Report - .  (2026-04-15)

## Corpus Check
- 100 files · ~50,000 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 19 nodes · 18 edges · 4 communities detected
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Enterprise Features|Enterprise Features]]
- [[_COMMUNITY_Multi-Tenant Architecture|Multi-Tenant Architecture]]
- [[_COMMUNITY_Account Management|Account Management]]
- [[_COMMUNITY_Premium Capabilities|Premium Capabilities]]

## God Nodes (most connected - your core abstractions)
1. `Enterprise Module` - 9 edges
2. `Account Model (Tenant)` - 4 edges
3. `Account ID Isolation` - 3 edges
4. `Premium Features` - 3 edges
5. `Single Database Architecture` - 2 edges
6. `Companies/Organizations` - 2 edges
7. `SAML SSO Authentication` - 1 edges
8. `Custom Roles` - 1 edges
9. `SLA Policies` - 1 edges
10. `Audit Logs` - 1 edges

## Surprising Connections (you probably didn't know these)
- `Account Model (Tenant)` --stored_in--> `Single Database Architecture`  [EXTRACTED]
  app/models/account.rb → config/database.yml
- `Single Database Architecture` --uses_pattern--> `Account ID Isolation`  [INFERRED]
  config/database.yml → app/models/concerns.rb
- `Enterprise Module` --provides--> `Premium Features`  [EXTRACTED]
  enterprise/lib/enterprise.rb → enterprise/config/premium_features.yml
- `Enterprise Module Injection` --loads--> `Enterprise Module`  [EXTRACTED]
  config/initializers/01_inject_enterprise_edition_module.rb → enterprise/lib/enterprise.rb
- `Enterprise Module` --adds--> `Companies/Organizations`  [EXTRACTED]
  enterprise/lib/enterprise.rb → enterprise/app/models/company.rb

## Hyperedges (group relationships)
- **Enterprise Feature Set** — saml_sso, custom_roles, sla_policies, audit_logs, companies_model, agent_capacity [EXTRACTED 1.00]
- **Multi-Tenant Data Isolation** — account_model, account_id_isolation, conversation_model, contact_model, single_database [EXTRACTED 1.00]

## Communities

### Community 0 - "Enterprise Features"
Cohesion: 0.25
Nodes (8): Agent Capacity Policies, Audit Logs, Custom Roles, Enterprise License, Enterprise Module, Enterprise Module Injection, SAML SSO Authentication, SLA Policies

### Community 1 - "Multi-Tenant Architecture"
Cohesion: 0.5
Nodes (4): Account Model (Tenant), AccountUser Join Table, Companies/Organizations, Plan Management

### Community 2 - "Account Management"
Cohesion: 0.5
Nodes (4): Account ID Isolation, Contact Model, Conversation Model, Single Database Architecture

### Community 3 - "Premium Capabilities"
Cohesion: 0.67
Nodes (3): Captain AI Integration, Branding Removal Feature, Premium Features

## Knowledge Gaps
- **12 isolated node(s):** `SAML SSO Authentication`, `Custom Roles`, `SLA Policies`, `Audit Logs`, `Agent Capacity Policies` (+7 more)
  These have ≤1 connection - possible missing edges or undocumented components.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Enterprise Module` connect `Enterprise Features` to `Multi-Tenant Architecture`, `Premium Capabilities`?**
  _High betweenness centrality (0.797) - this node is a cross-community bridge._
- **Why does `Account Model (Tenant)` connect `Multi-Tenant Architecture` to `Account Management`?**
  _High betweenness centrality (0.529) - this node is a cross-community bridge._
- **Why does `Companies/Organizations` connect `Multi-Tenant Architecture` to `Enterprise Features`?**
  _High betweenness centrality (0.503) - this node is a cross-community bridge._
- **What connects `SAML SSO Authentication`, `Custom Roles`, `SLA Policies` to the rest of the system?**
  _12 weakly-connected nodes found - possible documentation gaps or missing edges._