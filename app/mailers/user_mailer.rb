class UserMailer < ApplicationMailer
  default from: 'sysunipresence@gmail.com'
  def welcome_email
    @user = params[:user]
    mail(to: @user.email, subject: 'Bem-vindo! Defina sua senha no sistema')
  end
end
