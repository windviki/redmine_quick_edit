class QuickEditRelationsController < ApplicationController
  before_filter :find_issue, :find_project_from_association, :authorize, :only => [:create]
  before_filter :find_relation, :except => [:index, :create]

  def index
  end

  def create
    @relation = IssueRelation.new(params[:relation])
    @relation.issue_from = @issue
    if params[:relation] && m = params[:relation][:issue_to_id].to_s.strip.match(/^#?(\d+)$/)
      @relation.issue_to = Issue.visible.find_by_id(m[1].to_i)
    end
    saved = @relation.save

    back_url = params[:back_url]
    respond_to do |format|
      format.html { redirect_to back_url }
      format.js {
        @relations = @issue.reload.relations.select {|r| r.other_issue(@issue) && r.other_issue(@issue).visible? }
      }
    end
  end

  def destroy
    raise Unauthorized unless @relation.deletable?
    @relation.destroy

    back_url = params[:back_url]
    respond_to do |format|
      format.html { redirect_to back_url }
      format.js
      format.api  { render_api_ok }
    end
  end

private
  def find_issue
    @issue = @object = Issue.find(params[:issue_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_relation
    @relation = IssueRelation.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
