db.getSiblingDB("admin").auth("george", "george" )
mean = db.getSiblingDB("mean-dev")

mean.runCommand( { usersInfo: { user: "mean", db: "mean-dev" }, showCredentials: true } )

mean.updateUser(
  "mean",
  {
    pwd: "TBS",
    customData: { title: "MEAN User" }
  }
)

mean.runCommand( { usersInfo: { user: "mean", db: "mean-dev" }, showCredentials: true } )
