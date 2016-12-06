db.getSiblingDB("admin").auth("george", "george" )
mean = db.getSiblingDB("mean-dev")
mean.updateUser(
  "mean",
  {
    pwd: "TBS",
    customData: { title: "MEAN User" }
  }
)

