admin = User.create!(
  email: "admin@example.com",
  password: "password",
  role: "admin"
)

user = User.create!(
  email: "user@example.com",
  password: "password",
  role: "user"
)

categories = Category.create!([
  { name: "Work" },
  { name: "Personal" },
  { name: "Learning" }
])

Task.create!([
  { title: "Review PRs", description: "Review open pull requests", status: "in_progress", priority: 2, user: admin, category: categories[0] },
  { title: "Write documentation", description: "Add API docs for all endpoints", status: "todo", priority: 1, user: admin, category: categories[0] },
  { title: "Learn Rust", description: "Complete Rust book chapters 1-5", status: "todo", priority: 0, user: user, category: categories[2] },
  { title: "Grocery shopping", description: "Buy groceries for the week", status: "done", priority: 1, user: user, category: categories[1] }
])

puts "Seeded admin (admin@example.com), user (user@example.com), 3 categories, 4 tasks"
