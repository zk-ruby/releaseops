require 'spec_helper'

module ReleaseOps
module Mohel
  describe Version do
    describe :initialize do
      it 'should return a Version object equiv. to 0.0.0 if no options are given' do
        v = Version.new

        v.major.should be_zero
        v.minor.should be_zero
        v.patch.should be_zero
      end

      it 'should set major to zero if not given as an option' do
        v = Version.new(:minor => 3, :patch => 8)
        v.major.should be_zero
      end

      it 'should set minor to zero if not given as an option' do
        v = Version.new(:major => 3, :patch => 8)
        v.minor.should be_zero
      end

      it 'should set patch to zero if not given as an option' do
        v = Version.new(:major => 3, :minor => 8)
        v.patch.should be_zero
      end

      it 'should set major to the integer value of the option given' do
        v = Version.new(:major => '3')
        v.major.should == 3
        v.major.should be_a_kind_of(Integer)
      end

      it 'should set minor to the integer value of the option given' do
        v = Version.new(:minor => '3')
        v.minor.should == 3
        v.minor.should be_a_kind_of(Integer)
      end

      it 'should set patch to the integer value of the option given' do
        v = Version.new(:patch => '3')
        v.patch.should == 3
        v.patch.should be_a_kind_of(Integer)
      end
    end

    describe :parse do
      it 'should parse "$major.$minor.$patch" strings correctly' do
        v = Version.parse('3.7.8')
        v.should be_a(Version)
        v.major.should == 3
        v.minor.should == 7
        v.patch.should == 8
      end

      it 'should barf if one of the elements is not an integer' do
        lambda { Version.parse('3.7.omfg') }.should raise_error(ArgumentError)
      end

      it 'should barf if the string is does not have 2 "."s' do
        lambda { Version.parse('3.2') }.should raise_error(ArgumentError)
      end

      it 'should return a 0.0.0 version if the string is blank' do
        v = Version.parse('')
        v.to_hash.should == {:major => 0, :minor => 0, :patch => 0}
      end

      it 'should return a 0.0.0 version if the argument is nil' do
        v = Version.parse(nil)
        v.to_hash.should == {:major => 0, :minor => 0, :patch => 0}
      end
    end

    describe :instance_methods do
      before :each do
        @v = Version.new
      end

      describe :major= do
        it 'should convert the given argument to an integer' do
          @v.major = '3'
          @v.major.should == 3
          @v.major.should be_a_kind_of(Integer)
        end
        
        it 'should raise ArgumentError if input is not a valid integer representation' do
          lambda { @v.major = :not_an_integer_at_all }.should raise_error(ArgumentError)
        end
      end

      describe :minor= do
        it 'should convert the given argument to an integer' do
          @v.minor = '3'
          @v.minor.should == 3
          @v.minor.should be_a_kind_of(Integer)
        end
        
        it 'should raise ArgumentError if input is not a valid integer representation' do
          lambda { @v.minor = :not_an_integer_at_all }.should raise_error(ArgumentError)
        end
      end

      describe :patch= do
        it 'should convert the given argument to an integer' do
          @v.patch = '3'
          @v.patch.should == 3
          @v.patch.should be_a_kind_of(Integer)
        end
        
        it 'should raise ArgumentError if input is not a valid integer representation' do
          lambda { @v.patch = :not_an_integer_at_all }.should raise_error(ArgumentError)
        end
      end

      describe :bump_major do
        it 'should return a different Version object' do
          rval = @v.bump_major
          rval.should be_a(Version)
          rval.should_not be_equal(@v)
        end

        it "should return an object whose major number is one greater than the receiver's" do
          @v.bump_major.major.should == @v.major + 1
        end
      end

      describe :bump_minor do
        it 'should return a different Version object' do
          rval = @v.bump_minor
          rval.should be_a(Version)
          rval.should_not be_equal(@v)
        end

        it "should return an object whose minor number is one greater than the receiver's" do
          @v.bump_minor.minor.should == @v.minor + 1
        end
      end

      describe :bump_patch do
        it 'should return a different Version object' do
          rval = @v.bump_patch
          rval.should be_a(Version)
          rval.should_not be_equal(@v)
        end

        it "should return an object whose patch number is one greater than the receiver's" do
          @v.bump_patch.patch.should == @v.patch + 1
        end
      end

      describe :to_s do
        it 'should return a major.minor.patch string' do
          @v.major, @v.minor, @v.patch = 3, 7, 8
          @v.to_s.should == '3.7.8'
        end
      end

      describe :to_hash do
        it 'should return a hash with :major, :minor, :patch keys' do
          @v.major, @v.minor, @v.patch = 3, 7, 8

          h = @v.to_hash
          h[:major].should == 3
          h[:minor].should == 7
          h[:patch].should == 8
        end
      end
    end
  end
end # Mohel
end # ReleaseOps

