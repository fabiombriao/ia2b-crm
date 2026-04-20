# frozen_string_literal: true

module CustomExceptions::Crm
  class NotInstalled < CustomExceptions::Base
    def message
      I18n.t('errors.crm.not_installed')
    end
  end

  class AccessDenied < CustomExceptions::Base
    def message
      I18n.t('errors.crm.access_denied')
    end
  end
end
