Devise.setup do |config|
  #config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.secret_key = '38c6fd73684c27e05302e0c0a3264a668cfc963201bd8bc0e24ca6aca1668539c19f7b0d908ba5adb9e4ac5bd629cedf7816fe41c8c8fc249668291f23c14484'
  config.navigational_formats = [:json]
end
