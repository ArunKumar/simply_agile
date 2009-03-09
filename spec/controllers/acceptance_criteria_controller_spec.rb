require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AcceptanceCriteriaController do

  def set_instance_variables
    controller.instance_variable_set('@project', @project)
    controller.instance_variable_set('@story', @story)
    controller.instance_variable_set('@acceptance_criterion', @criterion)
  end

  before :each do
    login
    stub_projects!

    @story = mock_model Story
    @stories = mock('Collection', :find => @story)

    @acceptance_criterion = mock_model(AcceptanceCriterion, 
                                       :update_attributes => nil,
                                       :attributes= => {})
    @acceptance_criterion.errors.stub!(:full_messages).
      and_return(['some error'])

    @new_acceptance_criterion = mock_model(AcceptanceCriterion, 
                                           :update_attributes => nil)
    @new_acceptance_criterion.errors.stub!(:full_messages).
      and_return(['some error'])

    @acceptance_criteria = mock('Collection',
                                :build => @new_acceptance_criterion,
                                :find => @acceptance_criterion,
                                :destroy => @acceptance_criterion)

    @project.stub!(:stories).and_return(@stories)
    @story.stub!(:acceptance_criteria).and_return(@acceptance_criteria)
  end

  describe "it belongs to a story", :shared => true do
    it "should assign the story" do
      controller.should_receive(:get_story)
      do_call
    end
  end

  describe "it operates on an existing criterion", :shared => true do
    it "should assign the criterion" do
      controller.should_receive(:get_acceptance_criterion)
      do_call
    end
  end

  describe "it operates on a new criterion", :shared => true do
    it "should build the criterion" do
      controller.should_receive(:new_acceptance_criterion)
      do_call
    end
  end

  # set @criterion in calling block's before(:each)
  describe "it saves a criterion", :shared => true do
    before :each do
      @attributes = {'criterion' => 'asdf'}
      set_instance_variables
    end

    it_should_behave_like "it belongs to a project"
    it_should_behave_like "it belongs to a story"

    it "should attempt to save" do
      @criterion.should_receive(:update_attributes).with(@attributes)
      do_call
    end
    
    describe "success" do
      before :each do
        @criterion.stub!(:update_attributes).with(@attributes).and_return(true)
      end

      it_should_behave_like "it's successful"

      it "should render the new list" do
        do_call
        response.should render_template('acceptance_criteria/list')
      end
    end

    describe "failure" do
      before :each do
        @criterion.stub!(:update_attributes).with(@attributes).and_return(false)
      end

      it "should render some text" do
        do_call
        response.body.should_not be_blank
      end

      it "should provide a failure response code" do
        do_call
        response.code.should == '422'
      end
    end
  end

  describe "instance variable setup" do
    before :each do
      controller.stub!(:params).and_return({
        :project_id => @project.id.to_s,
        :story_id => @story.id.to_s
      })
      controller.instance_variable_set('@project', @project)
    end

    describe "get_story" do
      it "should restrict to project's stories" do
        @projects.stub!(:find).with(@project.id.to_s).and_return(@project)
        @stories.stub!(:find).with(@story.id.to_s).and_return(@story)
        controller.send(:get_story)
        controller.instance_variable_get("@story").should == @story
      end
    end

    describe "new_acceptance_criterion" do
      before :each do
        controller.instance_variable_set('@story', @story)
        controller.stub!(:params).and_return(:acceptance_criterion => {})
      end

      it "should build from story" do
        @acceptance_criteria.should_receive(:build)
        controller.send(:new_acceptance_criterion)
      end
    end

    describe "get_acceptance_criterion" do
      before :each do
        controller.instance_variable_set('@story', @story)
        controller.stub!(:params).and_return(:id => @acceptance_criterion.id)
      end

      it "should find from story" do
        @acceptance_criteria.should_receive(:find).with(@acceptance_criterion.id)
        controller.send(:get_acceptance_criterion)
      end

      it "should set the instance variable" do
        controller.send(:get_acceptance_criterion)
        controller.instance_variable_get('@acceptance_criterion').
          should == @acceptance_criterion
      end
    end
  end

  describe "create" do
    def do_call
      post :create, :project_id => @project.id, :story_id => @story.id,
        :acceptance_criterion => @attributes
    end

    before :each do
      @criterion = @new_acceptance_criterion
    end

    it_should_behave_like "it operates on a new criterion"
    it_should_behave_like "it saves a criterion"
  end

  describe "destroy" do
    def do_call
      delete :destroy, :id => @acceptance_criterion.id,
        :project_id => @project.id, :story_id => @story.id
    end

    before :each do
      set_instance_variables
    end

    it_should_behave_like "it belongs to a project"
    it_should_behave_like "it belongs to a story"
    it_should_behave_like "it's successful"

    it "should attempt to destroy" do
      @acceptance_criteria.should_receive(:destroy).
        with(@acceptance_criterion.id.to_s)
      do_call
    end

    it "should render the criteria partial" do
      do_call
      response.should render_template('acceptance_criteria/list')
    end
  end

  describe "edit" do
    def do_call
      get :edit, :id => @acceptance_criterion.id,
        :project_id => @project.id, :story_id => @story.id
    end

    before :each do
      set_instance_variables
    end

    it_should_behave_like "it belongs to a project"
    it_should_behave_like "it belongs to a story"
    it_should_behave_like "it's successful"

    it_should_behave_like "it operates on an existing criterion" 
  end

  describe "update" do
    def do_call
      put :update, :id => @criterion.id,
        :project_id => @project.id, :story_id => @story.id,
        :acceptance_criterion => @attributes
    end

    before :each do
      @criterion = @acceptance_criterion
    end

    it_should_behave_like "it operates on an existing criterion" 
    it_should_behave_like "it saves a criterion"
  end
end