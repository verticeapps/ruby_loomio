require 'spec_helper'

describe Vote do
  let(:user) { User.make! }
  let(:discussion) { create_discussion(author: user) }
  let(:motion) { create_motion(discussion: discussion) }

  it { Vote::POSITION_VERBS['yes'].should == 'agreed' }
  it { Vote::POSITION_VERBS['abstain'].should == 'abstained' }
  it { Vote::POSITION_VERBS['no'].should == 'disagreed' }
  it { Vote::POSITION_VERBS['block'].should == 'blocked' }

  context 'a new vote' do
    subject do
      @vote = Vote.new
      @vote.valid?
      @vote
    end

    it {should have(1).errors_on(:motion)}
    it {should have(1).errors_on(:user)}
    it {should have(2).errors_on(:position)}
  end

  it 'should only accept valid position values' do
    vote = Vote.make(position: 'bad')
    vote.valid?
    vote.should have(1).errors_on(:position)
  end

  it 'motion should only accept votes from users who belong to motion.group' do
    user2 = User.make
    user2.save
    vote = Vote.new(position: 'block')
    vote.motion = motion
    vote.user = user2
    vote.should_not be_valid
  end

  it "motion should only accept votes during the motion's voting phase" do
    motion.close_voting!
    vote = Vote.new(position: "yes")
    vote.motion = motion
    vote.user = user
    vote.save
    vote.errors.messages[:position].first.should match(/can only be modified while the motion is open/)
  end

  it 'sends notification email to author if block is issued' do
    MotionMailer.should_receive(:motion_blocked).with(kind_of(Vote))
      .and_return(stub(deliver: true))
    vote = Vote.new(position: 'block', statement: "I'm blocking this motion")
    vote.motion = motion
    vote.user = user
    vote.save
  end

  it 'can have a statement' do
    vote = Vote.new(position: "yes", statement: "This is what I think about the motion")
    vote.motion = motion
    vote.user = user
    vote.should be_valid
  end

  it 'cannot have a statement over 250 chars' do
    vote = Vote.new(position: 'yes')
    vote.motion = create_motion
    vote.user = user
    vote.statement = "a"*251
    vote.should_not be_valid
  end

  it 'should update vote_activity when new vote is created' do
    motion.discussion.activity = 2
    vote = Vote.new(position: 'yes')
    vote.motion = motion
    vote.user = user
    vote.save!
    motion.discussion.activity.should == 3
  end

  it 'should update comment_activity when vote is changed' do
    motion.discussion.activity = 2
    vote = Vote.new(position: 'yes')
    vote.motion = motion
    vote.user = user
    vote.save!
    vote.position = 'no'
    vote.save!
    motion.discussion.activity.should == 4
  end

  it 'should fire "new vote" event upon creation' do
    vote = Vote.new(position: 'yes')
    vote.motion = motion
    vote.user = user

    Event.should_receive(:new_vote!).with(vote)

    vote.save!
  end

  it 'should fire "new vote" event upon saving with new position' do
    vote = Vote.new(position: 'yes')
    vote.motion = motion
    vote.user = user
    vote.save!

    Event.should_receive(:new_vote!).with(vote)

    vote.position = 'no'
    vote.save!
  end

  it 'should not fire "new vote" event upon saving with same position' do
    vote = Vote.new(position: 'yes')
    vote.motion = motion
    vote.user = user
    vote.save!

    Event.should_not_receive(:new_vote!).with(vote)

    vote = Vote.new(position: 'yes')
    vote.motion = motion
    vote.user = user
    vote.statement = 'i really like this idea'
    vote.save!
  end


  it 'should fire "motion blocked" event upon creation if position is block' do
    vote = Vote.new(position: 'block')
    vote.motion = motion
    vote.user = user

    Event.should_receive(:motion_blocked!).with(vote)

    vote.save!
  end

  describe "previous_position" do
    it "gets position from previous vote on same motion by same user
        (if any)" do
    vote = Vote.new(position: 'abstain')
    vote.motion = motion
    vote.user = user
    vote.save!

    vote = Vote.new(position: 'yes')
    vote.motion = motion
    vote.user = user
    vote.save!

    vote.previous_position.should == 'abstain'
    end
  end
end
