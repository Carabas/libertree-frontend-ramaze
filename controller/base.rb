module Controller
  class Base < Ramaze::Controller
    helper :user, :xhtml, :age, :cleanse, :comment, :member, :wording
    trait :user_model => ::Libertree::Model::Account

    layout do |path|
      if path =~ /error/
        nil
      elsif session[:layout] == 'narrow'
        :narrow
      else
        :default
      end
    end

    def require_login
      if ! $skip_authentication && ! logged_in? && action.name != 'login' && action.name != 'logout'
        flash[:error] = 'Please log in.'
        case request.fullpath
        when %r{seen|/_}
          # don't store redirect target in the case of AJAX partials
        else
          session[:back] = request.fullpath
        end
        redirect Main.r(:login)
      end

      if logged_in?
        @num_unseen = account.num_notifications_unseen
        session[:saved_text] ||= Hash.new
        Libertree::Model::SessionAccount.find_or_create(
          sid: session.sid,
          account_id: account.id
        )
      end
    end

    # Alias methods because Ramaze::Helper::UserHelper has "user" hard-coded
    def account
      user
    end
    def account=(a)
      user = a
    end
    def account_login(*args)
      user_login *args
    end
    def account_logout(*args)
      session_account = Libertree::Model::SessionAccount[sid: session.sid]
      if session_account
        session_account.delete
      end
      user_logout *args
    end

    def error
      @e = request.env[Rack::RouteExceptions::EXCEPTION]
      Ramaze::Log.error @e.message
      Ramaze::Log.error @e.backtrace.join("\n\t")
      @t = Time.now.gmtime
    end

    def self.action_missing(path)
      return if path == '/error_404'
      # No normal action, runs on bare metal
      try_resolve('/error_404')
    end

    def error_404
      render_file "#{Ramaze.options.views[0]}/404.xhtml"
    end

    def force_mobile_to_narrow
      if request.env['HTTP_USER_AGENT'] =~ /Mobile|PlayStation/ && session[:layout] != 'narrow'
        session[:layout] = 'narrow'
        redirect r(:/)
      end
    end
  end
end
