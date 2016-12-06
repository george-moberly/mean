admin = db.getSiblingDB("admin")
admin.createUser(
  {
    user: "george",
    pwd: "george",
    roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
  }
)

