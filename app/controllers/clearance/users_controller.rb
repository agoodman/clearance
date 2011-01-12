class Clearance::UsersController < ApplicationController
  unloadable

  skip_before_filter :authenticate, :only => [:new, :create]
  before_filter :redirect_to_root,  :only => [:new, :create], :if => :signed_in?
  filter_parameter_logging :password

  def new
    @user = ::User.new(params[:user])
    render :template => 'users/new'
  end

  def create
    @user = ::User.new params[:user]
    if @user.save
      respond_to do |format|
        format.html { 
          flash_notice_after_create
          redirect_to(url_after_create)
        }
        format.json { render :json => hash_after_create(@user), :status => :ok }
        format.xml  { render :xml => hash_after_create(@user), :status => :ok }
      end
    else
      respond_to do |format|
        format.html { 
          flash_alert_after_create
          render :template => 'users/new' 
        }
        format.json { render :json => error_after_create(@user), :status => :unprocessable_entity }
        format.xml  { render :xml => error_after_create(@user), :status => :unprocessable_entity }
      end
    end
  end

  private

  def flash_notice_after_create
    flash[:notice] = translate(:deliver_confirmation,
      :scope   => [:clearance, :controllers, :users],
      :default => "You will receive an email within the next few minutes. " <<
                  "It contains instructions for confirming your account.")
  end

  def flash_alert_after_create
    flash[:alert] = @user.errors.full_messages.join('<br/>')
  end

  def url_after_create
    sign_in_url
  end
  
  def hash_after_create(user)
    user
  end
  
  def error_after_create(user)
    { :errors => user.errors.full_messages }
  end
  
end
