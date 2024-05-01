alias Mozart.Data.ProcessModel
alias Mozart.Data.Task

%ProcessModel{
  name: :one_user_task,
  tasks: [
    %Task{
      name: :provide_loan_amount,
      type: :user,
      assigned_groups: ["under writing"],
      next: nil
    }
  ],
  next: nil
}
