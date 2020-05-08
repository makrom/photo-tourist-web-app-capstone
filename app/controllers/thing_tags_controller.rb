class ThingTagsController < ApplicationController
  include ActionController::Helpers
  helper ThingsHelper
  wrap_parameters :thing_tag, include: ["tag_id", "thing_id"]
  before_action :get_thing, only: [:index, :update, :destroy]
  before_action :get_tag, only: [:tag_things]
  before_action :get_thing_tag, only: [:update, :destroy]
  before_action :authenticate_user!, only: [:create, :update, :destroy]
  after_action :verify_authorized
  # after_action :verify_policy_scoped, only: [:linkable_things]

  def index
    authorize @thing, :get_tags?
    @thing_tags = @thing.thing_tags.with_tag_name
  end

  def tag_things
    authorize @tag, :get_things?
    @thing_tags = @tag.thing_tags.with_name
    render :index
  end

  # def linkable_things
  #   authorize Thing, :get_tag_linkables?
  #   tag = Tag.find(params[:tag_id])
  #   @things = Thing.not_linked_tags(tag)
  #   @things = ThingPolicy::Scope.new(current_user, @things).user_roles2
  #   @things = ThingPolicy.merge(@things)
  #   render "things/index"
  # end

  def linkable_things
    authorize Thing, :get_tag_linkables?
    tag = Tag.find(params[:tag_id])
    # @things = policy_scope(Thing.not_linked_tags(tag))
    @things=Thing.not_linked_tags(tag)
    @things=ThingPolicy::Scope.new(current_user,@things).user_roles(true,false)
    @things=ThingPolicy.merge(@things)
    render "things/index"
  end

  def create
    thing_tag = ThingTag.new(thing_tag_create_params.merge({
      :tag_id=>params[:tag_id],
      :thing_id=>params[:thing_id]
      }))
    thing = Thing.where(id:thing_tag.thing_id).first
    if !thing
      full_message_error "cannot find thing[#{params[:thing_id]}]", :bad_request
      skip_authorization
    elsif !Tag.where(id:thing_tag.tag_id).exists?
      full_message_error "cannot find tag[#{params[:tag_id]}]", :bad_request
      skip_authorization
    else
      authorize thing, :add_tag?
      thing_tag.creator_id = current_user.id
      if thing_tag.save
        head :no_content
      else
        render json: {errors:@thing_tag.errors.messages}, status: unprocessable_entity
      end
    end
  end

  def update
    authorize @thing, :update_tag?
    if @thing_tag.update(thing_tag_update_params)
      head :no_content
    else
      render json: {errors:@thing_tag.errors.messages}, status: unprocessable_entity
    end
  end

  def destroy
    authorize @thing, :remove_tag?
    @thing_tag.destroy
    head :no_content
  end

  private
    def get_thing
      @thing ||= Thing.find(params[:thing_id])
    end
    def get_tag
      @tag ||= Tag.find(params[:tag_id])
    end
    def get_thing_tag
      @thing_tag ||= ThingTag.find(params[:id])
    end

    def thing_tag_create_params
      params.require(:thing_tag).tap {|p|
        #_ids only required in payload when not part of URI
        p.require(:tag_id)  if !params[:tag_id]
        p.require(:thing_id)  if !params[:thing_id]
      }.permit(:tag_id, :thing_id)
    end
    def thing_tag_update_params
      params.require(:thing_tag).permit(:tag_id, :thing_id) #_may be it is never?
    end
end
