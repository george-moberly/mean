db.getSiblingDB("admin").auth("george", "george" )
mean = db.getSiblingDB("mean-dev")
mean.createUser(
    {
      user: "mean",
      pwd: "mean",
      roles: [
        { role: "readWrite", db: "mean-dev" }
      ]
    }
)
