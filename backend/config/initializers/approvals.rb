# Character email-approval settings. Kept out of the code (no magic values) so
# the link lifetime can be tuned per environment without a deploy.
Rails.application.config.x.approvals.link_ttl_hours =
  Integer(ENV.fetch("APPROVAL_LINK_TTL_HOURS", "72"))
