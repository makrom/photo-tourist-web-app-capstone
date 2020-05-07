class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :update, :destroy]
  wrap_parameters :tag, include: ["name"]
  before_action :authenticate_user!, only: [:create, :update, :destroy]

  def index
    @tags = Tag.all
  end

  def show
  end

  def create
    @tag = Tag.new(tag_params)
    @tag.creator_id=current_user.id

    if @tag.save
      render :show, status: :created, location: @tag
    else
      render json: {errors:@tag.errors.messages}, status: :unprocessable_entity
    end
  end

  def update
    @tag = Tag.find(params[:id])

    if @tag.update(tag_params)
      head :no_content
    else
      render json: {errors:@tag.errors.messages}, status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy

    head :no_content
  end

  private

    def set_tag
      @tag = Tag.find(params[:id])
    end

    def tag_params
      params.require(:tag).permit(:name)
    end
end
