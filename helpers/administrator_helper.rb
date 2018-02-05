module AdministratorHelper
  def admin_title
    current_admin.email.split('@').first
  end
end
