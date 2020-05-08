class TagPolicy < ApplicationPolicy
  def index?
    true
  end
  def show?
    true
  end
  def create?
    @user
  end
  def update?
    organizer?
  end
  def destroy?
    organizer_or_admin?
  end

  def get_things?
    true
  end

  class Scope < Scope
    def user_roles
      joins_clause=["left join Roles r on r.mname='Tag'",
                    "r.mid=Tags.id",
                    "r.user_id #{user_criteria}"].join(" and ")
      scope.select("Tags.*, r.role_name")
           .joins(joins_clause)
           .tap {|s|
              s.where("r.role_name"=>[Role::ORGANIZER])
            }
    end

    def resolve
      user_roles
    end
  end
end
