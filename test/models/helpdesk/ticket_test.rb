require "test_helper"

class HelpdeskTicketTest < ActiveSupport::TestCase

  setup do
    @test_desc = 'Hello, World!'
    @test_project = Project.first
    @tickets = {
      without_task: HelpdeskTicket.create! {
        project: @test_project
      },
      with_task: HelpdeskTicket.create! {
        project: @test_project,
        task: @test_project.tasks.first
      },
      with_description: HelpdeskTicket.create! {
        project: @test_project,
        description: @test_desc
      }
    }
  end

  test "helpdesk tickets have projects" do
    @tickets.values.each do |t|
      assert_equal t.project, @test_project
    end
  end

  test "only one helpdesk ticket has a description" do
    assert_not_nil @tickets[:with_description].description
    assert_equal @tickets[:with_description], @test_desc
    assert_nil @tickets[:with_task].description
    assert_nil @tickets[:without_task].description
  end

  test "only one helpdesk ticket has a task" do
    assert_not_nil @tickets[:with_task].task
    assert_nil @tickets[:with_description].task
    assert_nil @tickets[:without_task].task
  end

  test "resolving a helpdesk ticket" do
    ticket_to_resolve = @tickets[:without_task]
    ticket_to_resolve.resolve
    assert ticket_to_resolve, true
    # both without_task and ticket_to_resolve should match
    assert_equal @tickets[:without_task], ticket_to_resolve
    # others should remain false
    refute @tickets[:with_task].is_resolved
    refute @tickets[:without_task].is_resolved
  end

  test "all resolved helpdesk tickets when one is resolved" do
    ticket_to_resolve = HelpdeskTicket.all.first
    assert_equal HelpdeskTicket.all_resolved.length, 0
    ticket_to_resolve.resolve
    assert_equal HelpdeskTicket.all_resolved.length, 1
    # The resolved ticket must match
    assert_equal HelpdeskTicket.all_resolved.first, ticket_to_resolve
  end

  test "all unresolved helpdesk tickets should remain when resolving a ticket" do
    ticket_to_resolve = HelpdeskTicket.all.first
    assert_equal HelpdeskTicket.all_unresolved.length, 3
    ticket_to_resolve.resolve
    # The others should be untouched!
    assert_equal HelpdeskTicket.all_unresolved.length, 2
  end

  test "the has_task? method should be true if the task has a task" do
    assert @tickets[:with_task].has_task?
  end

  test "the student method should match the associated project's student" do
    assert_equal HelpdeskTicket.first.student, @test_project.student
  end

  test "the unit method should match the associated project's unit" do
    assert_equal HelpdeskTicket.first.unit, @test_project.unit
  end
end
