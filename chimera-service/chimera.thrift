exception InternalError {
  1: string what
  2: string where
}

enum DeployStatus {
  UNKNOWN = 0,
  STARTED = 1,
  PULL = 2,
  CHECK = 3,
  EXTRACT = 4,
  BUILD = 5, 
  PREACTIVATE = 6,
  FLIP = 7,
  ACTIVATE = 8,
  POSTACTIVATE = 9,
  PREDEACTIVATE = 10,
  DEACTIVATE = 11,
  POSTDEACTIVATE = 12,
  COMPLETE = 13,
  PENDINGSTART = 14
}

struct PullStatus {
  1: i32 completedPackages = 0,
  2: i32 totalPackages = 0,
  3: i64 transferred = 0,
  4: i64 totalSize = 0
}

service Chimera {
  string ping(),
  void startDeployment(1:string deploymentId, 2:string manifest) throws (1:InternalError ex),
  void deployTargets(1:string deploymentId, 2:list<string> targets, 3:string environment) throws (1:InternalError ex),
  void reportStatus(1:string deploymentId, 2:DeployStatus status) throws (1:InternalError ex),
  void reportPullStatus(1:string deploymentId, 2:PullStatus status) throws (1:InternalError ex),
  DeployStatus getDeploymentStatus(1:string deploymentId) throws (1:InternalError ex),
  PullStatus getPullStatus(1:string deploymentId) throws (1:InternalError ex),
  list<string> getDeployments() throws (1:InternalError ex)
}
