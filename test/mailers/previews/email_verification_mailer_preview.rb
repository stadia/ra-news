# Preview all emails at http://localhost:3000/rails/mailers/email_verification_mailer
class EmailVerificationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/email_verification_mailer/verify
  def verify
    EmailVerificationMailer.verify(User.first)
  end
end
