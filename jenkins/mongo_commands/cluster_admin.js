db.getSiblingDB("admin").auth("george", "george" )
db.getSiblingDB("admin").createUser(
  {
    "user" : "george2",
    "pwd" : "george2",
    roles: [ { "role" : "clusterAdmin", "db" : "admin" } ]
  }
)
