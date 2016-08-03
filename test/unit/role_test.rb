# encoding: utf-8
# redMine - project management software
# Copyright (C) 2006-2008  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require "test_helper"

class RoleTest < ActiveSupport::TestCase
  should have_many(:user_roles)
  should validate_presence_of(:name)
  should validate_uniqueness_of(:name)
  should allow_value('a role name').for(:name)
  should allow_value('トメル３４；。').for(:name)
  should allow_value('test@example.com').for(:name)

  it "should strip leading space on name" do
    role = Role.new(:name => " a role name")
    role.must_be :valid?
  end

  it "should strip a trailing space on name" do
    role = Role.new(:name => "a role name ")
    role.must_be :valid?
  end

  context "System roles" do
    should "return the default role" do
      role = Role.default
      assert role.builtin?
      assert_equal Role::BUILTIN_DEFAULT_ROLE, role.builtin
    end

    context "with a missing default role" do
      setup do
        role_ids = Role.where("builtin = #{Role::BUILTIN_DEFAULT_ROLE}").pluck(:id)
        UserRole.where(:role_id => role_ids).destroy_all
        Filter.where(:role_id => role_ids).destroy_all
        Role.where(:id => role_ids).delete_all
      end

      should "create a new default role" do
        assert_difference('Role.count') do
          Role.default
        end
      end

      should "return the default role" do
        role = Role.default
        assert role.builtin?
        assert_equal Role::BUILTIN_DEFAULT_ROLE, role.builtin
      end
    end
  end

  describe ".for_current_user" do
    context "there are two roles, one of them is assigned to current user" do
      let(:first) { Role.create(:name => 'First') }
      let(:second) { Role.create(:name => 'Second') }
      before do
        User.current = users(:one)
        User.current.roles<< first
      end

      subject { Role.for_current_user.to_a }
      it { subject.must_include(first) }
      it { subject.wont_include(second) }
    end

    context "when current user is admin for_current_user should return all roles" do
      setup do
        User.current = users(:admin)
      end

      test "Admin user should query Role model with no restrictions" do
        Role.expects(:where).with('0 = 0')
        Role.for_current_user
      end
    end
  end

  describe ".permissions=" do
    let(:role) { FactoryGirl.build(:role) }

    it 'accepts not unique list of permissions' do
      role.expects(:add_permissions).once.with(['a','b'])
      role.permissions = [
        FactoryGirl.build(:permission, :name => 'a'),
        FactoryGirl.build(:permission, :name => 'b'),
        FactoryGirl.build(:permission, :name => 'a'),
        FactoryGirl.build(:permission, :name => 'b')
      ]
    end
  end

  describe "#add_permissions" do
    setup do
      @permission1 = FactoryGirl.create(:permission, :name => 'permission1')
      @permission2 = FactoryGirl.create(:permission, :architecture, :name => 'permission2')
      @role = FactoryGirl.build(:role, :permissions => [])
    end

    it "should build filters with assigned permission" do
      @role.add_permissions [@permission1.name, @permission2.name.to_sym]
      assert @role.filters.all?(&:unlimited?)

      permissions = @role.filters.map { |f| f.filterings.map(&:permission) }.flatten
      assert_equal 2, @role.filters.size
      assert_includes permissions, Permission.find_by_name(@permission1.name)
      assert_includes permissions, Permission.find_by_name(@permission2.name)
      # not saved yet
      assert_empty @role.permissions
    end

    it "should raise error when given permission does not exist" do
      assert_raises ArgumentError do
        @role.add_permissions ['does_not_exist']
      end
    end

    it "accespts one permissions instead of array as well" do
      @role.add_permissions @permission1.name
      permissions = @role.filters.map { |f| f.filterings.map(&:permission) }.flatten

      assert_equal 1, @role.filters.size
      assert_includes permissions, Permission.find_by_name(@permission1.name)
    end

    it "sets search filter to all filters" do
      search = "id = 1"
      @role.add_permissions [@permission1.name, @permission2.name.to_sym], :search => search
      refute @role.filters.any?(&:unlimited?)
      assert @role.filters.all? { |f| f.search == search }
    end
  end

  describe "#add_permissions!" do
    setup do
      @permission1 = FactoryGirl.create(:permission, :name => 'permission1')
      @permission2 = FactoryGirl.create(:permission, :architecture, :name => 'permission2')
      @role = FactoryGirl.build(:role, :permissions => [])
    end

    it "persists built permissions" do
      assert @role.add_permissions!([@permission1.name, @permission2.name.to_sym])
      @role.reload

      permissions = @role.permissions
      assert_equal 2, @role.filters.size
      assert_includes permissions, Permission.find_by_name(@permission1.name)
      assert_includes permissions, Permission.find_by_name(@permission2.name)
    end
  end

  context 'having role with filters' do
    setup do
      @permission1 = FactoryGirl.create(:permission, :domain, :name => 'permission1')
      @permission2 = FactoryGirl.create(:permission, :architecture, :name => 'permission2')
      @role = FactoryGirl.build(:role, :permissions => [])
      @role.add_permissions! [@permission1.name, @permission2.name]
      @org1 = FactoryGirl.create(:organization)
      @org2 = FactoryGirl.create(:organization)
      @role.filters.reload
      @filter_with_org = @role.filters.detect { |f| f.allows_organization_filtering? }
      @filter_without_org = @role.filters.detect { |f| !f.allows_organization_filtering? }
    end

    describe "#set_taxonomies" do
      it "allows adding organization for admin for global role" do
        as_admin do
          @role.set_taxonomies([ @org1.id ])
        end

        @role.organizations.must_include @org1
        @role.organizations.wont_include @org2
        @filter_with_org.organizations.must_include @org1
        @filter_with_org.organizations.wont_include @org2
        @filter_with_org.reload
        @filter_with_org.taxonomy_search.must_be :present?
        @filter_without_org.organizations.wont_include @org1
        @filter_without_org.organizations.wont_include @org2
      end

      it "can change the association of organizations for admin" do
        @role.organization_ids = [ @org1.id ]
        as_admin do
          @role.set_taxonomies([ @org2.id ])
        end

        @role.organizations.must_include @org2
        @role.organizations.wont_include @org1
        @filter_with_org.organizations.must_include @org2
        @filter_with_org.organizations.wont_include @org1
        @filter_with_org.reload
        @filter_with_org.taxonomy_search.must_be :present?
        @filter_without_org.organizations.wont_include @org1
        @filter_without_org.organizations.wont_include @org2
      end

      context "user scoped to some organizations" do
        setup do
          @org3 = FactoryGirl.create(:organization)
          @org4 = FactoryGirl.create(:organization)
          @user = FactoryGirl.create(:user)
          @user.organizations = [ @org3, @org4 ]
        end

        it "allows to only set user's organizations converting global role to org limited role" do
          as_user @user do
            @role.set_taxonomies([ @org3.id, @org4.id ])
          end

          @role.organizations.wont_include @org1
          @role.organizations.wont_include @org2
          @role.organizations.must_include @org3
          @role.organizations.must_include @org4

          @filter_with_org.organizations.wont_include @org1
          @filter_with_org.organizations.wont_include @org2
          @filter_with_org.organizations.must_include @org3
          @filter_with_org.organizations.must_include @org4
          @filter_with_org.reload
          @filter_with_org.taxonomy_search.must_be :present?
          @filter_without_org.organizations.wont_include @org1
          @filter_without_org.organizations.wont_include @org2
          @filter_without_org.organizations.wont_include @org3
          @filter_without_org.organizations.wont_include @org4
        end

        it "allows to only set user's organizations adding more orgs to existing list" do
          @role.organization_ids = [ @org1.id, @org3.id ]
          as_user @user do
            @role.set_taxonomies([ @org3.id, @org4.id ])
          end

          @role.organizations.must_include @org1
          @role.organizations.wont_include @org2
          @role.organizations.must_include @org3
          @role.organizations.must_include @org4

          @filter_with_org.organizations.wont_include @org1 # since the filter was already out of sync
          @filter_with_org.organizations.wont_include @org2
          @filter_with_org.organizations.must_include @org3
          @filter_with_org.organizations.must_include @org4
          @filter_with_org.reload
          @filter_with_org.taxonomy_search.must_be :present?
          @filter_without_org.organizations.wont_include @org1
          @filter_without_org.organizations.wont_include @org2
          @filter_without_org.organizations.wont_include @org3
          @filter_without_org.organizations.wont_include @org4
        end

        it "allows to only set user's organizations ignoring orgs that user is not assigned to" do
          @role.organization_ids = []
          as_user @user do
            @role.set_taxonomies([ @org1.id, @org4.id ])
          end

          @role.organizations.wont_include @org1
          @role.organizations.wont_include @org2
          @role.organizations.wont_include @org3
          @role.organizations.must_include @org4

          @filter_with_org.organizations.wont_include @org1 # because user can't assign this org
          @filter_with_org.organizations.wont_include @org2
          @filter_with_org.organizations.wont_include @org3
          @filter_with_org.organizations.must_include @org4
          @filter_with_org.reload
          @filter_with_org.taxonomy_search.must_be :present?
          @filter_without_org.organizations.wont_include @org1
          @filter_without_org.organizations.wont_include @org2
          @filter_without_org.organizations.wont_include @org3
          @filter_without_org.organizations.wont_include @org4
        end

        it "allows to only set user's organizations adding more orgs to existing list keeping filter associations that use can't change" do
          @role.organization_ids = [ @org1.id, @org3.id ]
          @filter_with_org.organization_ids = [ @org1.id, @org4.id ]
          as_user @user do
            @role.set_taxonomies([ @org3.id, @org4.id ])
          end

          @role.organizations.must_include @org1
          @role.organizations.wont_include @org2
          @role.organizations.must_include @org3
          @role.organizations.must_include @org4

          @filter_with_org.reload
          @filter_with_org.organizations.must_include @org1 # since the filter was already out of sync
          @filter_with_org.organizations.wont_include @org2
          @filter_with_org.organizations.must_include @org3
          @filter_with_org.organizations.must_include @org4
          @filter_with_org.taxonomy_search.must_be :present?
          @filter_without_org.organizations.wont_include @org1
          @filter_without_org.organizations.wont_include @org2
          @filter_without_org.organizations.wont_include @org3
          @filter_without_org.organizations.wont_include @org4
        end

        it "supports organization and location ids at the same time" do
          @loc1 = FactoryGirl.create(:location)
          @loc2 = FactoryGirl.create(:location)
          @role.location_ids = [ @loc2.id ]
          @filter_with_org.organization_ids = [ @org1.id ]
          @filter_with_org.location_ids = [ @loc2.id ]
          @user.location_ids = [ @loc1.id, @loc2.id ]
          as_user @user do
            @role.set_taxonomies([ @org3.id, @org4.id, @loc1.id ])
          end

          @role.organizations.wont_include @org1
          @role.organizations.wont_include @org2
          @role.organizations.must_include @org3
          @role.organizations.must_include @org4
          @role.locations.must_include @loc1

          @filter_with_org.reload
          @filter_with_org.organizations.must_include @org1
          @filter_with_org.organizations.wont_include @org2
          @filter_with_org.organizations.must_include @org3
          @filter_with_org.organizations.must_include @org4
          @filter_with_org.locations.must_include @loc1
          @filter_with_org.locations.wont_include @loc2
          @filter_with_org.taxonomy_search.must_be :present?
          @filter_without_org.organizations.wont_include @org1
          @filter_without_org.organizations.wont_include @org2
          @filter_without_org.organizations.wont_include @org3
          @filter_without_org.organizations.wont_include @org4
          @filter_without_org.locations.wont_include @loc1
          @filter_without_org.locations.wont_include @loc2
        end
      end
    end

    describe '#filters_out_of_sync?' do
      it 'should ignore non-taxable filters' do
        @role.filters = [ @filter_without_org ]
        refute @role.filters_out_of_sync?
      end

      it 'should detect filter out of sync' do
        as_admin do
          @filter_with_org.organizations = [ @org1 ]
          assert @role.filters_out_of_sync?
        end
      end

      it 'should return false if there is no filter out of sync' do
        @role.organizations = [ @org1 ]
        as_admin do
          @role.set_filter_taxonomies
          refute @role.filters_out_of_sync?
        end
      end
    end

    describe '#filter_out_of_sync' do
      it 'finds all out of sync filters' do
        as_admin do
          @filter_with_org.organizations = [ @org1 ]
          assert_equal [ @filter_with_org ], @role.filters_out_of_sync
        end
      end
    end

    describe '#existing_taxonomy_ids' do
      it 'returns taxable taxonomy ids' do
        @loc1 = FactoryGirl.create(:location)
        @role.organizations = [ @org1, @org2 ]
        @role.locations = [ @loc1 ]
        result = @role.existing_taxonomy_ids
        assert_equal 3, result.size
        assert_includes result, @org1.id
        assert_includes result, @org2.id
        assert_includes result, @loc1.id
      end
    end

    describe '#set_filter_taxonomies' do
      it 'fixes filter out of sync' do
        @role.organizations = [ @org1 ]
        as_admin do
          @role.set_filter_taxonomies
          @filter_with_org.reload
          assert_equal [ @org1 ], @filter_with_org.organizations
        end
      end
    end
  end
end
