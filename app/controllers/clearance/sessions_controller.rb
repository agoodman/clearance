class Clearance::SessionsController < ApplicationController
  unloadable

  skip_before_filter :authenticate, :only => [:new, :create, :destroy]
  protect_from_forgery :except => :create
  filter_parameter_logging :password

  def new
    render :template => 'sessions/new'
  end

  def create
    @user = ::User.authenticate(params[:session][:email],
                                params[:session][:password])
                                
    respond_to do |format|
      if @user.nil?
        format.html { 
          flash_failure_after_create
          render :template => 'sessions/new', :status => :unauthorized
        }
        format.json { render :json => error_after_create(@user), :status => :unauthorized }
        format.xml  { render :xml => error_after_create(@user), :status => :unauthorized }
      else
        if @user.email_confirmed?
          sign_in(@user)
          format.html { 
            flash_success_after_create
            redirect_to(url_after_create)
          }
          format.json { render :json => hash_after_create(@user), :status => :ok }
          format.xml  { render :xml => hash_after_create(@user), :status => :ok }
        else
          ::ClearanceMailer.confirmation(@user).deliver
          format.html { 
            flash_notice_after_create
            redirect_to(sign_in_url)
          }
          format.json { render :json => confirm_after_create(@user), :status => :unprocessable_entity }
          format.xml  { render :xml => confirm_after_create(@user), :status => :unprocessable_entity }
        end
      end
    end
  end

  def destroy
    sign_out
    respond_to do |format|
      format.html { 
        flash_success_after_destroy
        redirect_to(url_after_destroy)
      }
      format.json { head :ok }
      format.xml  { head :ok }
    end
  end

  private

  def flash_failure_after_create
    flash.now[:alert] = translate(:bad_email_or_password,
      :scope   => [:clearance, :controllers, :sessions],
      :default => "Bad email or password.")
  end

  def flash_success_after_create
    flash[:notice] = translate(:signed_in, :default =>  "Signed in.")
  end

  def flash_notice_after_create
    flash[:notice] = translate(:unconfirmed_email,
      :scope   => [:clearance, :controllers, :sessions],
      :default => "User has not confirmed email. " <<
                  "Confirmation email will be resent.")
  end

  def url_after_create
    '/'
  end

  def flash_success_after_destroy
    flash[:notice] = translate(:signed_out, :default =>  "Signed out.")
  end

  def url_after_destroy
    sign_in_url
  end
  
  def hash_after_create(user)
    user
  end
  
  def error_after_create(user)
    { :errors => user.errors.full_messages }
  end
  
  def confirm_after_create(user)
    { :errors => [ 'Email confirmation resent' ] }
  end
  
end
