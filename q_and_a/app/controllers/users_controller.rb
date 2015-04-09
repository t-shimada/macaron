class UsersController < ApplicationController
  def index
    @users = User.search_user(params)
  end

  def show
    if params[:id].blank?
      redirect_to(users_url, alert: '対象が指定されていません')
      return
    end

    @user = User.where(id: params[:id]).first
    unless @user
      redirect_to(users_url, alert: '対象が見つかりません')
      return
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    
    ActiveRecord::Base.transaction do
      fail ActiveRecord::RecordInvalid.new(@user) unless @user.valid?
      @user.save!
    end

    redirect_to(users_url, notice: '利用者を登録しました')
  rescue ActiveRecord::RecordInvalid => e
    render :new
  end

  def edit
  end

  def login
  end

  def user_params
    return {} if params[:user].blank?

    params.require(:user).permit(:name, :name_kana, :login, :password, :password_confirmation)
  end
end
