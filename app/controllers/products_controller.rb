class ProductsController < ApplicationController
  before_action :set_category, only: [:new, :create]
  before_action :move_to_signed_in, except: [:index, :show]
  
  def index
    # Productテーブルとimagesデータを事前に読み込む
    @products = Product.includes(:images).order('created_at DESC')

  end

  def new
    @product = Product.new
    @product.images.new
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      redirect_to root_path, notice: '商品を出品しました。'
    else
      redirect_to new_product_path, alert: "商品登録に失敗しました"
    end
  end

  def show
    @product = Product.find(params[:id])
    @category = Category.find(@product.category_id)
    @user = User.find(@product.user_id)
    @address = Prefecture.find(@product.prefecture_id)
    @condition = Condition.find(@product.condition)
    @delivery_charge = DeliveryCharge.find(@product.delivery_charge)
    @shipping_day = ShippingDay.find(@product.shipping_day)
    array = []
    @products = Product.all.order(created_at: :desc)
    @products.each do |item|
      if Category.find(item.category_id) == @category || Category.find(item.category_id).parent == @category.parent || Category.find(item.category_id).parent.parent == @category.parent.parent
        unless item.buyer_id.present?
        array << item
        end
      end
    end
    @items = Kaminari.paginate_array(array).page(params[:page]).per(5)
      respond_to do |format|
        format.html
        format.js
      end
  end

  #jsonで親の名前で検索し、紐づく小カテゴリーの配列を取得
  def get_category_children
    @category_children = Category.find(params[:parent_name]).children
  end

  #jsonで子カテゴリーに紐づく孫カテゴリーの配列を取得
  def get_category_grandchildren
    @category_grandchildren = Category.find("#{params[:child_id]}").children
  end

  private

  def product_params
    params.require(:product).permit(:name,:infomation,:price,:condition_id, :delivery_charge_id,:prefecture_id,:shipping_day_id,:brand,:category_id, images_attributes: [:src]).merge(user_id: current_user.id)
  end
  
  def set_category  
    @category_parent_array = Category.where(ancestry: nil).limit(13)
  end

  def item_params
    params.permit(:category_id )
  end

  def move_to_signed_in
    unless user_signed_in?
      #サインインしていないユーザーはログインページが表示される
      redirect_to  new_user_session_path
    end
  end
end
