class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "AI Character Video Platform <no-reply@aicvp.local>")
  layout "mailer"
end
