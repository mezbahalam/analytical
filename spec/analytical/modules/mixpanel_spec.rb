require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Analytical::Modules::Mixpanel" do
  before(:each) do
    @parent = mock('api', :options=>{:google=>{:js_url_key=>'abc'}})
  end
  describe 'on initialize' do
    it 'should set the command_location' do
      a = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abc'
      a.tracking_command_location.should == :body_append
    end
    it 'should set the options' do
      a = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abc'
      a.options.should == {:js_url_key=>'abc', :parent=>@parent}
    end
  end
  describe '#identify' do
    it 'should return a js string' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abcdef'
      @api.identify('id', {:email=>'test@test.com'}).should == "mixpanel.identify('id');"
    end
    it 'should return a js string with name if included' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abcdef'
      @api.identify('id', {:email=>'test@test.com', :name => "user_name"}).should == "mixpanel.identify('id'); mixpanel.name_tag('user_name');"
    end
  end
  describe '#track' do
    it 'should return the tracking javascript' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :key=>'abcdef'
      @api.track('pagename', {'page title'=>'lovely day'}).should == "mixpanel.track(\"page viewed\", {\"url\":\"pagename\",\"page title\":\"lovely day\"}, function(){});"
    end
    it 'should return the tracking javascript with a callback' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :key=>'abcdef'
      @api.track('pagename', {'page title'=>'lovely day', :callback=>'fubar'}).should == "mixpanel.track(\"page viewed\", {\"url\":\"pagename\",\"page title\":\"lovely day\"}, fubar);"
    end
    it 'should return the tracking javascript with a custom event name' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :key=>'abcdef'
      @api.track('pagename', {:event=>'virtual pageview'}).should == "mixpanel.track(\"virtual pageview\", {\"url\":\"pagename\"}, function(){});"
    end
    it 'should return nil when Mixpanel pageview tracking is disabled' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :key=>'abcdef', :track => false
      @api.track('pagename', {'page title'=>'lovely day', :callback=>'fubar'}).should be_nil
    end

  end
  describe '#event' do
    it 'should return a js string' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abcdef'
      @api.event('An event happened', { :item => 43 }).should == "mixpanel.track(\"An event happened\", {\"item\":43});"
    end
  end
  describe '#alias_identity' do
    it 'should return a js string' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abcdef'
      @api.alias_identity(nil, 'new identity').should == "mixpanel.alias(\"new identity\");"
    end
    it 'ignores the first parameter' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abcdef'
      @api.alias_identity('foo', 'new identity').should == "mixpanel.alias(\"new identity\");"
    end
  end

  describe '#queue' do
    before(:each) do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :js_url_key=>'abcdef'
      @api.command_store.commands = [:a, :b, :c]
    end
    describe 'with an alias_identity command' do
      it 'should store it at the head of the command list' do
        @api.queue :identify, 'someone', {:some=>:args}
        @api.queue :alias_identity, 'someone new'
        @api.command_store.commands.should == [[:alias_identity, 'someone new'], [:identify, 'someone', {:some=>:args}], :a, :b, :c]
      end
    end
    describe 'with an identify command' do
      it 'should store it at the head of the command list' do
        @api.queue :identify, 'someone', {:some=>:args}
        @api.command_store.commands.should == [[:identify, 'someone', {:some=>:args}], :a, :b, :c]
      end
      it 'should ignore it if head of queue is :alias_identity' do
        @api.queue :alias_identity, 'someone new'
        @api.queue :identify, 'someone', {:some=>:args}
        @api.command_store.commands.should == [[:alias_identity, 'someone new'], :a, :b, :c]
      end
    end
    describe 'with any other command' do
      it 'should store it at the end of the command list' do
        @api.queue :other, {:some=>:args}
        @api.command_store.commands.should == [:a, :b, :c, [:other, {:some=>:args}]]
      end
    end
  end

  describe '#init_javascript' do
    it 'should return the init javascript' do
      @api = Analytical::Modules::Mixpanel.new :parent=>@parent, :key=>'abcdef'
      @api.init_javascript(:head_prepend).should == ''
      @api.init_javascript(:head_append).should == ''
      @api.init_javascript(:body_prepend).should == ''
      @api.init_javascript(:body_append).should =~ %r(cdn\.mxpnl\.com\/libs/mixpanel-2\.2\.min\.js)
      @api.init_javascript(:body_append).should =~ %r(mixpanel\.init\("abcdef"\))
      @api.init_javascript(:body_append).should =~ %r(<script type="text\/javascript">)
    end
  end
end
